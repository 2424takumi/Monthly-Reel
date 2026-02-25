import SwiftUI

/// First-launch onboarding with three swipeable pages:
/// introduction, how-it-works, and photo library permission.
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let pageCount = 3

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    introPage.tag(0)
                    howItWorksPage.tag(1)
                    permissionPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                pageIndicator
                    .padding(.bottom, 16)

                bottomButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
        .statusBarHidden(true)
    }
}

// MARK: - Page 1: Intro

private extension OnboardingView {
    var introPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "film.stack")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentBlue, Color.accentBlue.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Monthly Reel")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("撮るだけ。月の記録が動画になる。")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Page 2: How It Works

private extension OnboardingView {
    var howItWorksPage: some View {
        VStack(spacing: 40) {
            Spacer()

            Text("使い方")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 28) {
                featureRow(
                    icon: "video.fill",
                    title: "自動スキャン",
                    description: "カメラロールから今月の動画を自動で見つけます"
                )
                featureRow(
                    icon: "sparkles",
                    title: "ベストシーン選択",
                    description: "AIがベストシーンを自動でピックアップします"
                )
                featureRow(
                    icon: "paintbrush.fill",
                    title: "カラーグレーディング",
                    description: "5種類のプリセットで映画のような仕上がりに"
                )
            }
            .padding(.horizontal, 8)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(Color.accentBlue)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineSpacing(2)
            }
        }
    }
}

// MARK: - Page 3: Permission

private extension OnboardingView {
    var permissionPage: some View {
        PermissionsView {
            // Permission granted callback — no immediate action needed,
            // user will tap "はじめる" to proceed.
        }
    }
}

// MARK: - Page Indicator

private extension OnboardingView {
    var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.accentBlue : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }
}

// MARK: - Bottom Button

private extension OnboardingView {
    var bottomButton: some View {
        Button {
            handleButtonTap()
        } label: {
            Text(buttonTitle)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.accentBlue)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    var buttonTitle: String {
        currentPage == pageCount - 1 ? "はじめる" : "次へ"
    }

    func handleButtonTap() {
        if currentPage < pageCount - 1 {
            currentPage += 1
        } else {
            completeOnboarding()
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        dismiss()
    }
}
