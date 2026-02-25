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
