import Foundation

/// Protocol for the composition service, enabling test mocks.
protocol AVCompositionServiceProtocol {
    func compose(
        clips: [SelectedClip],
        quality: ExportQuality
    ) async throws -> URL

    func generateThumbnail(from videoURL: URL) async throws -> Data
}
