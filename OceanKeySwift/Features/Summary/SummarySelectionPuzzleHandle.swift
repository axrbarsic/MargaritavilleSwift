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
        max(220, UIScreen.main.bounds.width - 166)
    }

    var body: some View {
        let progress = min(max(drag / threshold, 0), 1)
        let eased = cubicEaseOut(progress)

        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(OceanKeyTheme.surface.opacity(0.78))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            OceanKeyTheme.accent.opacity(0.22 + 0.34 * eased),
                            lineWidth: 1
                        )
                }

            PuzzleGlyph(
                systemName: "puzzlepiece.extension.fill",
                accentOpacity: 0.26 + 0.30 * eased,
                fillOpacity: 0.05 + 0.08 * eased
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 8)

            PuzzleGlyph(
                systemName: "puzzlepiece.fill",
                accentOpacity: 0.45 + 0.50 * eased,
                fillOpacity: 0.08 + 0.18 * eased,
                shadowOpacity: 0.22 * eased
            )
            .offset(x: -min(threshold * 0.68, 250) * eased)
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
                } else if !nextArmed, next > threshold * 0.55, drag <= threshold * 0.55 {
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

    private func cubicEaseOut(_ value: CGFloat) -> CGFloat {
        1 - pow(1 - value, 3)
    }
}

private struct PuzzleGlyph: View {
    let systemName: String
    let accentOpacity: Double
    let fillOpacity: Double
    var shadowOpacity: Double = 0

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .black))
            .frame(width: 33, height: 33)
            .foregroundStyle(OceanKeyTheme.accent.opacity(accentOpacity))
            .background(OceanKeyTheme.accent.opacity(fillOpacity))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(OceanKeyTheme.accent.opacity(0.18 + shadowOpacity), lineWidth: 1)
            }
            .shadow(color: OceanKeyTheme.accent.opacity(shadowOpacity), radius: 8)
    }
}

#Preview {
    SummarySelectionPuzzleHandle(onComplete: {})
        .padding()
        .background(OceanKeyTheme.background)
}
