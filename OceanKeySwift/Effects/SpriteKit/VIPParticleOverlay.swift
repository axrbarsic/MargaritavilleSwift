import SpriteKit
import SwiftUI

struct VIPParticleOverlay: UIViewRepresentable {
    let targets: [VIPParticleTarget]

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.allowsTransparency = true
        view.backgroundColor = .clear
        view.isOpaque = false
        view.isUserInteractionEnabled = false
        view.preferredFramesPerSecond = 120

        let scene = VIPParticleScene(size: .zero)
        scene.scaleMode = .resizeFill
        view.presentScene(scene)
        context.coordinator.scene = scene
        scene.updateTargets(targets, sceneSize: view.bounds.size)
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        view.preferredFramesPerSecond = 120
        context.coordinator.scene?.updateTargets(targets, sceneSize: view.bounds.size)
    }

    final class Coordinator {
        fileprivate var scene: VIPParticleScene?
    }
}

private final class VIPParticleScene: SKScene {
    private var emitters: [String: SKEmitterNode] = [:]
    private var glowNodes: [String: SKShapeNode] = [:]

    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    func updateTargets(_ targets: [VIPParticleTarget], sceneSize: CGSize) {
        if sceneSize.width > 1, sceneSize.height > 1, size != sceneSize {
            size = sceneSize
        }

        let activeIDs = Set(targets.map(\.id))
        for staleID in emitters.keys where !activeIDs.contains(staleID) {
            emitters[staleID]?.removeFromParent()
            emitters.removeValue(forKey: staleID)
        }
        for staleID in glowNodes.keys where !activeIDs.contains(staleID) {
            glowNodes[staleID]?.removeFromParent()
            glowNodes.removeValue(forKey: staleID)
        }

        for target in targets where target.rect.width > 1 && target.rect.height > 1 {
            let sceneRect = CGRect(
                x: target.rect.minX,
                y: max(size.height - target.rect.maxY, 0),
                width: target.rect.width,
                height: target.rect.height
            )
            let glow = glowNodes[target.id] ?? makeGlowNode()
            if glow.parent == nil {
                addChild(glow)
                glowNodes[target.id] = glow
            }
            glow.path = UIBezierPath(
                roundedRect: sceneRect.insetBy(dx: 4, dy: 4),
                cornerRadius: min(18, sceneRect.height * 0.26)
            ).cgPath
            glow.fillColor = target.tintColor.withAlphaComponent(0.16)
            glow.strokeColor = UIColor.white.withAlphaComponent(0.18)

            let emitter = emitters[target.id] ?? makeEmitter()
            if emitter.parent == nil {
                addChild(emitter)
                emitters[target.id] = emitter
            }

            emitter.position = CGPoint(
                x: target.rect.midX,
                y: max(size.height - target.rect.midY, 0)
            )
            emitter.particlePositionRange = CGVector(
                dx: max(target.rect.width * 0.84, 1),
                dy: max(target.rect.height * 0.56, 1)
            )
            emitter.particleColor = target.tintColor
            emitter.particleColorBlendFactor = 0.92
        }
    }

    private func makeGlowNode() -> SKShapeNode {
        let node = SKShapeNode()
        node.zPosition = 4
        node.lineWidth = 1.0
        node.glowWidth = 18
        node.blendMode = .add
        node.alpha = 0.10
        let up = SKAction.fadeAlpha(to: 0.30, duration: Double.random(in: 0.55...0.90))
        let down = SKAction.fadeAlpha(to: 0.07, duration: Double.random(in: 0.75...1.35))
        up.timingMode = .easeInEaseOut
        down.timingMode = .easeInEaseOut
        node.run(.repeatForever(.sequence([up, down])))
        return node
    }

    private func makeEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.zPosition = 6
        emitter.particleTexture = SKTexture(image: sparkImage())
        emitter.particleBirthRate = 86
        emitter.numParticlesToEmit = 0
        emitter.particleLifetime = 0.92
        emitter.particleLifetimeRange = 0.28
        emitter.particleSpeed = 18
        emitter.particleSpeedRange = 28
        emitter.emissionAngle = .pi * 0.05
        emitter.emissionAngleRange = .pi * 1.35
        emitter.particleAlpha = 0.92
        emitter.particleAlphaRange = 0.14
        emitter.particleAlphaSpeed = -0.76
        emitter.particleScale = 0.22
        emitter.particleScaleRange = 0.18
        emitter.particleScaleSpeed = -0.06
        emitter.particleBlendMode = .add
        return emitter
    }

    private func sparkImage() -> UIImage {
        let size = CGSize(width: 20, height: 20)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let colors = [
                UIColor.white.withAlphaComponent(1.0).cgColor,
                UIColor.white.withAlphaComponent(0.42).cgColor,
                UIColor.white.withAlphaComponent(0.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0, 0.35, 1]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) else { return }
            context.cgContext.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: rect.midX, y: rect.midY),
                startRadius: 0,
                endCenter: CGPoint(x: rect.midX, y: rect.midY),
                endRadius: rect.width * 0.5,
                options: []
            )
        }
    }
}
