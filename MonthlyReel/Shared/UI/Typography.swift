import SwiftUI

/// Typography definitions using SF Pro Rounded.
enum AppTypography {
    static let largeTitle = Font.system(size: 48, weight: .bold, design: .rounded)
    static let title = Font.system(size: 24, weight: .bold, design: .rounded)
    static let body = Font.system(size: 16, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
    static let button = Font.system(size: 17, weight: .semibold, design: .rounded)
}
