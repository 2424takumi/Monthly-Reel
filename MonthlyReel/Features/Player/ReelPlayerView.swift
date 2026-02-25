import SwiftUI
import AVKit

/// Full-screen video player with looping playback, overlay controls,
/// and a bottom bar for preset selection, saving, and sharing.
struct ReelPlayerView: View {
    let videoURL: URL
    let month: YearMonth

    @Environment(PlayerViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            videoPlayerLayer

            if viewModel.isOverlayVisible {
                overlayControls
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isOverlayVisible)
        .onTapGesture { viewModel.toggleOverlay() }
        .onAppear { viewModel.loadVideo(url: videoURL) }
        .onDisappear { viewModel.cleanup() }
        .sheet(isPresented: $showShareSheet) {
            if let player = viewModel.player,
               let item = player.currentItem,
               let asset = item.asset as? AVURLAsset {
                ShareSheet(activityItems: [asset.url])
            }
        }
        .statusBarHidden(true)
    }
}

// MARK: - Video Player Layer

private extension ReelPlayerView {
    var videoPlayerLayer: some View {
        LoopingPlayerView(player: viewModel.player)
            .ignoresSafeArea()
    }
}

// MARK: - Overlay Controls

private extension ReelPlayerView {
    var overlayControls: some View {
        ZStack {
            // Top gradient
            VStack {
                LinearGradient(
                    colors: [.black.opacity(0.7), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 140)

                Spacer()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
            }
            .ignoresSafeArea()

            VStack {
                topBar
                Spacer()
                bottomBar
            }
        }
        .allowsHitTesting(true)
    }

    var topBar: some View {
        HStack {
            Text(month.displayString)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    var bottomBar: some View {
        VStack(spacing: 16) {
            presetPicker
            actionButtons
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }
}

// MARK: - Preset Picker

private extension ReelPlayerView {
    var presetPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ColorPreset.allCases, id: \.self) { preset in
                    presetChip(preset)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    func presetChip(_ preset: ColorPreset) -> some View {
        let isSelected = viewModel.currentPreset == preset
        return Button {
            Task { await viewModel.changePreset(preset) }
        } label: {
            Text(preset.displayName)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentBlue : Color.white.opacity(0.15))
                .clipShape(Capsule())
        }
        .disabled(viewModel.isApplyingPreset)
    }
}

// MARK: - Action Buttons

private extension ReelPlayerView {
    var actionButtons: some View {
        HStack(spacing: 16) {
            saveButton
            shareButton
        }
    }

    var saveButton: some View {
        Button {
            Task { await viewModel.saveToPhotoLibrary() }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 15, weight: .semibold))
                }
                Text("保存")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.accentBlue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(viewModel.isSaving)
    }

    var shareButton: some View {
        Button {
            showShareSheet = true
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
