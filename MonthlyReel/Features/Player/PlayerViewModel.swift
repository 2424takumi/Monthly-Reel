import AVFoundation
import Photos
import SwiftUI

/// View model for the full-screen reel player.
/// Manages AVPlayer lifecycle, preset switching, and saving to the photo library.
@Observable
@MainActor
final class PlayerViewModel {

    // MARK: - Dependencies

    private let gradingUseCase: GradingUseCase
    private let appState: AppState
    private var loopObserver: NSObjectProtocol?

    // MARK: - Published State

    var currentPreset: ColorPreset
    var isOverlayVisible = true
    var isSaving = false
    var isApplyingPreset = false
    var saveError: AppError?
    var player: AVPlayer?

    // MARK: - Init

    init(gradingUseCase: GradingUseCase, appState: AppState) {
        self.gradingUseCase = gradingUseCase
        self.appState = appState
        self.currentPreset = appState.selectedPreset
    }

    // MARK: - Player Lifecycle

    /// Loads a video URL into the player and starts looping playback.
    func loadVideo(url: URL) {
        let item = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: item)
        self.player = avPlayer

        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak avPlayer] _ in
            avPlayer?.seek(to: .zero)
            avPlayer?.play()
        }

        avPlayer.play()
    }

    /// Cleans up the player and observation when the view disappears.
    func cleanup() {
        player?.pause()
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
            loopObserver = nil
        }
        player = nil
    }

    // MARK: - Overlay

    func toggleOverlay() {
        isOverlayVisible.toggle()
    }

    // MARK: - Preset

    /// Applies a new color preset to the current video.
    func changePreset(_ preset: ColorPreset) async {
        guard preset != currentPreset else { return }
        guard let currentItem = player?.currentItem,
              let asset = currentItem.asset as? AVURLAsset else { return }

        isApplyingPreset = true
        defer { isApplyingPreset = false }

        do {
            let gradedURL = try await gradingUseCase.apply(
                preset: preset,
                to: asset.url
            )
            currentPreset = preset
            appState.selectedPreset = preset
            loadVideo(url: gradedURL)
        } catch {
            saveError = error as? AppError ?? .gradingFailed(underlying: error)
        }
    }

    // MARK: - Save

    /// Saves the currently playing video to the user's photo library.
    func saveToPhotoLibrary() async {
        guard let currentItem = player?.currentItem,
              let asset = currentItem.asset as? AVURLAsset else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited else {
                saveError = .photoLibraryAccessDenied
                return
            }

            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(
                    atFileURL: asset.url
                )
            }
        } catch {
            saveError = .exportFailed(underlying: error)
        }
    }
}
