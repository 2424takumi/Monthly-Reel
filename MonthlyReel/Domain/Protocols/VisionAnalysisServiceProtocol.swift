import Foundation

/// Protocol for vision analysis, enabling test mocks.
protocol VisionAnalysisServiceProtocol {
    func analyze(
        asset: any VideoAssetProtocol
    ) async throws -> AnalysisResult

    func analyzeAll(
        assets: [any VideoAssetProtocol]
    ) async throws -> [String: AnalysisResult]
}
