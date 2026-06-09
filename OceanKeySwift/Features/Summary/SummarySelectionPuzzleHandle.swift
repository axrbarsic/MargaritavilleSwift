import SwiftUI
import UIKit

struct SummarySelectionPuzzleHandle: View {
    @Environment(\.interactionFeedback) private var feedback

    @Binding var progress: CGFloat
    let onComplete: () -> Void

    @State private var drag: CGFloat = 0
    @State private var armed = false
    @State private var committed = false
    @State private var feedbackStarted = false

    var body: some View {
        GeometryReader { proxy in
            let metrics = PuzzleTrackMetrics(width: proxy.size.width, height: proxy.size.height)
            let normalized = metrics.progress(for: drag)

            ZStack {
                if normalized > 0.001 {
                    PuzzleSocket(progress: normalized)
                        .frame(width: metrics.pieceSize, height: metrics.pieceSize)
                        .position(x: metrics.targetCenterX, y: metrics.centerY)
                        .transition(.opacity)
                }

                PuzzlePiece(progress: normalized, systemName: "puzzlepiece.fill")
                    .frame(width: metrics.pieceSize, height: metrics.pieceSize)
                    .position(x: metrics.pieceCenterX(progress: normalized), y: metrics.centerY)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.black.opacity(0.08 + 0.07 * normalized))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                OceanKeyTheme.accent.opacity(0.12 + 0.26 * normalized),
                                lineWidth: 1
                            )
                    }
                    .frame(width: metrics.startZoneWidth, height: 42)
                    .position(x: metrics.startZoneCenterX, y: metrics.centerY)
                    .opacity(1 - min(normalized * 1.15, 0.82))

                Color.clear
                    .frame(width: metrics.startZoneWidth + 18, height: metrics.height)
                    .contentShape(Rectangle())
                    .position(x: metrics.startZoneCenterX, y: metrics.centerY)
                    .gesture(dragGesture(metrics: metrics))
            }
        }
        .accessibilityLabel("Открыть выбор комнат")
    }

    private func dragGesture(metrics: PuzzleTrackMetrics) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard !committed else { return }
                let next = min(max(-value.translation.width, 0), metrics.travel * 1.08)
                guard next > 0 || drag > 0 else { return }
                if next > 2, !feedbackStarted {
                    feedbackStarted = true
                    feedback.holdStart()
                }
                let nextArmed = next >= metrics.travel
                if nextArmed, !armed {
                    feedback.holdCommit()
                } else if !nextArmed, next > metrics.travel * 0.82, drag <= metrics.travel * 0.82 {
                    feedback.holdWarning()
                }
                drag = next
                progress = metrics.progress(for: next)
                armed = nextArmed
            }
            .onEnded { _ in
                guard !committed else { return }
                guard armed else {
                    reset()
                    return
                }
                committed = true
                drag = metrics.travel
                progress = 1
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
        progress = 0
        armed = false
        feedbackStarted = false
    }
}

private struct PuzzleTrackMetrics {
    let width: CGFloat
    let height: CGFloat

    let horizontalPadding: CGFloat = 18
    let settingsButtonSize: CGFloat = 48
    let startZoneWidth: CGFloat = 86
    let pieceSize: CGFloat = 42

    var centerY: CGFloat { height * 0.5 }
    var targetCenterX: CGFloat { horizontalPadding + settingsButtonSize * 0.5 }
    var startZoneCenterX: CGFloat { width - horizontalPadding - startZoneWidth * 0.5 }
    var startCenterX: CGFloat { startZoneCenterX }
    var travel: CGFloat { max(startCenterX - targetCenterX, 1) }

    func progress(for drag: CGFloat) -> CGFloat {
        min(max(drag / travel, 0), 1)
    }

    func pieceCenterX(progress: CGFloat) -> CGFloat {
        startCenterX + (targetCenterX - startCenterX) * min(max(progress, 0), 1)
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
    SummarySelectionPuzzleHandle(progress: .constant(0), onComplete: {})
        .padding()
        .background(OceanKeyTheme.background)
}
