import SwiftUI

/// Circular progress indicator with status text and cancel button.
/// Displayed during the scanning, selecting, compositing, and grading phases.
struct GenerationProgressView: View {
    let progress: Double
    let statusText: String
    let onCancel: () -> Void

    private let circleDiameter: CGFloat = 120
    private let strokeWidth: CGFloat = 6

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            progressCircle

            statusLabel

            Spacer()

            cancelButton
                .padding(.bottom, 48)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Subviews

private extension GenerationProgressView {
    var progressCircle: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: strokeWidth)
                .frame(width: circleDiameter, height: circleDiameter)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.accentBlue,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )
                .frame(width: circleDiameter, height: circleDiameter)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)

            Text("\(Int(progress * 100))%")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    var statusLabel: some View {
        Text(statusText)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.7))
    }

    var cancelButton: some View {
        Button {
            onCancel()
        } label: {
            Text("キャンセル")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
    }
}
