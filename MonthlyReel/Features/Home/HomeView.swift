import SwiftUI

/// Main home screen with state-driven UI based on reel generation status.
struct HomeView: View {
    @Environment(HomeViewModel.self) private var viewModel
    @State private var showPlayer = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.generationStatus {
            case .idle:
                idleContent

            case .scanning(let progress):
                GenerationProgressView(
                    progress: progress,
                    statusText: "スキャン中...",
                    onCancel: { viewModel.cancel() }
                )

            case .selecting(let progress):
                GenerationProgressView(
                    progress: progress,
                    statusText: "ベストシーンを選んでいます...",
                    onCancel: { viewModel.cancel() }
                )

            case .compositing(let progress):
                GenerationProgressView(
                    progress: progress,
                    statusText: "動画を合成中...",
                    onCancel: { viewModel.cancel() }
                )

            case .grading(let progress):
                GenerationProgressView(
                    progress: progress,
                    statusText: "カラーを適用中...",
                    onCancel: { viewModel.cancel() }
                )

            case .completed(let videoURL, let thumbnailData, _, _, _):
                completedContent(videoURL: videoURL, thumbnailData: thumbnailData)

            case .failed(let error):
                failedContent(error: error)
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if case .completed(let videoURL, _, _, _, _) = viewModel.generationStatus {
                ReelPlayerView(
                    videoURL: videoURL,
                    month: viewModel.currentMonth
                )
            }
        }
    }
}

// MARK: - Idle Content

private extension HomeView {
    var idleContent: some View {
        VStack(spacing: 40) {
            Spacer()

            Text(viewModel.currentMonth.displayString)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            generateButton

            Spacer()
                .frame(height: 32)
        }
        .padding(.horizontal, 24)
    }

    var generateButton: some View {
        Button {
            viewModel.startGeneration()
        } label: {
            Text("今月のリールを生成")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.accentBlue)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Completed Content

private extension HomeView {
    func completedContent(videoURL: URL, thumbnailData: Data) -> some View {
        VStack(spacing: 0) {
            ReelThumbnailView(thumbnailData: thumbnailData) {
                showPlayer = true
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Failed Content

private extension HomeView {
    func failedContent(error: AppError) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)

            Text(error.errorDescription ?? "エラーが発生しました")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                viewModel.startGeneration()
            } label: {
                Text("リトライ")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.accentBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

// MARK: - Accent Color Extension

extension Color {
    /// App-wide accent blue used for interactive elements.
    static let accentBlue = Color(red: 0.4, green: 0.6, blue: 1.0)
}
