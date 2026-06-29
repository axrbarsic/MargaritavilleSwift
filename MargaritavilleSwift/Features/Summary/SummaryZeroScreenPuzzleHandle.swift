import SwiftUI

struct SummaryZeroScreenPuzzleHandle: View {
    @Binding var progress: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let metrics = ZeroScreenPuzzleTrackMetrics(width: proxy.size.width, height: proxy.size.height)
            let normalized = min(max(progress, 0), 1)

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
                    .position(x: metrics.startZoneCenterX, y: metrics.centerY)
            }
        }
        .accessibilityLabel("Вернуться к выбору контейнеров")
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
