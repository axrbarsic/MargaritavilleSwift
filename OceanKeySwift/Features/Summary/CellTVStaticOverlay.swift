import CoreImage
import SwiftUI
import UIKit

struct CellTVStaticOverlay: UIViewRepresentable {
    let statusColor: Color
    let roomID: String

    func makeUIView(context: Context) -> CellTVStaticRenderView {
        let view = CellTVStaticRenderView()
        view.configure(statusColor: UIColor(statusColor), seedOffset: Self.seed(roomID: roomID))
        view.start()
        return view
    }

    func updateUIView(_ view: CellTVStaticRenderView, context: Context) {
        view.configure(statusColor: UIColor(statusColor), seedOffset: Self.seed(roomID: roomID))
        view.start()
    }

    static func dismantleUIView(_ view: CellTVStaticRenderView, coordinator: ()) {
        view.stop()
    }

    private static func seed(roomID: String) -> Int {
        var hash: UInt64 = 1469598103934665603
        for byte in roomID.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return Int(hash % 4096)
    }
}

final class CellTVStaticRenderView: UIView {
    private let imageView = UIImageView()
    private let scanlineView = CellTVStaticScanlineView()
    private let context = CIContext(options: [.cacheIntermediates: false])
    private let randomFilter = CIFilter(name: "CIRandomGenerator")
    private var displayLink: CADisplayLink?
    private var frameIndex = 0
    private var renderSize = CGSize(width: 220, height: 54)
    private var statusUIColor = UIColor.systemGreen
    private var seedOffset = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false

        imageView.contentMode = .scaleAspectFill
        imageView.layer.magnificationFilter = .nearest
        imageView.layer.minificationFilter = .nearest
        imageView.backgroundColor = .clear
        imageView.isOpaque = false
        imageView.alpha = 0.78

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

    func configure(statusColor: UIColor, seedOffset: Int) {
        self.statusUIColor = statusColor
        self.seedOffset = seedOffset
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
        imageView.image = makeNoiseImage()
    }

    private func updateRenderSize() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let aspect = bounds.height / max(bounds.width, 1)
        let width: CGFloat = 220
        renderSize = CGSize(width: width, height: max(34, width * aspect))
    }

    private func makeNoiseImage() -> UIImage? {
        guard let source = randomFilter?.outputImage else { return nil }

        let jitterX = CGFloat(((frameIndex + seedOffset) * 37) % 8192)
        let jitterY = CGFloat(((frameIndex + seedOffset) * 91) % 8192)
        let components = statusUIColor.normalizedRGBA
        let cropped = source
            .transformed(by: CGAffineTransform(translationX: jitterX, y: jitterY))
            .cropped(to: CGRect(origin: .zero, size: renderSize))
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputContrastKey: 1.95,
                kCIInputBrightnessKey: -0.08
            ])
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: components.red, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: components.green, y: 0, z: 0, w: 0),
                "inputBVector": CIVector(x: components.blue, y: 0, z: 0, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
            ])

        guard let cgImage = context.createCGImage(cropped, from: CGRect(origin: .zero, size: renderSize)) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
    }
}

private final class CellTVStaticScanlineView: UIView {
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
        context.setFillColor(UIColor.black.withAlphaComponent(0.16).cgColor)
        var y: CGFloat = 0
        while y < rect.height {
            context.fill(CGRect(x: 0, y: y, width: rect.width, height: 1))
            y += 4
        }
    }
}

private extension UIColor {
    var normalizedRGBA: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return (0, 1, 0, 1)
        }
        return (red, green, blue, alpha)
    }
}
