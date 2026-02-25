import AVFoundation
import CoreImage
import OSLog

/// Applies color grading (CIFilter chain) to a composed video file.
/// Uses the ColorPreset's filter chain via the ColorGrading protocol.
final class GradingUseCase {

    private let ciContext: CIContext

    init() {
        self.ciContext = CIContext(
            options: [.useSoftwareRenderer: false]
        )
    }

    /// Apply a color preset to a video file and export to a new URL.
    /// Returns the URL of the graded output file.
    func apply(
        preset: ColorPreset,
        to sourceURL: URL
    ) async throws -> URL {
        let asset = AVAsset(url: sourceURL)
        let videoTrack = try await loadVideoTrack(from: asset)
        let naturalSize = try await videoTrack.load(.naturalSize)
        let transform = try await videoTrack.load(.preferredTransform)

        let videoComposition = buildVideoComposition(
            asset: asset,
            preset: preset,
            naturalSize: naturalSize,
            transform: transform
        )

        let outputURL = makeOutputURL()

        let exportSession = try createExportSession(
            asset: asset,
            outputURL: outputURL,
            videoComposition: videoComposition
        )

        await exportSession.export()

        guard exportSession.status == .completed else {
            throw AppError.gradingFailed(
                underlying: exportSession.error ?? unknownError()
            )
        }

        Logger.grading.info(
            "Applied \(preset.rawValue) grading successfully"
        )
        return outputURL
    }

    // MARK: - Private

    private func loadVideoTrack(
        from asset: AVAsset
    ) async throws -> AVAssetTrack {
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard let track = tracks.first else {
            throw AppError.gradingFailed(
                underlying: NSError(
                    domain: "GradingUseCase",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "No video track found"
                    ]
                )
            )
        }
        return track
    }

    private func buildVideoComposition(
        asset: AVAsset,
        preset: ColorPreset,
        naturalSize: CGSize,
        transform: CGAffineTransform
    ) -> AVMutableVideoComposition {
        let composition = AVMutableVideoComposition(
            asset: asset
        ) { [ciContext] request in
            let source = request.sourceImage.clampedToExtent()
            let output = preset.apply(to: source)
            let cropped = output.cropped(to: request.sourceImage.extent)
            request.finish(with: cropped, context: ciContext)
        }

        let isPortrait = transform.a == 0
        if isPortrait {
            composition.renderSize = CGSize(
                width: naturalSize.height,
                height: naturalSize.width
            )
        } else {
            composition.renderSize = naturalSize
        }
        composition.frameDuration = CMTime(value: 1, timescale: 30)

        return composition
    }

    private func makeOutputURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
    }

    private func createExportSession(
        asset: AVAsset,
        outputURL: URL,
        videoComposition: AVMutableVideoComposition
    ) throws -> AVAssetExportSession {
        guard let session = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw AppError.gradingFailed(
                underlying: NSError(
                    domain: "GradingUseCase",
                    code: -2,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Could not create export session"
                    ]
                )
            )
        }

        session.outputURL = outputURL
        session.outputFileType = .mp4
        session.videoComposition = videoComposition
        return session
    }

    private func unknownError() -> NSError {
        NSError(
            domain: "GradingUseCase",
            code: -3,
            userInfo: [
                NSLocalizedDescriptionKey: "Unknown export error"
            ]
        )
    }
}

