import SwiftUI

/// Global observable state shared across the app.
/// Injected into the SwiftUI environment from the root scene.
@Observable
final class AppState {
    var currentMonth: YearMonth = .current
    var generationStatus: GenerationStatus = .idle
    var selectedPreset: ColorPreset = .clean
    var reels: [MonthlyReelModel] = []
    var showOnboarding: Bool = false
    var errorAlert: AppError?
}
