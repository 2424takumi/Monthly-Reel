import SwiftUI

/// App color definitions.
/// Pure black background with blue accent for the dark-first design.
enum AppColors {
    static let background = Color.black
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.7)
    static let accent = Color(red: 0.4, green: 0.6, blue: 1.0)
    static let error = Color.red
    static let overlay = Color.black.opacity(0.4)
    static let cardBackground = Color.white.opacity(0.1)
}
