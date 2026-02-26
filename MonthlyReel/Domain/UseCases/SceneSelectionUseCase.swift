import Photos
import CoreMedia
import OSLog

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
