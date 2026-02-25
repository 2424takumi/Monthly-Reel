import Photos
import CoreMedia
import OSLog

/// Protocol that abstracts PHAsset for testability.
/// Both PHAsset and mock objects conform to this protocol.
protocol VideoAssetProtocol {
    var localIdentifier: String { get }
    var duration: TimeInterval { get }
    var creationDate: Date? { get }
}

extension PHAsset: VideoAssetProtocol {}

/// Evaluates videos and selects the best clips for a monthly reel.
/// Uses Vision-based analysis to score each video by sharpness,
/// brightness, face presence, and duration.
final class SceneSelectionUseCase {

    private let visionService: VisionAnalysisServiceProtocol
    private let maxVideoScanCount = 200
    private let clipDuration: Double = 3.0

    init(visionService: VisionAnalysisServiceProtocol) {
        self.visionService = visionService
    }

    // MARK: - Public

    /// Evaluate all assets and select the best clips for a reel.
    /// Returns clips sorted chronologically by capture date.
    func select(
        from assets: [any VideoAssetProtocol]
    ) async throws -> [SelectedClip] {
        guard !assets.isEmpty else {
            throw AppError.sceneSelectionFailed
        }

        let capped = Array(assets.prefix(maxVideoScanCount))
        let analysisResults = try await visionService.analyzeAll(
            assets: capped
        )

        let scores = buildScores(assets: capped, results: analysisResults)
        let penalized = applyDateDiversityPenalty(to: scores)
        let eligible = penalized.filter { !$0.isExcluded }
        let sorted = eligible.sorted { $0.totalScore > $1.totalScore }
        let limit = maxClips(forVideoCount: capped.count)
        let selected = Array(sorted.prefix(limit))
        let chronological = selected.sorted {
            $0.captureDate < $1.captureDate
        }

        return chronological.map { score in
            let start = bestSegmentStartTime(
                for: score.duration,
                clipDuration: clipDuration
            )
            return SelectedClip(
                assetLocalIdentifier: score.assetIdentifier,
                startTime: start,
                duration: CMTime(
                    seconds: clipDuration,
                    preferredTimescale: 600
                ),
                score: score.totalScore,
                captureDate: score.captureDate
            )
        }
    }

    /// Determine max clip count based on source video count.
    func maxClips(forVideoCount count: Int) -> Int {
        switch count {
        case 1...5:   return count
        case 6...20:  return 10
        case 21...50: return 15
        default:      return 20
        }
    }

    /// Determine the best 3-second start time within a video.
    /// - Short (3-6s): start from beginning
    /// - Medium (6-15s): skip first 10%, then start
    /// - Long (15s+): pick segment at ~35% into the video
    func bestSegmentStartTime(
        for duration: Double,
        clipDuration: Double
    ) -> CMTime {
        let usable = max(duration - clipDuration, 0)

        switch duration {
        case ..<3.0:
            return .zero
        case 3.0..<6.0:
            return .zero
        case 6.0..<15.0:
            let offset = duration * 0.1
            let clamped = min(offset, usable)
            return CMTime(seconds: clamped, preferredTimescale: 600)
        default:
            // TODO: [MR-XXX] Implement Vision-based 5-segment analysis
            // to pick the sharpest segment. For MVP, pick ~35% into the
            // video which generally skips intros and avoids outros.
            let offset = duration * 0.35
            let clamped = min(offset, usable)
            return CMTime(seconds: clamped, preferredTimescale: 600)
        }
    }

    // MARK: - Private

    private func buildScores(
        assets: [any VideoAssetProtocol],
        results: [String: AnalysisResult]
    ) -> [SceneScore] {
        assets.compactMap { asset in
            guard let result = results[asset.localIdentifier] else {
                return nil
            }
            return SceneScore(
                assetIdentifier: asset.localIdentifier,
                sharpness: result.sharpness,
                brightness: result.brightness,
                hasFace: result.hasFace,
                duration: asset.duration,
                captureDate: asset.creationDate ?? Date.distantPast
            )
        }
    }

    private func applyDateDiversityPenalty(
        to scores: [SceneScore]
    ) -> [SceneScore] {
        let calendar = Calendar.current
        var dayCounts: [DateComponents: Int] = [:]

        for score in scores {
            let day = calendar.dateComponents(
                [.year, .month, .day],
                from: score.captureDate
            )
            dayCounts[day, default: 0] += 1
        }

        return scores.map { score in
            let day = calendar.dateComponents(
                [.year, .month, .day],
                from: score.captureDate
            )
            let count = dayCounts[day] ?? 0
            if count > 3 {
                var penalized = score
                penalized.totalScore *= 0.5
                return penalized
            }
            return score
        }
    }
}

// MARK: - SceneScore

/// Internal scoring model for a single video asset.
struct SceneScore {
    let assetIdentifier: String
    let sharpness: Double
    let brightness: Double
    let hasFace: Bool
    let duration: Double
    let captureDate: Date
    var isExcluded: Bool
    var durationScore: Double
    var totalScore: Double

    init(
        assetIdentifier: String,
        sharpness: Double,
        brightness: Double,
        hasFace: Bool,
        duration: Double,
        captureDate: Date
    ) {
        self.assetIdentifier = assetIdentifier
        self.sharpness = sharpness
        self.brightness = brightness
        self.hasFace = hasFace
        self.duration = duration
        self.captureDate = captureDate

        // Exclusion rules
        self.isExcluded = sharpness < 0.1
            || brightness < 0.15
            || brightness > 0.95
            || duration < 3.0

        // Duration scoring: prefer 5-30s videos
        switch duration {
        case ..<3.0:    self.durationScore = 0.0
        case 3.0..<5.0: self.durationScore = 0.5
        case 5.0...30:  self.durationScore = 1.0
        case 30..<60:   self.durationScore = 0.7
        default:        self.durationScore = 0.4
        }

        // Total score: weighted combination
        let faceBonus: Double = hasFace ? 0.2 : 0.0
        self.totalScore = (sharpness * 0.35)
            + (brightness * 0.15)
            + (durationScore * 0.2)
            + faceBonus
            + 0.1 // base score
    }
}

// MARK: - VisionAnalysisServiceProtocol

/// Protocol for vision analysis, enabling test mocks.
protocol VisionAnalysisServiceProtocol {
    func analyze(
        asset: any VideoAssetProtocol
    ) async throws -> AnalysisResult

    func analyzeAll(
        assets: [any VideoAssetProtocol]
    ) async throws -> [String: AnalysisResult]
}

/// Result of Vision-based analysis for a single video.
struct AnalysisResult {
    let sharpness: Double
    let brightness: Double
    let hasFace: Bool
}

// MARK: - SelectedClip

/// A clip selected for inclusion in the monthly reel.
struct SelectedClip {
    let assetLocalIdentifier: String
    let startTime: CMTime
    let duration: CMTime
    let score: Double
    let captureDate: Date
}

