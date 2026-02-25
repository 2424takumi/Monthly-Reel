import Vision
import AVFoundation
import Photos
import CoreImage
import OSLog

/// Analyzes video frames for sharpness, brightness, and face presence.
/// Uses Vision, Core Image, and AVAssetImageGenerator under the hood.
final class VisionAnalysisService {

    // MARK: - Types

    struct AnalysisResult {
        let sharpness: Double   // 0.0 - 1.0
        let brightness: Double  // 0.0 - 1.0
        let hasFace: Bool
    }

    // MARK: - Constants

    enum Constants {
        static let sharpnessNormalizationDivisor: Double = 500.0
        static let luminanceRedCoefficient: Double = 0.299
        static let luminanceGreenCoefficient: Double = 0.587
        static let luminanceBlueCoefficient: Double = 0.114
        static let averagePixelByteCount = 4
    }

    // MARK: - Properties

    let ciContext = CIContext()

    // MARK: - Public API

    func analyze(asset: PHAsset) async throws -> AnalysisResult {
        let avAsset = try await loadAVAsset(from: asset)
        let cgImage = try await extractFirstFrame(from: avAsset)

        async let sharpnessResult = computeSharpness(from: cgImage)
        async let brightnessResult = computeBrightness(from: cgImage)
        async let faceResult = detectFace(in: cgImage)

        return try await AnalysisResult(
            sharpness: sharpnessResult,
            brightness: brightnessResult,
            hasFace: faceResult
        )
    }

    func analyzeAll(assets: [PHAsset]) async throws -> [PHAsset: AnalysisResult] {
        try await withThrowingTaskGroup(
            of: (PHAsset, AnalysisResult).self
        ) { group in
            for asset in assets {
                group.addTask {
                    let result = try await self.analyze(asset: asset)
                    return (asset, result)
                }
            }
            var results: [PHAsset: AnalysisResult] = [:]
            for try await (asset, result) in group {
                results[asset] = result
            }
            return results
        }
    }
}

// MARK: - Asset Loading

extension VisionAnalysisService {

    func loadAVAsset(from asset: PHAsset) async throws -> AVAsset {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.version = .current
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestAVAsset(
                forVideo: asset,
                options: options
            ) { avAsset, _, _ in
                guard let avAsset else {
                    continuation.resume(
                        throwing: AppError.sceneSelectionFailed
                    )
                    return
                }
                continuation.resume(returning: avAsset)
            }
        }
    }

    func extractFirstFrame(from avAsset: AVAsset) async throws -> CGImage {
        let generator = AVAssetImageGenerator(asset: avAsset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = CMTime(
            seconds: 1,
            preferredTimescale: 600
        )

        let (image, _) = try await generator.image(at: .zero)
        return image
    }
}
