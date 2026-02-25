import SwiftUI
import SwiftData

/// Main entry point for the Monthly Reel app.
@main
struct MonthlyReelApp: App {
    private let container: DependencyContainer

    init() {
        do {
            container = try DependencyContainer()
        } catch {
            // Fatal at launch — SwiftData misconfiguration is unrecoverable.
            fatalError("Failed to initialize DependencyContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(container.appState)
                .environment(container.homeViewModel)
                .environment(container.archiveViewModel)
                .environment(container.playerViewModel)
                .fullScreenCover(isPresented: Bindable(container.appState).showOnboarding) {
                    OnboardingView()
                }
                .preferredColorScheme(.dark)
        }
        .modelContainer(container.modelContainer)
    }
}

// MARK: - MainTabView

/// Root tab view with three tabs: Home, Archive, Settings.
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(0)

            ArchiveView()
                .tabItem {
                    Label("アーカイブ", systemImage: "square.grid.2x2.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(Color.accentBlue)
    }
}
