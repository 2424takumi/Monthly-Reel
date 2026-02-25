import Foundation

/// Callback for progress updates during reel generation.
typealias ProgressCallback = @Sendable (GenerationStatus) -> Void

/// Represents the current phase and progress of reel generation.
enum GenerationStatus: Sendable {
    case idle
    case scanning(progress: Double)
    case selecting(progress: Double)
    case compositing(progress: Double)
    case grading(progress: Double)
    case completed(
        videoURL: URL,
        thumbnailData: Data,
        clipCount: Int,
        sourceVideoCount: Int,
        duration: Double
    )
    case failed(error: AppError)
}

/// Result returned upon successful reel generation.
struct GenerationResult: Sendable {
    let videoURL: URL
    let thumbnailData: Data
    let clipCount: Int
    let sourceVideoCount: Int
    let duration: Double
}
