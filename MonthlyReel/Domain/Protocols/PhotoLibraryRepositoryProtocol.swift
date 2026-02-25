import Photos

/// Protocol for photo library access.
/// Implementations handle authorization and fetching videos for a given month.
protocol PhotoLibraryRepositoryProtocol {
    func requestAuthorization() async -> PHAuthorizationStatus
    func fetchVideos(in month: YearMonth) async throws -> [PHAsset]
}
