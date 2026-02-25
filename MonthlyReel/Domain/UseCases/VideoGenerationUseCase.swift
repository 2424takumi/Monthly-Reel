import Foundation
import Photos
import OSLog

/// Callback for progress updates during reel generation.
typealias ProgressCallback = @Sendable (GenerationStatus) -> Void

/// Represents the current phase and progress of reel generation.
enum GenerationStatus: Sendable {
    case idle
    case scanning(progress: Double)
    case selecting(progress: Double)
    case compositing(progress: Double)
    case grading(progress: Double)
    case completed(
        videoURL: URL,
        thumbnailData: Data,
        clipCount: Int,
        sourceVideoCount: Int,
        duration: Double
    )
    case failed(error: AppError)
}

/// Result returned upon successful reel generation.
struct GenerationResult: Sendable {
    let videoURL: URL
    let thumbnailData: Data
    let clipCount: Int
    let sourceVideoCount: Int
    let duration: Double
}

/// Main pipeline orchestrator for monthly reel generation.
/// Coordinates four phases: scan, select, composite, and grade.
final class VideoGenerationUseCase {

    private let photoLibraryRepository: PhotoLibraryRepositoryProtocol
    private let sceneSelectionUseCase: SceneSelectionUseCase
    private let compositionService: AVCompositionServiceProtocol
    private let gradingUseCase: GradingUseCase

    init(
        photoLibraryRepository: PhotoLibraryRepositoryProtocol,
        sceneSelectionUseCase: SceneSelectionUseCase,
        compositionService: AVCompositionServiceProtocol,
        gradingUseCase: GradingUseCase
    ) {
        self.photoLibraryRepository = photoLibraryRepository
        self.sceneSelectionUseCase = sceneSelectionUseCase
        self.compositionService = compositionService
        self.gradingUseCase = gradingUseCase
    }

    /// Generate a monthly highlight reel for the given month.
    /// Reports progress through the callback across four phases:
    /// - Phase 1 (0%-30%): Scan videos from photo library
    /// - Phase 2 (30%-60%): Select best scenes
    /// - Phase 3 (60%-90%): Composite clips into video
    /// - Phase 4 (90%-100%): Apply color grading
    func generate(
        for month: YearMonth,
        preset: ColorPreset = .clean,
        quality: ExportQuality = .standard,
        onProgress: ProgressCallback? = nil
    ) async throws -> GenerationResult {
        // Phase 1: Scan (0% - 30%)
        onProgress?(.scanning(progress: 0.0))
        let assets = try await photoLibraryRepository.fetchVideos(
            in: month
        )
        try Task.checkCancellation()
        onProgress?(.scanning(progress: 0.3))

        // Phase 2: Select (30% - 60%)
        onProgress?(.selecting(progress: 0.3))
        let clips = try await sceneSelectionUseCase.select(from: assets)
        try Task.checkCancellation()
        onProgress?(.selecting(progress: 0.6))

        // Phase 3: Composite (60% - 90%)
        onProgress?(.compositing(progress: 0.6))
        let rawVideoURL = try await compositionService.compose(
            clips: clips,
            quality: quality
        )
        let thumbnailData = try await compositionService.generateThumbnail(
            from: rawVideoURL
        )
        try Task.checkCancellation()
        onProgress?(.compositing(progress: 0.9))

        // Phase 4: Grade (90% - 100%)
        onProgress?(.grading(progress: 0.9))
        let gradedURL = try await applyGrading(
            preset: preset,
            rawVideoURL: rawVideoURL
        )
        try Task.checkCancellation()

        let duration = clips.reduce(0.0) { $0 + $1.duration.seconds }
        let result = GenerationResult(
            videoURL: gradedURL,
            thumbnailData: thumbnailData,
            clipCount: clips.count,
            sourceVideoCount: assets.count,
            duration: duration
        )

        onProgress?(.completed(
            videoURL: gradedURL,
            thumbnailData: thumbnailData,
            clipCount: clips.count,
            sourceVideoCount: assets.count,
            duration: duration
        ))

        Logger.composition.info(
            "Reel generated: \(clips.count) clips, \(duration)s"
        )
        return result
    }

    // MARK: - Private

    private func applyGrading(
        preset: ColorPreset,
        rawVideoURL: URL
    ) async throws -> URL {
        guard preset != .clean else {
            return rawVideoURL
        }

        let gradedURL = try await gradingUseCase.apply(
            preset: preset,
            to: rawVideoURL
        )
        try? FileManager.default.removeItem(at: rawVideoURL)
        return gradedURL
    }
}

// MARK: - ExportQuality

/// Video export quality levels.
enum ExportQuality: String, Sendable {
    case standard
    case high
}

// MARK: - AVCompositionServiceProtocol

/// Protocol for the composition service, enabling test mocks.
protocol AVCompositionServiceProtocol {
    func compose(
        clips: [SelectedClip],
        quality: ExportQuality
    ) async throws -> URL

    func generateThumbnail(from videoURL: URL) async throws -> Data
}

