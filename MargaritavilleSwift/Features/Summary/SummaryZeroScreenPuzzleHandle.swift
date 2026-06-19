import SwiftUI

struct SummaryZeroScreenPuzzleHandle: View {
    @Environment(\.interactionFeedback) private var feedback

    @Binding var progress: CGFloat
    let onComplete: () -> Void

    @State private var drag: CGFloat = 0
    @State private var armed = false
    @State private var committed = false
    @State private var feedbackStarted = false

    var body: some View {
        GeometryReader { proxy in
            let metrics = ZeroScreenPuzzleTrackMetrics(width: proxy.size.width, height: proxy.size.height)
            let normalized = metrics.progress(for: drag)

            ZStack {
                if normalized > 0.001 {
                    PuzzleSocket(progress: normalized)
                        .frame(width: metrics.pieceSize, height: metrics.pieceSize)
                        .position(x: metrics.targetCenterX, y: metrics.centerY)
                        .transition(.opacity)
                }

                PuzzlePiece(progress: normalized, systemName: "puzzlepiece.extension.fill")
                    .frame(width: metrics.pieceSize, height: metrics.pieceSize)
                    .position(x: metrics.pieceCenterX(progress: normalized), y: metrics.centerY)
                    .opacity(min(normalized * 1.35, 1))

                Color.clear
                    .frame(width: metrics.startZoneWidth + 18, height: metrics.height)
                    .contentShape(Rectangle())
                    .position(x: metrics.startZoneCenterX, y: metrics.centerY)
                    .gesture(dragGesture(metrics: metrics))
            }
        }
        .accessibilityLabel("Вернуться к выбору контейнеров")
    }

    private func dragGesture(metrics: ZeroScreenPuzzleTrackMetrics) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard !committed else { return }
                let next = min(max(value.translation.width, 0), metrics.travel * 1.08)
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

private struct ZeroScreenPuzzleTrackMetrics {
    let width: CGFloat
    let height: CGFloat

    let horizontalPadding: CGFloat = 18
    let settingsButtonSize: CGFloat = 48
    let startZoneWidth: CGFloat = 86
    let pieceSize: CGFloat = 42

    var centerY: CGFloat { height * 0.5 }
    var startZoneCenterX: CGFloat { horizontalPadding + settingsButtonSize * 0.5 }
    var startCenterX: CGFloat { startZoneCenterX }
    var targetCenterX: CGFloat { width - horizontalPadding - startZoneWidth * 0.5 }
    var travel: CGFloat { max(targetCenterX - startCenterX, 1) }

    func progress(for drag: CGFloat) -> CGFloat {
        min(max(drag / travel, 0), 1)
    }

    func pieceCenterX(progress: CGFloat) -> CGFloat {
        startCenterX + (targetCenterX - startCenterX) * min(max(progress, 0), 1)
    }
}
