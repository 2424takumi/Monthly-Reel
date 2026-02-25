import Foundation

/// Centralized error type for the Monthly Reel app.
/// All errors surface through ViewModels as this type.
enum AppError: LocalizedError {
    case photoLibraryAccessDenied
    case noVideosInMonth(month: YearMonth)
    case sceneSelectionFailed
    case compositionFailed(underlying: Error)
    case exportFailed(underlying: Error)
    case gradingFailed(underlying: Error)
    case storageInsufficientSpace

    var errorDescription: String? {
        switch self {
        case .photoLibraryAccessDenied:
            return "写真ライブラリへのアクセスを許可してください"
        case .noVideosInMonth(let month):
            return "\(month.displayString)の動画が見つかりませんでした"
        case .sceneSelectionFailed:
            return "シーンの選定に失敗しました"
        case .compositionFailed:
            return "動画の合成に失敗しました"
        case .exportFailed:
            return "動画の書き出しに失敗しました"
        case .gradingFailed:
            return "カラーグレーディングの適用に失敗しました"
        case .storageInsufficientSpace:
            return "ストレージの空き容量が不足しています"
        }
    }
}
