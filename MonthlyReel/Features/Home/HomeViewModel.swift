import Foundation

/// View model driving the Home screen.
/// Coordinates reel generation and propagates status through AppState.
@Observable
@MainActor
final class HomeViewModel {

    // MARK: - Dependencies

    private let videoGenerationUseCase: VideoGenerationUseCase
    private let videoArchiveRepository: VideoArchiveRepositoryProtocol
    private let appState: AppState
    private var generationTask: Task<Void, Never>?

    // MARK: - Computed State

    var generationStatus: GenerationStatus { appState.generationStatus }
    var currentMonth: YearMonth { appState.currentMonth }
    var selectedPreset: ColorPreset { appState.selectedPreset }

    // MARK: - Init

    init(
        videoGenerationUseCase: VideoGenerationUseCase,
        videoArchiveRepository: VideoArchiveRepositoryProtocol,
        appState: AppState
    ) {
        self.videoGenerationUseCase = videoGenerationUseCase
        self.videoArchiveRepository = videoArchiveRepository
        self.appState = appState
    }

    // MARK: - Actions

    /// Kicks off asynchronous reel generation for the current month.
    func startGeneration() {
        guard case .idle = appState.generationStatus else { return }
        guard case .failed = appState.generationStatus else {
            beginGeneration()
            return
        }
        beginGeneration()
    }

    /// Cancels any in-flight generation work and resets to idle.
    func cancel() {
        generationTask?.cancel()
        generationTask = nil
        appState.generationStatus = .idle
    }
}

// MARK: - Private Helpers

private extension HomeViewModel {
    func beginGeneration() {
        generationTask = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await self.videoGenerationUseCase.generate(
                    for: self.appState.currentMonth,
                    preset: self.appState.selectedPreset,
                    quality: self.currentQuality
                ) { [weak self] status in
                    Task { @MainActor [weak self] in
                        self?.appState.generationStatus = status
                    }
                }
                try Task.checkCancellation()
                try await self.videoArchiveRepository.save(result)
                self.appState.generationStatus = .completed(
                    videoURL: result.videoURL,
                    thumbnailData: result.thumbnailData,
                    clipCount: result.clipCount,
                    sourceVideoCount: result.sourceVideoCount,
                    duration: result.duration
                )
            } catch is CancellationError {
                self.appState.generationStatus = .idle
            } catch {
                self.appState.generationStatus = .failed(
                    error: error as? AppError ?? .compositionFailed(underlying: error)
                )
            }
        }
    }

    var currentQuality: ExportQuality {
        let raw = UserDefaults.standard.string(forKey: "reelQuality") ?? "standard"
        return ExportQuality(rawValue: raw) ?? .standard
    }
}
