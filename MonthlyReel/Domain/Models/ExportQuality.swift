import Foundation

/// Video export quality options stored in UserDefaults.
/// Used by SettingsView and HomeViewModel to determine render resolution.
enum ExportQuality: String, CaseIterable {
    case standard
    case high

    var displayName: String {
        switch self {
        case .standard: return "標準 (720p)"
        case .high: return "高品質 (1080p)"
        }
    }
}
