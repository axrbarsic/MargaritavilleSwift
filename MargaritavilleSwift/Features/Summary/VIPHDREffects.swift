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
        let components = OceanKeyTheme.statusRGBComponents(
            for: status,
            saturation: saturation,
            usesPurpleScheduled: usesPurpleScheduled
        )
        view.apply(
            VIPHDRStatusFillConfiguration(
                display: .init(
                    intensity: intensity,
                    red: components.red,
                    green: components.green,
                    blue: components.blue,
                    seed: seed
                ),
                mask: .init(
                    cornerRadius: cornerRadius,
                    isMenuExpanded: isMenuExpanded,
                    usesExternalMask: usesExternalMask
                )
            )
        )
    }
}

struct VIPHDRStatusFillConfiguration: Equatable, Sendable {
    struct Display: Equatable, Sendable {
        let intensity: CGFloat
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let seed: Double
    }

    struct Mask: Equatable, Sendable {
        let cornerRadius: CGFloat
        let isMenuExpanded: Bool
        let usesExternalMask: Bool
    }

    let display: Display
    let mask: Mask

    func changes(
        comparedTo previous: VIPHDRStatusFillConfiguration?
    ) -> VIPHDRStatusFillUpdate {
        guard let previous else { return [.display, .mask] }
        var changes: VIPHDRStatusFillUpdate = []
        if display != previous.display {
            changes.insert(.display)
        }
        if mask != previous.mask {
            changes.insert(.mask)
        }
        return changes
    }
}

struct VIPHDRStatusFillUpdate: OptionSet, Equatable, Sendable {
    let rawValue: Int

    static let display = VIPHDRStatusFillUpdate(rawValue: 1 << 0)
    static let mask = VIPHDRStatusFillUpdate(rawValue: 1 << 1)
}

private final class VIPHDRStatusFillUIView: UIView {
    private var configuration = VIPHDRStatusFillConfiguration(
        display: .init(intensity: 1, red: 0, green: 1, blue: 0, seed: 0),
        mask: .init(
            cornerRadius: 16,
            isMenuExpanded: false,
            usesExternalMask: false
        )
    )
    private var hasAppliedConfiguration = false
    private let maskLayer = CAShapeLayer()
    private var appliedMaskConfiguration: VIPHDRStatusFillConfiguration.Mask?
    private var appliedMaskBounds = CGRect.null

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
        updateMaskIfNeeded()
    }

    func apply(_ configuration: VIPHDRStatusFillConfiguration) {
        let previous = hasAppliedConfiguration ? self.configuration : nil
        let changes = configuration.changes(comparedTo: previous)
        guard !changes.isEmpty else { return }

        self.configuration = configuration
        hasAppliedConfiguration = true

        if changes.contains(.display) {
            configureDynamicRange()
            setNeedsDisplay()
        }
        if changes.contains(.mask) {
            updateMaskIfNeeded()
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), !bounds.isEmpty else { return }
        configureDynamicRange()

        RoomHDRRuntime.configure(context: context, targetHeadroom: targetHeadroom)

        context.clear(rect)
        context.setFillColor(extendedStatusColor(alpha: 1))
        context.fill(rect)
        drawSameColorLift(in: rect, context: context)
    }

    private var targetHeadroom: CGFloat {
        RoomHDRRuntime.targetHeadroom(intensity: configuration.display.intensity)
    }

    private func configureDynamicRange() {
        RoomHDRRuntime.configure(layer: layer, targetHeadroom: targetHeadroom)
    }

    private func drawSameColorLift(in rect: CGRect, context: CGContext) {
        RoomHDRRuntime.drawSameColorLift(
            in: rect,
            context: context,
            components: statusComponents,
            targetHeadroom: targetHeadroom,
            seed: configuration.display.seed
        )
    }

    private var statusComponents: (red: CGFloat, green: CGFloat, blue: CGFloat) {
        (
            configuration.display.red,
            configuration.display.green,
            configuration.display.blue
        )
    }

    private func updateMaskIfNeeded() {
        let maskConfiguration = configuration.mask
        if maskConfiguration.usesExternalMask {
            if layer.mask != nil {
                layer.mask = nil
            }
            appliedMaskConfiguration = maskConfiguration
            appliedMaskBounds = bounds
            return
        }

        guard layer.mask !== maskLayer
                || appliedMaskConfiguration != maskConfiguration
                || appliedMaskBounds != bounds
        else {
            return
        }

        maskLayer.frame = bounds
        maskLayer.path = staticMaskPath(in: bounds).cgPath
        if layer.mask !== maskLayer {
            layer.mask = maskLayer
        }
        appliedMaskConfiguration = maskConfiguration
        appliedMaskBounds = bounds
    }

    private func staticMaskPath(in rect: CGRect) -> UIBezierPath {
        let cornerRadius = configuration.mask.cornerRadius
        let bottomRadius = configuration.mask.isMenuExpanded ? 0 : cornerRadius
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
        RoomHDRRuntime.extendedColor(
            components: statusComponents,
            targetHeadroom: targetHeadroom,
            alpha: alpha
        )
    }

}

@MainActor
enum RoomHDRRuntime {
    static let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)
        ?? CGColorSpaceCreateDeviceRGB()

    static func targetHeadroom(intensity: CGFloat) -> CGFloat {
        let baseHeadroom = min(max(UIScreen.main.potentialEDRHeadroom, 1.65), 4.0)
        return min(baseHeadroom * max(intensity, 1), 8.0)
    }

    static func configure(layer: CALayer, targetHeadroom: CGFloat) {
        if #available(iOS 26.0, *) {
            layer.preferredDynamicRange = .high
            layer.contentsHeadroom = targetHeadroom
        } else if #available(iOS 17.0, *) {
            layer.wantsExtendedDynamicRangeContent = true
        }
    }

    static func configure(context: CGContext, targetHeadroom: CGFloat) {
        if #available(iOS 18.0, *) {
            _ = context.setEDRTargetHeadroom(Float(targetHeadroom))
        }
    }

    static func drawSameColorLift(
        in rect: CGRect,
        context: CGContext,
        components: (red: CGFloat, green: CGFloat, blue: CGFloat),
        targetHeadroom: CGFloat,
        seed: Double
    ) {
        guard let gradient = CGGradient(
            colorsSpace: RoomHDRRuntime.colorSpace,
            colors: [
                extendedColor(components: components, targetHeadroom: targetHeadroom, alpha: 0.34),
                extendedColor(components: components, targetHeadroom: targetHeadroom, alpha: 0.10),
                extendedColor(components: components, targetHeadroom: targetHeadroom, alpha: 0)
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

    static func extendedColor(
        components: (red: CGFloat, green: CGFloat, blue: CGFloat),
        targetHeadroom: CGFloat,
        alpha: CGFloat
    ) -> CGColor {
        let maximum = max(components.red, components.green, components.blue, 0.001)
        let scale = targetHeadroom / maximum
        return CGColor(
            colorSpace: colorSpace,
            components: [
                components.red * scale,
                components.green * scale,
                components.blue * scale,
                alpha
            ]
        ) ?? UIColor.white.withAlphaComponent(alpha).cgColor
    }
}
