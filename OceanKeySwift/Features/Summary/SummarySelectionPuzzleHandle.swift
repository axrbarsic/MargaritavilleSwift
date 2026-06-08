import SwiftUI
import UIKit

struct SummarySelectionPuzzleHandle: View {
    @Environment(\.interactionFeedback) private var feedback

    let onComplete: () -> Void

    @State private var drag: CGFloat = 0
    @State private var armed = false
    @State private var committed = false
    @State private var feedbackStarted = false

    private var threshold: CGFloat {
        max(280, UIScreen.main.bounds.width - 94)
    }

    var body: some View {
        let progress = min(max(drag / threshold, 0), 1)

        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.black.opacity(0.10 + 0.06 * progress))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            OceanKeyTheme.accent.opacity(0.12 + 0.24 * progress),
                            lineWidth: 1
                        )
                }

            PuzzleSocket(progress: progress)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 8)

            PuzzlePiece(progress: progress, systemName: "puzzlepiece.fill")
            .offset(x: -threshold * progress)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 6)
        }
        .frame(width: 86, height: 42)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityLabel("Открыть выбор комнат")
        .gesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard !committed else { return }
                let next = min(max(-value.translation.width, 0), threshold * 1.15)
                guard next > 0 || drag > 0 else { return }
                if next > 2, !feedbackStarted {
                    feedbackStarted = true
                    feedback.holdStart()
                }
                let nextArmed = next >= threshold
                if nextArmed, !armed {
                    feedback.holdCommit()
                } else if !nextArmed, next > threshold * 0.82, drag <= threshold * 0.82 {
                    feedback.holdWarning()
                }
                drag = next
                armed = nextArmed
            }
            .onEnded { _ in
                guard !committed else { return }
                guard armed else {
                    reset()
                    return
                }
                committed = true
                drag = threshold
                feedback.confirm()
                onComplete()
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(160))
                    reset()
                    committed = false
                }
            }
    }

    private func reset() {
        drag = 0
        armed = false
        feedbackStarted = false
    }
}

struct PuzzleSocket: View {
    let progress: CGFloat

    var body: some View {
        Image(systemName: "puzzlepiece.extension.fill")
            .font(.system(size: 20, weight: .black))
            .frame(width: 34, height: 34)
            .foregroundStyle(.black.opacity(0.32 + 0.22 * progress))
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.black.opacity(0.18 + 0.28 * progress))
                    .shadow(color: .white.opacity(0.10), radius: 1, x: -1, y: -1)
                    .shadow(color: .black.opacity(0.42), radius: 5, x: 2, y: 3)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(OceanKeyTheme.accent.opacity(0.12 + 0.28 * progress), lineWidth: 1)
            }
    }
}

struct PuzzlePiece: View {
    let progress: CGFloat
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .black))
            .frame(width: 33, height: 33)
            .foregroundStyle(OceanKeyTheme.accent.opacity(0.48 + 0.48 * progress))
            .background(OceanKeyTheme.accent.opacity(0.08 + 0.16 * progress))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(OceanKeyTheme.accent.opacity(0.22 + 0.34 * progress), lineWidth: 1)
            }
            .shadow(color: OceanKeyTheme.accent.opacity(0.28 * progress), radius: 8)
    }
}

#Preview {
    SummarySelectionPuzzleHandle(onComplete: {})
        .padding()
        .background(OceanKeyTheme.background)
}
