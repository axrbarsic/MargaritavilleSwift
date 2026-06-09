import CoreImage
import SwiftUI
import UIKit

struct TVStaticNoiseBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> TVStaticNoiseRenderView {
        let view = TVStaticNoiseRenderView()
        view.start()
        return view
    }

    func updateUIView(_ view: TVStaticNoiseRenderView, context: Context) {
        view.start()
    }

    static func dismantleUIView(_ view: TVStaticNoiseRenderView, coordinator: ()) {
        view.stop()
    }
}

final class TVStaticNoiseRenderView: UIView {
    private let imageView = UIImageView()
    private let scanlineView = TVStaticScanlineView()
    private let context = CIContext(options: [.cacheIntermediates: false])
    private let randomFilter = CIFilter(name: "CIRandomGenerator")
    private var displayLink: CADisplayLink?
    private var frameIndex = 0
    private var renderSize = CGSize(width: 180, height: 320)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        isUserInteractionEnabled = false

        imageView.contentMode = .scaleAspectFill
        imageView.layer.magnificationFilter = .nearest
        imageView.layer.minificationFilter = .nearest
        imageView.isOpaque = true
        imageView.backgroundColor = .black

        addSubview(imageView)
        addSubview(scanlineView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        scanlineView.frame = bounds
        updateRenderSize()
    }

    func start() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(renderFrame))
        link.preferredFrameRateRange = CAFrameRateRange(
            minimum: 60,
            maximum: Float(UIScreen.main.maximumFramesPerSecond),
            preferred: Float(UIScreen.main.maximumFramesPerSecond)
        )
        link.add(to: .main, forMode: .common)
        displayLink = link
        renderFrame()
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func renderFrame() {
        frameIndex &+= 1
        guard bounds.width > 0, bounds.height > 0 else { return }
        guard let image = makeNoiseImage() else { return }
        imageView.image = image
    }

    private func updateRenderSize() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let aspect = bounds.height / max(bounds.width, 1)
        let width: CGFloat = 180
        renderSize = CGSize(width: width, height: max(240, width * aspect))
    }

    private func makeNoiseImage() -> UIImage? {
        guard let source = randomFilter?.outputImage else { return nil }

        let jitterX = CGFloat((frameIndex * 37) % 8192)
        let jitterY = CGFloat((frameIndex * 91) % 8192)
        let cropped = source
            .transformed(by: CGAffineTransform(translationX: jitterX, y: jitterY))
            .cropped(to: CGRect(origin: .zero, size: renderSize))
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputContrastKey: 1.9,
                kCIInputBrightnessKey: -0.08
            ])
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 1, y: 0, z: 0, w: 0),
                "inputBVector": CIVector(x: 1, y: 0, z: 0, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
            ])

        guard let cgImage = context.createCGImage(cropped, from: CGRect(origin: .zero, size: renderSize)) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
    }
}

private final class TVStaticScanlineView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        isUserInteractionEnabled = false
        backgroundColor = .clear
        contentMode = .redraw
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(UIColor.black.withAlphaComponent(0.18).cgColor)
        var y: CGFloat = 0
        while y < rect.height {
            context.fill(CGRect(x: 0, y: y, width: rect.width, height: 1))
            y += 4
        }
    }
}
