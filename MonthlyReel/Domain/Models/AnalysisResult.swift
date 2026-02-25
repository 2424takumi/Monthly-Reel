import Foundation

/// Result of Vision-based analysis for a single video.
struct AnalysisResult: Sendable {
    let sharpness: Double
    let brightness: Double
    let hasFace: Bool
}
