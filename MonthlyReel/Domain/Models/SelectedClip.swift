import CoreMedia

/// A clip selected for inclusion in the monthly reel.
struct SelectedClip: Sendable {
    let assetLocalIdentifier: String
    let startTime: CMTime
    let duration: CMTime
    let score: Double
    let captureDate: Date
}
