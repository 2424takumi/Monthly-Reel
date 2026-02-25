import Vision
import AVFoundation
import Photos
import CoreImage
import OSLog

/// Analyzes video frames for sharpness, brightness, and face presence.
/// Uses Vision, Core Image, and AVAssetImageGenerator under the hood.
final class VisionAnalysisService: VisionAnalysisServiceProtocol {

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

    func analyze(asset: any VideoAssetProtocol) async throws -> AnalysisResult {
        let phAsset = try resolvePHAsset(from: asset)
        let avAsset = try await loadAVAsset(from: phAsset)
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

    func analyzeAll(
        assets: [any VideoAssetProtocol]
    ) async throws -> [String: AnalysisResult] {
        try await withThrowingTaskGroup(
            of: (String, AnalysisResult).self
        ) { group in
            for asset in assets {
                let identifier = asset.localIdentifier
                group.addTask {
                    let result = try await self.analyze(asset: asset)
                    return (identifier, result)
                }
            }
            var results: [String: AnalysisResult] = [:]
            for try await (identifier, result) in group {
                results[identifier] = result
            }
            return results
        }
    }
}

// MARK: - Asset Resolution

extension VisionAnalysisService {

    private func resolvePHAsset(
        from asset: any VideoAssetProtocol
    ) throws -> PHAsset {
        if let phAsset = asset as? PHAsset {
            return phAsset
        }
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [asset.localIdentifier],
            options: nil
        )
        guard let phAsset = fetchResult.firstObject else {
            throw AppError.sceneSelectionFailed
        }
        return phAsset
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
