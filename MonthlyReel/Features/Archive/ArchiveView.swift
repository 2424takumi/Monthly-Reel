import SwiftUI

/// Grid display of all previously generated monthly reels.
/// Supports tap to play and long-press to delete.
struct ArchiveView: View {
    @Environment(ArchiveViewModel.self) private var viewModel
    @State private var selectedReel: MonthlyReelModel?
    @State private var reelToDelete: MonthlyReelModel?
    @State private var showDeleteAlert = false

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if viewModel.reels.isEmpty {
                    emptyState
                } else {
                    reelGrid
                }
            }
            .navigationTitle("アーカイブ")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear { viewModel.loadReels() }
        .fullScreenCover(item: $selectedReel) { reel in
            ReelPlayerView(
                videoURL: reel.videoURL,
                month: YearMonth(year: reel.year, month: reel.month)
            )
        }
        .alert("このリールを削除しますか？", isPresented: $showDeleteAlert) {
            Button("削除", role: .destructive) {
                if let reel = reelToDelete {
                    viewModel.deleteReel(reel)
                    reelToDelete = nil
                }
            }
            Button("キャンセル", role: .cancel) {
                reelToDelete = nil
            }
        } message: {
            Text("この操作は取り消せません。")
        }
    }
}

// MARK: - Empty State

private extension ArchiveView {
    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))

            Text("まだリールがありません")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

// MARK: - Reel Grid

private extension ArchiveView {
    var reelGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.reels) { reel in
                    archiveCell(reel)
                }
            }
            .padding(.top, 2)
        }
    }

    func archiveCell(_ reel: MonthlyReelModel) -> some View {
        ZStack(alignment: .bottomLeading) {
            thumbnailImage(reel.thumbnailData)

            monthLabel(year: reel.year, month: reel.month)
        }
        .aspectRatio(9.0 / 16.0, contentMode: .fit)
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture { selectedReel = reel }
        .onLongPressGesture {
            reelToDelete = reel
            showDeleteAlert = true
        }
    }
}

// MARK: - Cell Subviews

private extension ArchiveView {
    func thumbnailImage(_ data: Data) -> some View {
        Group {
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
            }
        }
    }

    func monthLabel(year: Int, month: Int) -> some View {
        Text(YearMonth(year: year, month: month).displayString)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 1)
            .padding(.leading, 8)
            .padding(.bottom, 8)
    }
}
