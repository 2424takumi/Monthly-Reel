import SwiftData
import Foundation

/// Simple dependency injection container that creates and holds all dependencies.
/// Instantiated once at app launch and passed through the environment.
@MainActor
final class DependencyContainer {

    // MARK: - Core

    let modelContainer: ModelContainer
    let appState: AppState

    // MARK: - Repositories

    let photoLibraryRepository: PhotoLibraryRepository
    let videoArchiveRepository: VideoArchiveRepository

    // MARK: - Services

    let visionAnalysisService: VisionAnalysisService
    let compositionService: AVCompositionService

    // MARK: - Use Cases

    let sceneSelectionUseCase: SceneSelectionUseCase
    let gradingUseCase: GradingUseCase
    let videoGenerationUseCase: VideoGenerationUseCase

    // MARK: - View Models

    lazy var homeViewModel: HomeViewModel = {
        HomeViewModel(
            videoGenerationUseCase: videoGenerationUseCase,
            videoArchiveRepository: videoArchiveRepository,
            appState: appState
        )
    }()

    lazy var archiveViewModel: ArchiveViewModel = {
        ArchiveViewModel(
            videoArchiveRepository: videoArchiveRepository
        )
    }()

    lazy var playerViewModel: PlayerViewModel = {
        PlayerViewModel(
            gradingUseCase: gradingUseCase,
            appState: appState
        )
    }()

    // MARK: - Initialization

    init() throws {
        let schema = Schema([MonthlyReelModel.self])
        let config = ModelConfiguration(
            "MonthlyReel",
            schema: schema,
            isStoredInMemoryOnly: false
        )
        self.modelContainer = try ModelContainer(
            for: schema,
            configurations: [config]
        )

        self.appState = AppState()

        // Repositories
        self.photoLibraryRepository = PhotoLibraryRepository()
        self.videoArchiveRepository = VideoArchiveRepository(
            modelContext: modelContainer.mainContext
        )

        // Services
        self.visionAnalysisService = VisionAnalysisService()
        self.compositionService = AVCompositionService()

        // Use Cases
        self.sceneSelectionUseCase = SceneSelectionUseCase(
            visionService: visionAnalysisService
        )
        self.gradingUseCase = GradingUseCase()
        self.videoGenerationUseCase = VideoGenerationUseCase(
            photoLibraryRepository: photoLibraryRepository,
            sceneSelectionUseCase: sceneSelectionUseCase,
            compositionService: compositionService,
            gradingUseCase: gradingUseCase
        )

        // Check onboarding
        self.appState.showOnboarding = !UserDefaults.standard.bool(
            forKey: "hasCompletedOnboarding"
        )
    }
}
