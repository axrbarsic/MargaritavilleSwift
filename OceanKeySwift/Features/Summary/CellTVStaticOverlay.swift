import SwiftUI

struct CellTVStaticOverlay: View {
    let statusColor: Color
    let roomID: String

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 36.0)) { timeline in
            let frame = UInt64(timeline.date.timeIntervalSinceReferenceDate * 36)
            let seed = CellTVStaticNoise.seed(roomID: roomID, frame: frame)
            Canvas(opaque: false, rendersAsynchronously: true) { context, size in
                CellTVStaticNoise.draw(
                    in: &context,
                    size: size,
                    statusColor: statusColor,
                    seed: seed
                )
            }
            .blendMode(.plusLighter)
            .opacity(0.52)
            .overlay {
                scanlines
                    .blendMode(.multiply)
                    .opacity(0.26)
            }
        }
    }

    private var scanlines: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0.36), location: 0.00),
                .init(color: .clear, location: 0.30),
                .init(color: .clear, location: 0.70),
                .init(color: .black.opacity(0.28), location: 1.00)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private enum CellTVStaticNoise {
    static func seed(roomID: String, frame: UInt64) -> UInt64 {
        var hash: UInt64 = 1469598103934665603
        for byte in roomID.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return hash ^ (frame &* 0x9E3779B97F4A7C15)
    }

    static func draw(in context: inout GraphicsContext, size: CGSize, statusColor: Color, seed: UInt64) {
        guard size.width > 0, size.height > 0 else { return }

        var generator = SeededNoise(seed: seed)
        let pixel = max(2.0, min(4.0, size.height / 22.0))
        let columns = max(1, Int(size.width / pixel))
        let rows = max(1, Int(size.height / pixel))

        for row in 0..<rows {
            let rowY = CGFloat(row) * pixel
            let rowFlicker = 0.32 + generator.nextUnit() * 0.64
            for column in stride(from: 0, to: columns, by: 2) {
                let spark = generator.nextUnit()
                guard spark > 0.28 else { continue }

                let widthMultiplier = spark > 0.93 ? 2.6 : 1.15
                let alpha = (0.12 + spark * 0.38) * rowFlicker
                let rect = CGRect(
                    x: CGFloat(column) * pixel,
                    y: rowY,
                    width: pixel * widthMultiplier,
                    height: pixel * (spark > 0.88 ? 1.45 : 0.92)
                )
                context.fill(Path(rect), with: .color(statusColor.opacity(alpha)))
            }
        }

        for _ in 0..<8 {
            let y = generator.nextUnit() * size.height
            let height = 1.0 + generator.nextUnit() * 2.5
            let alpha = 0.08 + generator.nextUnit() * 0.16
            let rect = CGRect(x: 0, y: y, width: size.width, height: height)
            context.fill(Path(rect), with: .color(Color.white.opacity(alpha)))
        }

        if generator.nextUnit() > 0.62 {
            let x = generator.nextUnit() * size.width
            let width = 10 + generator.nextUnit() * 42
            let rect = CGRect(x: x, y: 0, width: width, height: size.height)
            context.fill(Path(rect), with: .color(statusColor.opacity(0.12)))
        }
    }
}

private struct SeededNoise {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0xD1B54A32D192ED03 : seed
    }

    mutating func nextUnit() -> CGFloat {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        z ^= z >> 31
        return CGFloat(Double(z & 0xFFFF) / Double(0xFFFF))
    }
}
