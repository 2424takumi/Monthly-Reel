import AVFoundation
import Photos

// MARK: - Asset Loading

extension AVCompositionService {

    func loadAVAsset(identifier: String) async throws -> AVAsset {
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [identifier],
            options: nil
        )
        guard let phAsset = fetchResult.firstObject else {
            throw AppError.compositionFailed(
                underlying: CompositionError.assetLoadFailed
            )
        }

        return try await withCheckedThrowingContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.version = .current
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestAVAsset(
                forVideo: phAsset,
                options: options
            ) { avAsset, _, _ in
                guard let avAsset else {
                    continuation.resume(
                        throwing: AppError.compositionFailed(
                            underlying: CompositionError.assetLoadFailed
                        )
                    )
                    return
                }
                continuation.resume(returning: avAsset)
            }
        }
    }
}

// MARK: - Clip Insertion

extension AVCompositionService {

    func insertClip(
        _ clip: SelectedClip,
        into videoTrack: AVMutableCompositionTrack,
        audioTrack: AVMutableCompositionTrack?,
        at cursor: CMTime,
        outputSize: CGSize,
        instructions: inout [AVMutableVideoCompositionInstruction]
    ) async throws -> CMTime {
        let avAsset = try await loadAVAsset(identifier: clip.assetIdentifier)
        let duration = clip.timeRange.duration
        let insertRange = clip.timeRange

        if let sourceVideoTrack = try await avAsset.loadTracks(
            withMediaType: .video
        ).first {
            try videoTrack.insertTimeRange(
                insertRange,
                of: sourceVideoTrack,
                at: cursor
            )

            let instruction = try await buildLayerInstruction(
                for: videoTrack,
                sourceTrack: sourceVideoTrack,
                at: cursor,
                duration: duration,
                outputSize: outputSize
            )
            instructions.append(instruction)
        }

        if let sourceAudioTrack = try await avAsset.loadTracks(
            withMediaType: .audio
        ).first, let audioTrack {
            try? audioTrack.insertTimeRange(
                insertRange,
                of: sourceAudioTrack,
                at: cursor
            )
        }

        return CMTimeAdd(cursor, duration)
    }
}
