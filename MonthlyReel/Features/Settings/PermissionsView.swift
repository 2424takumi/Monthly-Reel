import SwiftUI
import Photos

/// Photo library permission explanation and request view.
/// Used in onboarding and can be embedded in settings.
struct PermissionsView: View {
    @State private var authStatus: PHAuthorizationStatus = .notDetermined
    var onGranted: (() -> Void)?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            iconSection
            explanationSection
            actionSection

            Spacer()
        }
        .padding(.horizontal, 32)
        .background(Color.black)
        .onAppear {
            authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        }
    }
}

// MARK: - Icon

private extension PermissionsView {
    var iconSection: some View {
        Image(systemName: "photo.stack.fill")
            .font(.system(size: 56))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.accentBlue, Color.accentBlue.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

// MARK: - Explanation

private extension PermissionsView {
    var explanationSection: some View {
        VStack(spacing: 12) {
            Text("写真ライブラリへのアクセス")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("動画を読み取り、ベストシーンを自動で選ぶために写真ライブラリへのアクセスが必要です。")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
}

// MARK: - Action

private extension PermissionsView {
    @ViewBuilder
    var actionSection: some View {
        switch authStatus {
        case .notDetermined:
            requestButton

        case .authorized, .limited:
            grantedLabel

        case .denied, .restricted:
            deniedSection

        @unknown default:
            requestButton
        }
    }

    var requestButton: some View {
        Button {
            requestAccess()
        } label: {
            Text("アクセスを許可")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.accentBlue)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    var grantedLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(.green)

            Text("アクセスが許可されています")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    var deniedSection: some View {
        VStack(spacing: 16) {
            Text("写真ライブラリへのアクセスが拒否されています。設定アプリで許可してください。")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)

            Button {
                openSettings()
            } label: {
                Text("設定を開く")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

// MARK: - Actions

private extension PermissionsView {
    func requestAccess() {
        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            await MainActor.run {
                authStatus = status
                if status == .authorized || status == .limited {
                    onGranted?()
                }
            }
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
