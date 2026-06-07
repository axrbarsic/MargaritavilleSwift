import GameplayKit
import SpriteKit

final class MatrixRainSpriteScene: SKScene, ResizableSpriteScene {
    private let glyphs = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789木火水金月日")
    private var columns: [RainColumn] = []
    private var lastGlyphTick = -1
    private var random = GKLinearCongruentialRandomSource(seed: UInt64(Date().timeIntervalSinceReferenceDate))
    private var configuration: MatrixRainConfiguration

    init(size: CGSize, configuration: MatrixRainConfiguration = .default) {
        self.configuration = configuration
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .black
    }

    override init(size: CGSize) {
        self.configuration = .default
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        self.configuration = .default
        super.init(coder: coder)
        scaleMode = .resizeFill
        backgroundColor = .black
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        resize(to: size)
    }

    func resize(to size: CGSize) {
        removeAllChildren()
        columns.removeAll(keepingCapacity: true)

        guard size.width > 0, size.height > 0 else { return }

        let columnWidth: CGFloat = 24
        let rowHeight: CGFloat = 30
        let columnCount = max(14, Int(size.width / columnWidth))
        let rowCount = max(24, Int(size.height / rowHeight) + 5)

        for index in 0..<columnCount {
            let x = (CGFloat(index) + 0.5) * size.width / CGFloat(columnCount)
            let speed = CGFloat.random(in: 70...145, using: &random)
            let phase = CGFloat.random(in: 0...size.height, using: &random)
            let column = RainColumn(x: x, speed: speed, phase: phase)

            for row in 0..<rowCount {
                let label = SKLabelNode(fontNamed: "Menlo-Bold")
                label.fontSize = 19
                label.verticalAlignmentMode = .center
                label.horizontalAlignmentMode = .center
                label.text = randomGlyph()
                label.position = CGPoint(x: x, y: CGFloat(row) * rowHeight)
                label.blendMode = .add
                addChild(label)
                column.labels.append(label)
            }

            columns.append(column)
        }

        let veil = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        veil.fillColor = UIColor.black.withAlphaComponent(0.32)
        veil.strokeColor = .clear
        veil.zPosition = 10
        addChild(veil)
    }

    func apply(configuration: MatrixRainConfiguration) {
        guard self.configuration != configuration else { return }
        self.configuration = configuration
    }

    override func update(_ currentTime: TimeInterval) {
        let glyphTick = Int(currentTime * 7)
        let shouldUpdateGlyphs = glyphTick != lastGlyphTick
        if shouldUpdateGlyphs {
            lastGlyphTick = glyphTick
        }

        for column in columns {
            for (row, label) in column.labels.enumerated() {
                let trail = CGFloat(row) * 30
                let rawY = size.height - ((CGFloat(currentTime) * column.speed + column.phase + trail)
                    .truncatingRemainder(dividingBy: size.height + 180))
                label.position.y = rawY + 90

                let normalizedTrail = CGFloat(row) / CGFloat(max(column.labels.count - 1, 1))
                let alpha = max(0.04, 0.72 - normalizedTrail * 0.72)
                let richness = configuration.normalizedColorRichness
                let green = min(1.0, 0.58 + richness * 0.26)
                let blue = min(0.68, 0.18 + richness * 0.10)
                let adjustedAlpha = min(0.96, alpha * (0.72 + richness * 0.32))
                label.fontColor = row == 0
                    ? UIColor(
                        red: min(1.0, 0.64 + richness * 0.18),
                        green: 1.0,
                        blue: min(1.0, 0.68 + richness * 0.14),
                        alpha: min(0.98, 0.70 + richness * 0.12)
                    )
                    : UIColor(red: 0.0, green: green, blue: blue, alpha: adjustedAlpha)

                if shouldUpdateGlyphs, row % 3 == glyphTick % 3 {
                    label.text = randomGlyph()
                }
            }
        }
    }

    private func randomGlyph() -> String {
        let index = random.nextInt(upperBound: glyphs.count)
        return String(glyphs[index])
    }
}

private final class RainColumn {
    let x: CGFloat
    let speed: CGFloat
    let phase: CGFloat
    var labels: [SKLabelNode] = []

    init(x: CGFloat, speed: CGFloat, phase: CGFloat) {
        self.x = x
        self.speed = speed
        self.phase = phase
    }
}

private extension CGFloat {
    static func random(in range: ClosedRange<CGFloat>, using source: inout GKLinearCongruentialRandomSource) -> CGFloat {
        let value = CGFloat(source.nextUniform())
        return range.lowerBound + (range.upperBound - range.lowerBound) * value
    }
}
