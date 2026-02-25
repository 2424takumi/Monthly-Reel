import SwiftUI

/// Common View extensions for the Monthly Reel dark-first UI.
extension View {
    func fullScreenBlackBackground() -> some View {
        self.background(AppColors.background)
            .preferredColorScheme(.dark)
    }
}
