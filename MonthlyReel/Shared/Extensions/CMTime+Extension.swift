import CoreMedia

/// Convenience extensions for CMTime creation and access.
extension CMTime {
    private static let preferredScale: CMTimeScale = 600

    static func seconds(_ value: Double) -> CMTime {
        CMTimeMakeWithSeconds(value, preferredTimescale: preferredScale)
    }

    var secondsValue: Double {
        CMTimeGetSeconds(self)
    }
}
