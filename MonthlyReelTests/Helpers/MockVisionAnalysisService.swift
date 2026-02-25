import Foundation
@testable import MonthlyReel

/// Mock implementation of VisionAnalysisServiceProtocol.
/// Returns predetermined AnalysisResult values keyed by asset identifier,
/// with a configurable default fallback.
final class MockVisionAnalysisService: VisionAnalysisServiceProtocol {

    /// Per-asset results keyed by localIdentifier.
    var resultsByIdentifier: [String: AnalysisResult] = [:]

    /// Default result returned when no per-asset override exists.
    var defaultResult = AnalysisResult(
        sharpness: 0.7,
        brightness: 0.5,
        hasFace: false
    )

    /// Tracks the number of times analyzeAll was called.
    private(set) var analyzeAllCallCount = 0

    /// Optional error to throw on next call.
    var errorToThrow: Error?

    // MARK: - VisionAnalysisServiceProtocol

    func analyze(
        asset: any VideoAssetProtocol
    ) async throws -> AnalysisResult {
        if let error = errorToThrow {
            throw error
        }
        return resultsByIdentifier[asset.localIdentifier] ?? defaultResult
    }

    func analyzeAll(
        assets: [any VideoAssetProtocol]
    ) async throws -> [String: AnalysisResult] {
        if let error = errorToThrow {
            throw error
        }
        analyzeAllCallCount += 1

        var results: [String: AnalysisResult] = [:]
        for asset in assets {
            let result = resultsByIdentifier[asset.localIdentifier]
                ?? defaultResult
            results[asset.localIdentifier] = result
        }
        return results
    }
}

// MARK: - Configuration Helpers

extension MockVisionAnalysisService {

    /// Configure a specific asset to return blurry analysis.
    func setBlurry(for identifier: String) {
        resultsByIdentifier[identifier] = AnalysisResult(
            sharpness: 0.05,
            brightness: 0.5,
            hasFace: false
        )
    }

    /// Configure a specific asset to return too-dark analysis.
    func setTooDark(for identifier: String) {
        resultsByIdentifier[identifier] = AnalysisResult(
            sharpness: 0.7,
            brightness: 0.10,
            hasFace: false
        )
    }

    /// Configure a specific asset to return too-bright analysis.
    func setTooBright(for identifier: String) {
        resultsByIdentifier[identifier] = AnalysisResult(
            sharpness: 0.7,
            brightness: 0.98,
            hasFace: false
        )
    }

    /// Configure a specific asset with face detection.
    func setWithFace(
        for identifier: String,
        sharpness: Double = 0.7,
        brightness: Double = 0.5
    ) {
        resultsByIdentifier[identifier] = AnalysisResult(
            sharpness: sharpness,
            brightness: brightness,
            hasFace: true
        )
    }
}
