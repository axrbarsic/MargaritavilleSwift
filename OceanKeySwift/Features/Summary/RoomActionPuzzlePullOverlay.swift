import SwiftUI

struct RoomActionPuzzlePullOverlay: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let sinkSize = min(max(proxy.size.height * 0.52, 34), 48)
            let normalized = min(max(progress, 0), 1)
            let startCenterX = sinkSize * 0.5 + 14
            let targetCenterX = width - sinkSize * 0.5 - 16
            let pieceCenterX = startCenterX + (targetCenterX - startCenterX) * normalized

            ZStack(alignment: .leading) {
                LinearGradient(
                    colors: [
                        .white.opacity(0.02),
                        OceanKeyTheme.accent.opacity(0.08 + normalized * 0.15),
                        .white.opacity(0.04 + normalized * 0.16)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .blendMode(.screen)

                PuzzleSocket(progress: normalized)
                    .frame(width: sinkSize, height: sinkSize)
                    .position(x: targetCenterX, y: proxy.size.height * 0.5)

                PuzzlePiece(progress: normalized, systemName: "puzzlepiece.fill")
                    .frame(width: sinkSize, height: sinkSize)
                    .position(x: pieceCenterX, y: proxy.size.height * 0.5)
            }
        }
    }
}
