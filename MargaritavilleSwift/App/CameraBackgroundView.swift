import Metal
import QuartzCore
import SwiftUI
import UIKit

/// Фон «Камера»: кадры задней камеры с выбранным эффектом рисуются Metal
/// прямо в слой этого вида. Камера работает только пока экран верхний и
/// приложение активно; неактивный экран замирает на последнем кадре.
struct CameraBackgroundView: UIViewRepresentable {
    var isActive = true
    var effect: CameraBackgroundEffect = .normal
    var position: CameraBackgroundPosition = .back
    var tuning: CameraEffectTuning = .default
    @Environment(\.scenePhase) private var scenePhase

    func makeUIView(context: Context) -> CameraMetalView {
        let view = CameraMetalView()
        update(view)
        return view
    }

    func updateUIView(_ view: CameraMetalView, context: Context) {
        update(view)
    }

    static func dismantleUIView(_ view: CameraMetalView, coordinator: ()) {
        view.setLive(false)
    }

    private func update(_ view: CameraMetalView) {
        view.renderTarget.effect = effect
        view.renderTarget.tuning = tuning
        CameraBackgroundSession.shared.setPosition(position)
        view.setLive(isActive && scenePhase == .active)
    }
}

final class CameraMetalView: UIView {
    /// 2× хватает для кадра 1080p и экономит заполнение пикселей на 3× экранах.
    private static let renderScale = min(UIScreen.main.scale, 2)

    override class var layerClass: AnyClass { CAMetalLayer.self }

    private var metalLayer: CAMetalLayer {
        layer as! CAMetalLayer
    }

    private(set) lazy var renderTarget = CameraRenderTarget(layer: metalLayer)
    private var isLive = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        isOpaque = true
        isUserInteractionEnabled = false
        metalLayer.device = MTLCreateSystemDefaultDevice()
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.contentsScale = Self.renderScale
        metalLayer.isOpaque = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        metalLayer.drawableSize = CGSize(
            width: max(1, bounds.width * Self.renderScale),
            height: max(1, bounds.height * Self.renderScale)
        )
    }

    func setLive(_ live: Bool) {
        guard live != isLive else { return }
        isLive = live
        if live {
            CameraBackgroundSession.shared.attach(renderTarget)
        } else {
            CameraBackgroundSession.shared.detach(renderTarget)
        }
    }
}
