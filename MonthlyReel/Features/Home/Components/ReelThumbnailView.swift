import SwiftUI

/// Displays a reel thumbnail image in 9:16 aspect ratio with gradient overlays
/// and a centered play button.
struct ReelThumbnailView: View {
    let thumbnailData: Data
    let onTap: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                thumbnailImage(in: geometry)
                gradientOverlay
                playButton
            }
        }
        .aspectRatio(9.0 / 16.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

// MARK: - Subviews

private extension ReelThumbnailView {
    func thumbnailImage(in geometry: GeometryProxy) -> some View {
        Group {
            if let uiImage = UIImage(data: thumbnailData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
            }
        }
    }

    var gradientOverlay: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [.black.opacity(0.6), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)

            Spacer()

            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
        }
    }

    var playButton: some View {
        Circle()
            .fill(.white.opacity(0.3))
            .frame(width: 64, height: 64)
            .overlay {
                Image(systemName: "play.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .offset(x: 2)
            }
    }
}
