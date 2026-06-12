import CoreImage
import SwiftUI
import UIKit

enum TVStaticNoiseVariant: String, CaseIterable, Identifiable, Codable {
    case classicAnalog
    case fineSnow
    case horizontalTear
    case greenTerminal
    case highContrast

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classicAnalog:
            "Analog"
        case .fineSnow:
            "Fine"
        case .horizontalTear:
            "Tear"
        case .greenTerminal:
            "Green"
        case .highContrast:
            "Hard"
        }
    }

    var description: String {
        switch self {
        case .classicAnalog:
            "Классический серый аналоговый снег."
        case .fineSnow:
            "Более мелкое плотное зерно."
        case .horizontalTear:
            "Горизонтальные срывы и полосы."
        case .greenTerminal:
            "Зелёный цифровой шум."
        case .highContrast:
            "Жёсткий контрастный снег."
        }
    }
}

struct TVStaticNoiseConfiguration: Equatable {
    var variant: TVStaticNoiseVariant
    var speed: Double
    var particleSize: Double
    var brightness: Double
    var greenTint: Double

    static let `default` = TVStaticNoiseConfiguration(
        variant: .classicAnalog,
        speed: 1,
        particleSize: 1,
        brightness: -0.08,
        greenTint: 0
    )
}

struct TVStaticNoiseBackgroundView: UIViewRepresentable {
    var configuration: TVStaticNoiseConfiguration = .default

    func makeUIView(context: Context) -> TVStaticNoiseRenderView {
        let view = TVStaticNoiseRenderView()
        view.configure(configuration)
        view.start()
        return view
    }

    func updateUIView(_ view: TVStaticNoiseRenderView, context: Context) {
        view.configure(configuration)
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
    private var framePhase: Double = 0
    private var renderSize = CGSize(width: 180, height: 320)
    private var configuration: TVStaticNoiseConfiguration = .default

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

    func configure(_ configuration: TVStaticNoiseConfiguration) {
        guard self.configuration != configuration else { return }
        self.configuration = configuration
        updateRenderSize()
        renderFrame()
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
        framePhase += max(configuration.speed, 0.05)
        guard bounds.width > 0, bounds.height > 0 else { return }
        guard let image = makeNoiseImage() else { return }
        imageView.image = image
    }

    private func updateRenderSize() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let aspect = bounds.height / max(bounds.width, 1)
        let particleSize = CGFloat(max(configuration.particleSize, 0.5))
        let width = min(420, max(80, 180 * tuning(for: configuration.variant).renderScale / particleSize))
        renderSize = CGSize(width: width, height: max(240, width * aspect))
    }

    private func makeNoiseImage() -> UIImage? {
        guard let source = randomFilter?.outputImage else { return nil }

        let variant = configuration.variant
        let variantTuning = tuning(for: variant)
        let jitterX = CGFloat(Int(framePhase * variantTuning.jitterX) % 8192)
        let jitterY = CGFloat(Int(framePhase * variantTuning.jitterY) % 8192)
        let greenTint = min(max(configuration.greenTint, 0), 1)
        let variantGreenBoost = variant == .greenTerminal ? 0.72 : 0
        let effectiveGreenTint = min(1, greenTint + variantGreenBoost)
        let effectiveBrightness = min(max(configuration.brightness * variantTuning.brightnessScale + variantTuning.brightnessBias, -1), 1)
        let redWeight = max(0, 1 - (0.97 * effectiveGreenTint)) * variantTuning.redScale
        let greenWeight = (1 + (0.55 * effectiveGreenTint)) * variantTuning.greenScale
        let blueWeight = max(0, 1 - (0.92 * effectiveGreenTint)) * variantTuning.blueScale
        var cropped = source
            .transformed(by: CGAffineTransform(translationX: jitterX, y: jitterY))
            .cropped(to: CGRect(origin: .zero, size: renderSize))
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputContrastKey: variantTuning.contrast + 0.45 * effectiveGreenTint,
                kCIInputBrightnessKey: effectiveBrightness
            ])
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: redWeight, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: greenWeight, y: 0, z: 0, w: 0),
                "inputBVector": CIVector(x: blueWeight, y: 0, z: 0, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
            ])

        if variant == .horizontalTear {
            cropped = cropped
                .applyingFilter("CIMotionBlur", parameters: [
                    kCIInputRadiusKey: 5,
                    kCIInputAngleKey: 0
                ])
                .cropped(to: CGRect(origin: .zero, size: renderSize))
        }

        guard let cgImage = context.createCGImage(cropped, from: CGRect(origin: .zero, size: renderSize)) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
    }

    private func tuning(for variant: TVStaticNoiseVariant) -> TVStaticNoiseVariantTuning {
        switch variant {
        case .classicAnalog:
            TVStaticNoiseVariantTuning(
                renderScale: 1,
                jitterX: 37,
                jitterY: 91,
                contrast: 1.9,
                brightnessScale: 1.25,
                brightnessBias: 0,
                redScale: 1,
                greenScale: 1,
                blueScale: 1
            )
        case .fineSnow:
            TVStaticNoiseVariantTuning(
                renderScale: 1.75,
                jitterX: 79,
                jitterY: 113,
                contrast: 2.18,
                brightnessScale: 1.05,
                brightnessBias: -0.04,
                redScale: 1,
                greenScale: 1,
                blueScale: 1
            )
        case .horizontalTear:
            TVStaticNoiseVariantTuning(
                renderScale: 1.15,
                jitterX: 151,
                jitterY: 17,
                contrast: 2.45,
                brightnessScale: 1.2,
                brightnessBias: -0.06,
                redScale: 1,
                greenScale: 1,
                blueScale: 1
            )
        case .greenTerminal:
            TVStaticNoiseVariantTuning(
                renderScale: 1.35,
                jitterX: 41,
                jitterY: 127,
                contrast: 2.05,
                brightnessScale: 1.1,
                brightnessBias: -0.1,
                redScale: 0.3,
                greenScale: 1.45,
                blueScale: 0.22
            )
        case .highContrast:
            TVStaticNoiseVariantTuning(
                renderScale: 0.82,
                jitterX: 97,
                jitterY: 211,
                contrast: 3.15,
                brightnessScale: 1.45,
                brightnessBias: -0.02,
                redScale: 1.08,
                greenScale: 1.08,
                blueScale: 1.08
            )
        }
    }
}

private struct TVStaticNoiseVariantTuning {
    let renderScale: CGFloat
    let jitterX: Double
    let jitterY: Double
    let contrast: Double
    let brightnessScale: Double
    let brightnessBias: Double
    let redScale: Double
    let greenScale: Double
    let blueScale: Double
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
