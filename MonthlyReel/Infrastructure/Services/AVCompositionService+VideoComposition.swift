import AVFoundation
import OSLog

// MARK: - Video Composition Instructions

extension AVCompositionService {

    func buildLayerInstruction(
        for compositionTrack: AVMutableCompositionTrack,
        sourceTrack: AVAssetTrack,
        at cursor: CMTime,
        duration: CMTime,
        outputSize: CGSize
    ) async throws -> AVMutableVideoCompositionInstruction {
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(
            start: cursor,
            duration: duration
        )

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(
            assetTrack: compositionTrack
        )

        let transform = try await computeTransform(
            for: sourceTrack,
            outputSize: outputSize
        )
        layerInstruction.setTransform(transform, at: cursor)
        instruction.layerInstructions = [layerInstruction]

        return instruction
    }

    func computeTransform(
        for sourceTrack: AVAssetTrack,
        outputSize: CGSize
    ) async throws -> CGAffineTransform {
        let naturalSize = try await sourceTrack.load(.naturalSize)
        let preferredTransform = try await sourceTrack.load(
            .preferredTransform
        )
        let transformedSize = naturalSize.applying(preferredTransform)
        let sourceSize = CGSize(
            width: abs(transformedSize.width),
            height: abs(transformedSize.height)
        )

        return centerCropTransform(
            source: sourceSize,
            preferredTransform: preferredTransform,
            output: outputSize
        )
    }

    func centerCropTransform(
        source: CGSize,
        preferredTransform: CGAffineTransform,
        output: CGSize
    ) -> CGAffineTransform {
        let scaleX = output.width / source.width
        let scaleY = output.height / source.height
        let scale = max(scaleX, scaleY)

        let scaledWidth = source.width * scale
        let scaledHeight = source.height * scale
        let offsetX = (output.width - scaledWidth) / 2.0
        let offsetY = (output.height - scaledHeight) / 2.0

        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
        let translateTransform = CGAffineTransform(
            translationX: offsetX,
            y: offsetY
        )

        return preferredTransform
            .concatenating(scaleTransform)
            .concatenating(translateTransform)
    }
}

// MARK: - Export

extension AVCompositionService {

    func exportComposition(
        _ composition: AVMutableComposition,
        videoComposition: AVMutableVideoComposition,
        quality: ExportQuality
    ) async throws -> URL {
        try VideoArchiveRepository.ensureDirectoriesExist()

        let outputURL = VideoArchiveRepository.reelsDirectoryURL
            .appendingPathComponent("\(UUID().uuidString).mp4")

        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw AppError.exportFailed(
                underlying: CompositionError.exportSessionCreationFailed
            )
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition
        exportSession.shouldOptimizeForNetworkUse = true

        await exportSession.export()

        guard exportSession.status == .completed else {
            let message = exportSession.error?.localizedDescription
                ?? "Unknown export error"
            Logger.composition.error("Export failed: \(message)")
            throw AppError.exportFailed(
                underlying: CompositionError.exportFailed(message)
            )
        }

        Logger.composition.info(
            "Exported reel to \(outputURL.lastPathComponent)"
        )
        return outputURL
    }
}
