import QuartzCore
import SwiftUI
import UIKit

extension View {
    @ViewBuilder
    func vipHDRStatusFill(
        enabled: Bool,
        intensity: CGFloat = 1,
        status: RoomStatus,
        saturation: Double,
        usesPurpleScheduled: Bool,
        seed: Double,
        cornerRadius: CGFloat,
        isMenuExpanded: Bool,
        usesExternalMask: Bool
    ) -> some View {
        if enabled {
            VIPHDRStatusFillLayer(
                intensity: intensity,
                status: status,
                saturation: saturation,
                usesPurpleScheduled: usesPurpleScheduled,
                seed: seed,
                cornerRadius: cornerRadius,
                isMenuExpanded: isMenuExpanded,
                usesExternalMask: usesExternalMask
            )
        } else {
            self
        }
    }
}

private struct VIPHDRStatusFillLayer: UIViewRepresentable {
    let intensity: CGFloat
    let status: RoomStatus
    let saturation: Double
    let usesPurpleScheduled: Bool
    let seed: Double
    let cornerRadius: CGFloat
    let isMenuExpanded: Bool
    let usesExternalMask: Bool

    func makeUIView(context: Context) -> VIPHDRStatusFillUIView {
        VIPHDRStatusFillUIView()
    }

    func updateUIView(_ view: VIPHDRStatusFillUIView, context: Context) {
        view.intensity = intensity
        view.statusComponents = OceanKeyTheme.statusRGBComponents(
            for: status,
            saturation: saturation,
            usesPurpleScheduled: usesPurpleScheduled
        )
        view.seed = seed
        view.cornerRadius = cornerRadius
        view.isMenuExpanded = isMenuExpanded
        view.usesExternalMask = usesExternalMask
    }
}

private final class VIPHDRStatusFillUIView: UIView {
    var intensity: CGFloat = 1 {
        didSet { setNeedsDisplay() }
    }

    var statusComponents: (red: CGFloat, green: CGFloat, blue: CGFloat) = (0, 1, 0) {
        didSet { setNeedsDisplay() }
    }

    var seed: Double = 0 {
        didSet { setNeedsDisplay() }
    }

    var cornerRadius: CGFloat = 16 {
        didSet {
            updateMask()
            setNeedsDisplay()
        }
    }

    var isMenuExpanded = false {
        didSet {
            updateMask()
            setNeedsDisplay()
        }
    }

    var usesExternalMask = false {
        didSet {
            updateMask()
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        isUserInteractionEnabled = false
        backgroundColor = .clear
        contentMode = .redraw
        layer.contentsScale = UIScreen.main.scale
        layer.contentsFormat = .RGBA16Float
        layer.drawsAsynchronously = true
        configureDynamicRange()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateMask()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), !bounds.isEmpty else { return }
        configureDynamicRange()

        if #available(iOS 18.0, *) {
            _ = context.setEDRTargetHeadroom(Float(targetHeadroom))
        }

        context.clear(rect)
        context.setFillColor(extendedStatusColor(alpha: 1))
        context.fill(rect)
        drawSameColorLift(in: rect, context: context)
    }

    private var targetHeadroom: CGFloat {
        let baseHeadroom = min(max(UIScreen.main.potentialEDRHeadroom, 1.65), 4.0)
        return min(baseHeadroom * max(intensity, 1), 8.0)
    }

    private func configureDynamicRange() {
        if #available(iOS 26.0, *) {
            layer.preferredDynamicRange = .high
            layer.contentsHeadroom = targetHeadroom
        } else if #available(iOS 17.0, *) {
            layer.wantsExtendedDynamicRangeContent = true
        }
    }

    private func drawSameColorLift(in rect: CGRect, context: CGContext) {
        guard let gradient = CGGradient(
            colorsSpace: extendedP3ColorSpace,
            colors: [
                extendedStatusColor(alpha: 0.34),
                extendedStatusColor(alpha: 0.10),
                extendedStatusColor(alpha: 0)
            ] as CFArray,
            locations: [0, 0.46, 1]
        ) else {
            return
        }

        let x = rect.minX + rect.width * CGFloat(0.30 + 0.08 * sin(seed * .pi * 2))
        let center = CGPoint(x: x, y: rect.minY + rect.height * 0.22)
        context.saveGState()
        context.setBlendMode(.plusLighter)
        context.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: max(rect.width, rect.height) * 0.90,
            options: [.drawsAfterEndLocation]
        )
        context.restoreGState()
    }

    private func updateMask() {
        if usesExternalMask {
            layer.mask = nil
            return
        }

        let mask = CAShapeLayer()
        mask.frame = bounds
        mask.path = staticMaskPath(in: bounds).cgPath
        layer.mask = mask
    }

    private func staticMaskPath(in rect: CGRect) -> UIBezierPath {
        let bottomRadius = isMenuExpanded ? 0 : cornerRadius
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius),
            controlPoint: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRadius))
        if bottomRadius > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - bottomRadius, y: rect.maxY),
                controlPoint: CGPoint(x: rect.maxX, y: rect.maxY)
            )
        }
        path.addLine(to: CGPoint(x: rect.minX + bottomRadius, y: rect.maxY))
        if bottomRadius > 0 {
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - bottomRadius),
                controlPoint: CGPoint(x: rect.minX, y: rect.maxY)
            )
        }
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY),
            controlPoint: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.close()
        return path
    }

    private func extendedStatusColor(alpha: CGFloat) -> CGColor {
        let components = boostedStatusComponents()
        return CGColor(
            colorSpace: extendedP3ColorSpace,
            components: [components.red, components.green, components.blue, alpha]
        ) ?? UIColor.white.withAlphaComponent(alpha).cgColor
    }

    private func boostedStatusComponents() -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        let maximum = max(statusComponents.red, statusComponents.green, statusComponents.blue, 0.001)
        let scale = targetHeadroom / maximum
        return (
            red: statusComponents.red * scale,
            green: statusComponents.green * scale,
            blue: statusComponents.blue * scale
        )
    }
}

private let extendedP3ColorSpace = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)
    ?? CGColorSpaceCreateDeviceRGB()
