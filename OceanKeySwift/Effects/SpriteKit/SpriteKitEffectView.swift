import SpriteKit
import SwiftUI

enum SpriteKitEffectKind {
    case matrixRain
    case tvStaticNoise
}

@MainActor
struct SpriteKitEffectView: UIViewRepresentable {
    @Environment(\.matrixRainConfiguration) private var environmentMatrixConfiguration

    let effect: SpriteKitEffectKind
    let matrixConfiguration: MatrixRainConfiguration?

    init(
        _ effect: SpriteKitEffectKind,
        matrixConfiguration: MatrixRainConfiguration? = nil
    ) {
        self.effect = effect
        self.matrixConfiguration = matrixConfiguration
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(effect: effect, matrixConfiguration: effectiveMatrixConfiguration)
    }

    func makeUIView(context: Context) -> EffectSKView {
        let view = EffectSKView()
        view.backgroundColor = .clear
        view.allowsTransparency = true
        view.isAsynchronous = true
        view.isUserInteractionEnabled = false
        view.ignoresSiblingOrder = true
        view.shouldCullNonVisibleNodes = true
        view.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
        view.presentScene(context.coordinator.scene)
        return view
    }

    func updateUIView(_ view: EffectSKView, context: Context) {
        context.coordinator.update(matrixConfiguration: effectiveMatrixConfiguration)
        view.resizeScene()
    }

    private var effectiveMatrixConfiguration: MatrixRainConfiguration {
        matrixConfiguration ?? environmentMatrixConfiguration
    }

    @MainActor
    final class Coordinator {
        let scene: SKScene

        init(effect: SpriteKitEffectKind, matrixConfiguration: MatrixRainConfiguration) {
            switch effect {
            case .matrixRain:
                scene = MatrixRainSpriteScene(size: .zero, configuration: matrixConfiguration)
            case .tvStaticNoise:
                scene = TVStaticNoiseSpriteScene(size: .zero)
            }
        }

        func update(matrixConfiguration: MatrixRainConfiguration) {
            (scene as? MatrixRainSpriteScene)?.apply(configuration: matrixConfiguration)
        }
    }
}

final class EffectSKView: SKView {
    override func layoutSubviews() {
        super.layoutSubviews()
        resizeScene()
    }

    func resizeScene() {
        guard bounds.size.width > 0, bounds.size.height > 0 else { return }
        guard scene?.size != bounds.size else { return }
        scene?.size = bounds.size
        (scene as? ResizableSpriteScene)?.resize(to: bounds.size)
    }
}

@MainActor
protocol ResizableSpriteScene: AnyObject {
    func resize(to size: CGSize)
}
