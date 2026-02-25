import AVFoundation
import Photos
import UIKit
import OSLog

/// Composes multiple video clips into a single reel and exports to disk.
/// Also provides thumbnail generation from exported videos.
final class AVCompositionService {

    // MARK: - Types

    enum ExportQuality {
        case standard  // 720p
        case high      // 1080p

        var size: CGSize {
            switch self {
            case .standard: return CGSize(width: 1280, height: 720)
            case .high:     return CGSize(width: 1920, height: 1080)
            }
        }

        var videoBitRate: Int {
            switch self {
            case .standard: return 2_500_000
            case .high:     return 8_000_000
            }
        }
    }

    // MARK: - Constants

    enum Constants {
        static let thumbnailCompressionQuality: CGFloat = 0.8
        static let preferredTimescale: CMTimeScale = 600
        static let frameRate: CMTimeScale = 30
    }

    // MARK: - Internal Error

    enum CompositionError: Error {
        case trackCreationFailed
        case assetLoadFailed
        case noVideoTrack
        case exportSessionCreationFailed
        case exportFailed(String)
        case thumbnailGenerationFailed
    }

    // MARK: - Public API

    func compose(
        clips: [SelectedClip],
        quality: ExportQuality
    ) async throws -> URL {
        let composition = AVMutableComposition()
        let videoComposition = AVMutableVideoComposition()
        var instructions: [AVMutableVideoCompositionInstruction] = []
        var cursor = CMTime.zero

        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw AppError.compositionFailed(
                underlying: CompositionError.trackCreationFailed
            )
        }

        let compositionAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )

        for clip in clips {
            let clipCursor = try await insertClip(
                clip,
                into: compositionVideoTrack,
                audioTrack: compositionAudioTrack,
                at: cursor,
                outputSize: quality.size,
                instructions: &instructions
            )
            cursor = clipCursor
        }

        videoComposition.instructions = instructions
        videoComposition.renderSize = quality.size
        videoComposition.frameDuration = CMTime(
            value: 1,
            timescale: Constants.frameRate
        )

        return try await exportComposition(
            composition,
            videoComposition: videoComposition,
            quality: quality
        )
    }

    func generateThumbnail(from videoURL: URL) async throws -> Data {
        let avAsset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: avAsset)
        generator.appliesPreferredTrackTransform = true

        let (cgImage, _) = try await generator.image(at: .zero)
        let uiImage = UIImage(cgImage: cgImage)

        guard let jpegData = uiImage.jpegData(
            compressionQuality: Constants.thumbnailCompressionQuality
        ) else {
            throw AppError.exportFailed(
                underlying: CompositionError.thumbnailGenerationFailed
            )
        }
        return jpegData
    }
}
