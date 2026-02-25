import Foundation
import CoreGraphics

/// Video export quality options stored in UserDefaults.
/// Single source of truth used by SettingsView, HomeViewModel,
/// AVCompositionService, and VideoGenerationUseCase.
enum ExportQuality: String, CaseIterable, Sendable {
    case standard
    case high

    var displayName: String {
        switch self {
        case .standard: return "標準 (720p)"
        case .high: return "高品質 (1080p)"
        }
    }

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

    var audioBitRate: Int {
        switch self {
        case .standard: return 128_000
        case .high:     return 192_000
        }
    }
}
