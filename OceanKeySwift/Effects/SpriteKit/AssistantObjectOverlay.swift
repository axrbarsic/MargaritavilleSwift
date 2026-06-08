import SpriteKit
import SwiftUI

struct AssistantObjectOverlay: UIViewRepresentable {
    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.allowsTransparency = true
        view.backgroundColor = .clear
        view.isOpaque = false
        view.isUserInteractionEnabled = false
        view.preferredFramesPerSecond = 120

        let scene = AssistantObjectScene(size: .zero)
        scene.scaleMode = SKSceneScaleMode.resizeFill
        view.presentScene(scene)
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        view.preferredFramesPerSecond = 120
    }
}

private final class AssistantObjectScene: SKScene {
    private let sprite = SKShapeNode(circleOfRadius: 9)
    private var nextImpulseAt: TimeInterval = 0

    override init(size: CGSize) {
        super.init(size: size)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(origin: .zero, size: size))
        physicsBody?.friction = 0
        physicsBody?.restitution = 0.92
        if sprite.parent != nil, oldSize == .zero, size.width > 1, size.height > 1 {
            sprite.position = CGPoint(x: size.width * 0.18, y: size.height * 0.72)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard size.width > 1, size.height > 1 else { return }
        if currentTime >= nextImpulseAt {
            nextImpulseAt = currentTime + Double.random(in: 1.2...2.8)
            sprite.physicsBody?.applyImpulse(
                CGVector(
                    dx: CGFloat.random(in: -4.5...4.5),
                    dy: CGFloat.random(in: -2.8...5.8)
                )
            )
        }

        if let velocity = sprite.physicsBody?.velocity {
            sprite.zRotation = atan2(velocity.dy, velocity.dx)
        }
    }

    private func setup() {
        backgroundColor = .clear
        guard sprite.parent == nil else { return }
        physicsWorld.gravity = CGVector(dx: 0, dy: -0.08)
        physicsWorld.speed = 0.86

        sprite.fillColor = UIColor(red: 0.05, green: 1, blue: 0.42, alpha: 0.68)
        sprite.strokeColor = UIColor.white.withAlphaComponent(0.82)
        sprite.lineWidth = 1.5
        sprite.glowWidth = 8
        sprite.physicsBody = SKPhysicsBody(circleOfRadius: 9)
        sprite.physicsBody?.allowsRotation = true
        sprite.physicsBody?.linearDamping = 0.18
        sprite.physicsBody?.angularDamping = 0.24
        sprite.physicsBody?.friction = 0.02
        sprite.physicsBody?.restitution = 0.88
        sprite.physicsBody?.mass = 0.018
        addChild(sprite)

        let tail = SKShapeNode(rectOf: CGSize(width: 26, height: 3), cornerRadius: 2)
        tail.fillColor = UIColor(red: 0.0, green: 1, blue: 0.38, alpha: 0.38)
        tail.strokeColor = .clear
        tail.position = CGPoint(x: -16, y: 0)
        sprite.addChild(tail)
    }
}
