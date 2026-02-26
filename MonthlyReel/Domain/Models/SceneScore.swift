import Foundation

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

    /// Thresholds for excluding low-quality videos from selection.
    enum Threshold {
        static let minSharpness: Double = 0.1
        static let minBrightness: Double = 0.15
        static let maxBrightness: Double = 0.95
        static let minDuration: Double = 3.0
    }

    /// Weights for the composite quality score calculation.
    enum Weight {
        static let sharpness: Double = 0.35
        static let brightness: Double = 0.15
        static let duration: Double = 0.2
        static let faceBonus: Double = 0.2
        static let base: Double = 0.1
    }

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
        self.isExcluded = sharpness < Threshold.minSharpness
            || brightness < Threshold.minBrightness
            || brightness > Threshold.maxBrightness
            || duration < Threshold.minDuration

        // Duration scoring: prefer 5-30s videos
        switch duration {
        case ..<3.0:    self.durationScore = 0.0
        case 3.0..<5.0: self.durationScore = 0.5
        case 5.0...30:  self.durationScore = 1.0
        case 30..<60:   self.durationScore = 0.7
        default:        self.durationScore = 0.4
        }

        // Total score: weighted combination
        let faceBonus: Double = hasFace ? Weight.faceBonus : 0.0
        self.totalScore = (sharpness * Weight.sharpness)
            + (brightness * Weight.brightness)
            + (durationScore * Weight.duration)
            + faceBonus
            + Weight.base
    }
}
