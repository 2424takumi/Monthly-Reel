import Photos

/// Protocol that abstracts PHAsset for testability.
/// Both PHAsset and mock objects conform to this protocol.
protocol VideoAssetProtocol {
    var localIdentifier: String { get }
    var duration: TimeInterval { get }
    var creationDate: Date? { get }
}

extension PHAsset: VideoAssetProtocol {}
