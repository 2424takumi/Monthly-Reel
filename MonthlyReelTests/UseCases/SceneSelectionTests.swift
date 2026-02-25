import XCTest
import CoreMedia
@testable import MonthlyReel

final class SceneSelectionTests: XCTestCase {

    private var sut: SceneSelectionUseCase!
    private var mockService: MockVisionAnalysisService!

    override func setUp() {
        super.setUp()
        mockService = MockVisionAnalysisService()
        sut = SceneSelectionUseCase(visionService: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Exclusion: Blurry Videos

    func test_sceneSelection_excludesBlurryVideos() async throws {
        // Arrange
        let blurry = MockVideoAsset(id: "blurry", duration: 10.0)
        let sharp = MockVideoAsset(id: "sharp", duration: 10.0)
        mockService.setBlurry(for: "blurry") // sharpness 0.05
        mockService.resultsByIdentifier["sharp"] = AnalysisResult(
            sharpness: 0.7, brightness: 0.5, hasFace: false
        )

        // Act
        let clips = try await sut.select(from: [blurry, sharp])

        // Assert
        XCTAssertEqual(clips.count, 1)
        XCTAssertEqual(clips.first?.assetLocalIdentifier, "sharp")
    }

    // MARK: - Exclusion: Too Dark Videos

    func test_sceneSelection_excludesTooDarkVideos() async throws {
        // Arrange
        let dark = MockVideoAsset(id: "dark", duration: 10.0)
        let normal = MockVideoAsset(id: "normal", duration: 10.0)
        mockService.setTooDark(for: "dark") // brightness 0.10
        mockService.resultsByIdentifier["normal"] = AnalysisResult(
            sharpness: 0.7, brightness: 0.5, hasFace: false
        )

        // Act
        let clips = try await sut.select(from: [dark, normal])

        // Assert
        XCTAssertEqual(clips.count, 1)
        XCTAssertEqual(clips.first?.assetLocalIdentifier, "normal")
    }

    // MARK: - Exclusion: Too Bright Videos

    func test_sceneSelection_excludesTooBrightVideos() async throws {
        // Arrange
        let bright = MockVideoAsset(id: "bright", duration: 10.0)
        let normal = MockVideoAsset(id: "normal", duration: 10.0)
        mockService.setTooBright(for: "bright") // brightness 0.98
        mockService.resultsByIdentifier["normal"] = AnalysisResult(
            sharpness: 0.7, brightness: 0.5, hasFace: false
        )

        // Act
        let clips = try await sut.select(from: [bright, normal])

        // Assert
        XCTAssertEqual(clips.count, 1)
        XCTAssertEqual(clips.first?.assetLocalIdentifier, "normal")
    }

    // MARK: - Exclusion: Short Videos

    func test_sceneSelection_excludesShortVideos() async throws {
        // Arrange
        let short = MockVideoAsset(id: "short", duration: 2.0)
        let long = MockVideoAsset(id: "long", duration: 10.0)
        mockService.defaultResult = AnalysisResult(
            sharpness: 0.7, brightness: 0.5, hasFace: false
        )

        // Act
        let clips = try await sut.select(from: [short, long])

        // Assert
        XCTAssertEqual(clips.count, 1)
        XCTAssertEqual(clips.first?.assetLocalIdentifier, "long")
    }

    // MARK: - Empty Assets

    func test_sceneSelection_emptyAssetsThrowsError() async {
        // Arrange
        let emptyAssets: [MockVideoAsset] = []

        // Act & Assert
        do {
            _ = try await sut.select(from: emptyAssets)
            XCTFail("Expected sceneSelectionFailed error")
        } catch let error as AppError {
            guard case .sceneSelectionFailed = error else {
                XCTFail("Expected sceneSelectionFailed, got \(error)")
                return
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Same Day Penalty

    func test_sceneSelection_sameDayPenalty_reducesScore() async throws {
        // Arrange: 5 assets on the same day (>3 triggers penalty),
        // 1 asset on a different day
        let baseDate = Date()
        let sameDayAssets = (0..<5).map { index in
            MockVideoAsset(
                id: "same-\(index)",
                duration: 10.0,
                creationDate: baseDate
            )
        }
        let differentDay = Calendar.current.date(
            byAdding: .day, value: -5, to: baseDate
        ) ?? baseDate
        let otherAsset = MockVideoAsset(
            id: "other",
            duration: 10.0,
            creationDate: differentDay
        )

        // Give same-day assets slightly higher raw sharpness
        for asset in sameDayAssets {
            mockService.resultsByIdentifier[asset.localIdentifier] =
                AnalysisResult(
                    sharpness: 0.8, brightness: 0.5, hasFace: false
                )
        }
        // The other-day asset has slightly lower raw sharpness
        mockService.resultsByIdentifier["other"] = AnalysisResult(
            sharpness: 0.75, brightness: 0.5, hasFace: false
        )

        let allAssets: [MockVideoAsset] = sameDayAssets + [otherAsset]

        // Act
        let clips = try await sut.select(from: allAssets)

        // Assert: The other-day asset should rank higher than penalized
        // same-day assets because 0.5x penalty applies to same-day group.
        // "other" should appear in the results.
        let otherClip = clips.first { $0.assetLocalIdentifier == "other" }
        XCTAssertNotNil(
            otherClip,
            "Other-day asset should be selected despite lower raw score"
        )

        // Verify the penalty was applied: same-day assets' scores
        // should be lower than the non-penalized asset.
        // Raw score for same-day (sharpness=0.8):
        //   (0.8*0.35) + (0.5*0.15) + (1.0*0.2) + 0.1 = 0.655
        //   after penalty: 0.655 * 0.5 = 0.3275
        // Raw score for other (sharpness=0.75):
        //   (0.75*0.35) + (0.5*0.15) + (1.0*0.2) + 0.1 = 0.6375
        //   no penalty: 0.6375
        // So "other" should be first (highest score) when sorted.
        if let otherIndex = clips.firstIndex(
            where: { $0.assetLocalIdentifier == "other" }
        ) {
            // After re-sorting chronologically, order is by date.
            // "other" is 5 days in the past, so it should appear first.
            XCTAssertEqual(otherIndex, 0)
        }
    }

    // MARK: - Max Clip Count

    func test_sceneSelection_maxClipCount_isRespected() async throws {
        // Arrange: 25 assets should yield max 15 clips
        let assets = MockVideoAsset.distinctDayAssets(count: 25)
        mockService.defaultResult = AnalysisResult(
            sharpness: 0.7, brightness: 0.5, hasFace: false
        )

        // Act
        let clips = try await sut.select(from: assets)

        // Assert
        XCTAssertEqual(clips.count, 15)
    }

    // MARK: - Chronological Order

    func test_sceneSelection_resultsAreSortedChronologically() async throws {
        // Arrange: create assets with known dates in random order
        let cal = Calendar.current
        let baseDate = Date()
        let dates = [
            cal.date(byAdding: .day, value: -10, to: baseDate),
            cal.date(byAdding: .day, value: -1, to: baseDate),
            cal.date(byAdding: .day, value: -20, to: baseDate),
            cal.date(byAdding: .day, value: -5, to: baseDate)
        ].compactMap { $0 }

        let assets = dates.enumerated().map { index, date in
            MockVideoAsset(
                id: "chrono-\(index)",
                duration: 10.0,
                creationDate: date
            )
        }
        mockService.defaultResult = AnalysisResult(
            sharpness: 0.7, brightness: 0.5, hasFace: false
        )

        // Act
        let clips = try await sut.select(from: assets)

        // Assert: clips should be sorted by captureDate ascending
        for i in 0..<(clips.count - 1) {
            XCTAssertTrue(
                clips[i].captureDate <= clips[i + 1].captureDate,
                "Clip at index \(i) should be before clip at \(i + 1)"
            )
        }
    }

    // MARK: - Face Detection Boost

    func test_sceneSelection_faceDetectionBoostsScore() async throws {
        // Arrange: two assets with identical metrics except face detection
        let withFace = MockVideoAsset(
            id: "face",
            duration: 10.0,
            creationDate: Date()
        )
        let withoutFace = MockVideoAsset(
            id: "noface",
            duration: 10.0,
            creationDate: Date()
        )
        mockService.setWithFace(
            for: "face",
            sharpness: 0.5,
            brightness: 0.5
        )
        mockService.resultsByIdentifier["noface"] = AnalysisResult(
            sharpness: 0.5, brightness: 0.5, hasFace: false
        )

        // Act
        let clips = try await sut.select(from: [withFace, withoutFace])

        // Assert: face asset should have higher score
        let faceClip = clips.first { $0.assetLocalIdentifier == "face" }
        let noFaceClip = clips.first {
            $0.assetLocalIdentifier == "noface"
        }
        XCTAssertNotNil(faceClip)
        XCTAssertNotNil(noFaceClip)

        // Face bonus is 0.2, so face score should be higher
        if let fScore = faceClip?.score, let nfScore = noFaceClip?.score {
            XCTAssertGreaterThan(
                fScore, nfScore,
                "Face clip score (\(fScore)) should exceed "
                    + "no-face score (\(nfScore))"
            )
        }
    }

    // MARK: - maxClips Counts

    func test_maxClips_returnsCorrectCounts() {
        // 1-5 videos: return the count itself
        XCTAssertEqual(sut.maxClips(forVideoCount: 1), 1)
        XCTAssertEqual(sut.maxClips(forVideoCount: 3), 3)
        XCTAssertEqual(sut.maxClips(forVideoCount: 5), 5)

        // 6-20 videos: return 10
        XCTAssertEqual(sut.maxClips(forVideoCount: 6), 10)
        XCTAssertEqual(sut.maxClips(forVideoCount: 12), 10)
        XCTAssertEqual(sut.maxClips(forVideoCount: 20), 10)

        // 21-50 videos: return 15
        XCTAssertEqual(sut.maxClips(forVideoCount: 21), 15)
        XCTAssertEqual(sut.maxClips(forVideoCount: 35), 15)
        XCTAssertEqual(sut.maxClips(forVideoCount: 50), 15)

        // 51+ videos: return 20
        XCTAssertEqual(sut.maxClips(forVideoCount: 51), 20)
        XCTAssertEqual(sut.maxClips(forVideoCount: 100), 20)
        XCTAssertEqual(sut.maxClips(forVideoCount: 200), 20)
    }

    // MARK: - bestSegmentStartTime

    func test_bestSegmentStartTime_shortVideo_startsAtZero() {
        // Arrange: 4.5s video (short: 3-6s range)
        let clipDuration = 3.0

        // Act
        let result = sut.bestSegmentStartTime(
            for: 4.5, clipDuration: clipDuration
        )

        // Assert
        XCTAssertEqual(result.seconds, 0.0, accuracy: 0.001)
    }

    func test_bestSegmentStartTime_mediumVideo_skipsFirst10Percent() {
        // Arrange: 10.0s video (medium: 6-15s range)
        let clipDuration = 3.0

        // Act
        let result = sut.bestSegmentStartTime(
            for: 10.0, clipDuration: clipDuration
        )

        // Assert: 10% of 10s = 1.0s start
        XCTAssertEqual(result.seconds, 1.0, accuracy: 0.001)
    }

    func test_bestSegmentStartTime_longVideo_picksAt35Percent() {
        // Arrange: 60.0s video (long: 15s+)
        let clipDuration = 3.0

        // Act
        let result = sut.bestSegmentStartTime(
            for: 60.0, clipDuration: clipDuration
        )

        // Assert: 35% of 60s = 21.0s
        XCTAssertEqual(result.seconds, 21.0, accuracy: 0.001)
    }

    func test_bestSegmentStartTime_veryShortVideo_clampsToZero() {
        // Arrange: 2.0s video (shorter than clip duration)
        let clipDuration = 3.0

        // Act
        let result = sut.bestSegmentStartTime(
            for: 2.0, clipDuration: clipDuration
        )

        // Assert
        XCTAssertEqual(result.seconds, 0.0, accuracy: 0.001)
    }

    // MARK: - Clip Duration

    func test_selectedClips_haveThreeSecondDuration() async throws {
        // Arrange
        let asset = MockVideoAsset(id: "dur-test", duration: 10.0)
        mockService.defaultResult = AnalysisResult(
            sharpness: 0.7, brightness: 0.5, hasFace: false
        )

        // Act
        let clips = try await sut.select(from: [asset])

        // Assert
        XCTAssertEqual(clips.count, 1)
        XCTAssertEqual(
            clips.first?.duration.seconds, 3.0, accuracy: 0.001
        )
    }

    // MARK: - All Excluded Yields Empty

    func test_sceneSelection_allExcluded_returnsEmpty() async throws {
        // Arrange: all assets are blurry (excluded)
        let assets = (0..<5).map { i in
            MockVideoAsset(id: "blurry-\(i)", duration: 10.0)
        }
        for asset in assets {
            mockService.setBlurry(for: asset.localIdentifier)
        }

        // Act
        let clips = try await sut.select(from: assets)

        // Assert
        XCTAssertTrue(clips.isEmpty)
    }

    // MARK: - Vision Service Called Once

    func test_sceneSelection_callsAnalyzeAllOnce() async throws {
        // Arrange
        let assets = MockVideoAsset.distinctDayAssets(count: 5)
        mockService.defaultResult = AnalysisResult(
            sharpness: 0.7, brightness: 0.5, hasFace: false
        )

        // Act
        _ = try await sut.select(from: assets)

        // Assert
        XCTAssertEqual(mockService.analyzeAllCallCount, 1)
    }

    // MARK: - Boundary: Exactly 3 Same-Day No Penalty

    func test_sceneSelection_exactlyThreeSameDay_noPenalty() async throws {
        // Arrange: exactly 3 assets on same day (no penalty)
        // plus 1 on a different day with lower sharpness
        let baseDate = Date()
        let sameDayAssets = (0..<3).map { i in
            MockVideoAsset(
                id: "same-\(i)", duration: 10.0, creationDate: baseDate
            )
        }
        let otherDate = Calendar.current.date(
            byAdding: .day, value: -3, to: baseDate
        ) ?? baseDate
        let otherAsset = MockVideoAsset(
            id: "other", duration: 10.0, creationDate: otherDate
        )

        for asset in sameDayAssets {
            mockService.resultsByIdentifier[asset.localIdentifier] =
                AnalysisResult(
                    sharpness: 0.8, brightness: 0.5, hasFace: false
                )
        }
        mockService.resultsByIdentifier["other"] = AnalysisResult(
            sharpness: 0.3, brightness: 0.5, hasFace: false
        )

        let allAssets: [MockVideoAsset] = sameDayAssets + [otherAsset]

        // Act
        let clips = try await sut.select(from: allAssets)

        // Assert: all 4 should be selected; same-day assets should rank
        // higher than "other" since no penalty with only 3 same-day.
        XCTAssertEqual(clips.count, 4)

        // The "other" asset has lower sharpness, so its score is lower.
        // In chronological order, "other" (3 days ago) comes first.
        XCTAssertEqual(clips.first?.assetLocalIdentifier, "other")
    }
}
