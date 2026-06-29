import SwiftUI

extension View {
    /// Animated VIP layer kept CPU-only for reliable device rendering.
    /// The Metal layer effect can render transparent on some device/runtime combinations.
    @ViewBuilder
    func vipJellyUnifiedLayer(
        enabled: Bool,
        time: TimeInterval?,
        speed: Double,
        seed: Double,
        cornerRadius: CGFloat
    ) -> some View {
        if enabled, let time {
            let normalizedSpeed = min(max(speed, 0.2), 2.5)
            let t = time * normalizedSpeed + seed * 11.0
            self
                .compositingGroup()
                .scaleEffect(
                    x: 1.0 + 0.012 * sin(t * 1.7),
                    y: 1.0 + 0.018 * cos(t * 1.4)
                )
                .offset(x: 1.2 * sin(t * 1.1), y: 0.8 * cos(t * 1.3))
        } else {
            self
        }
    }

    @ViewBuilder
    func roomCellStaticClip(enabled: Bool, shape: UnevenRoundedRectangle) -> some View {
        if enabled {
            self.clipShape(shape)
        } else {
            self
        }
    }

    @ViewBuilder
    func vipJellyShapeMask(
        enabled: Bool,
        time: TimeInterval?,
        speed: Double,
        seed: Double,
        cornerRadius: CGFloat,
        isMenuExpanded: Bool
    ) -> some View {
        if enabled, let time {
            self.mask {
                VIPJellyCellShape(
                    time: time,
                    speed: speed,
                    seed: seed,
                    cornerRadius: cornerRadius,
                    isMenuExpanded: isMenuExpanded
                )
                .fill(.black)
            }
        } else {
            self
        }
    }
}

struct VIPJellyCellShape: Shape {
    let time: TimeInterval
    let speed: Double
    let seed: Double
    let cornerRadius: CGFloat
    let isMenuExpanded: Bool

    func path(in rect: CGRect) -> Path {
        let normalizedSpeed = min(max(speed, 0.2), 2.5)
        let t = time * normalizedSpeed
        let amplitude = min(rect.height * 0.22, 18)
        let left = rect.minX
        let right = rect.maxX
        let top = rect.minY
        let bottom = rect.maxY
        let radius = min(cornerRadius, rect.height * 0.46, rect.width * 0.12)
        let bottomRadius = isMenuExpanded ? 0 : radius

        var path = Path()
        path.move(to: CGPoint(x: left + radius, y: top + jellyOffset(edge: 0, unit: 0, time: t, amplitude: amplitude)))
        addHorizontalEdge(to: &path, y: top, fromX: left + radius, toX: right - radius, edge: 0, time: t, amplitude: amplitude)
        path.addQuadCurve(
            to: CGPoint(x: right, y: top + radius),
            control: CGPoint(x: right + jellyOffset(edge: 4, unit: 0.25, time: t, amplitude: amplitude * 0.55), y: top)
        )
        addVerticalEdge(to: &path, x: right, fromY: top + radius, toY: bottom - bottomRadius, edge: 1, time: t, amplitude: amplitude)
        if bottomRadius > 0 {
            path.addQuadCurve(
                to: CGPoint(x: right - bottomRadius, y: bottom),
                control: CGPoint(x: right, y: bottom + jellyOffset(edge: 5, unit: 0.75, time: t, amplitude: amplitude * 0.55))
            )
        }
        addHorizontalEdge(to: &path, y: bottom, fromX: right - bottomRadius, toX: left + bottomRadius, edge: 2, time: t, amplitude: amplitude)
        if bottomRadius > 0 {
            path.addQuadCurve(
                to: CGPoint(x: left, y: bottom - bottomRadius),
                control: CGPoint(x: left + jellyOffset(edge: 6, unit: 0.35, time: t, amplitude: amplitude * 0.55), y: bottom)
            )
        }
        addVerticalEdge(to: &path, x: left, fromY: bottom - bottomRadius, toY: top + radius, edge: 3, time: t, amplitude: amplitude)
        path.addQuadCurve(
            to: CGPoint(x: left + radius, y: top),
            control: CGPoint(x: left, y: top + jellyOffset(edge: 7, unit: 0.9, time: t, amplitude: amplitude * 0.55))
        )
        path.closeSubpath()
        return path
    }

    private func addHorizontalEdge(
        to path: inout Path,
        y: CGFloat,
        fromX: CGFloat,
        toX: CGFloat,
        edge: Int,
        time: Double,
        amplitude: CGFloat
    ) {
        let steps = 28
        var points: [CGPoint] = []
        points.reserveCapacity(steps + 1)
        for index in 0...steps {
            let unit = Double(index) / Double(steps)
            let x = fromX + (toX - fromX) * CGFloat(unit)
            points.append(CGPoint(x: x, y: y + jellyOffset(edge: edge, unit: unit, time: time, amplitude: amplitude)))
        }
        addSmoothEdge(to: &path, points: points)
    }

    private func addVerticalEdge(
        to path: inout Path,
        x: CGFloat,
        fromY: CGFloat,
        toY: CGFloat,
        edge: Int,
        time: Double,
        amplitude: CGFloat
    ) {
        let steps = 12
        var points: [CGPoint] = []
        points.reserveCapacity(steps + 1)
        for index in 0...steps {
            let unit = Double(index) / Double(steps)
            let y = fromY + (toY - fromY) * CGFloat(unit)
            points.append(CGPoint(x: x + jellyOffset(edge: edge, unit: unit, time: time, amplitude: amplitude * 0.55), y: y))
        }
        addSmoothEdge(to: &path, points: points)
    }

    private func addSmoothEdge(to path: inout Path, points: [CGPoint]) {
        guard points.count > 1 else { return }
        for index in 0..<(points.count - 1) {
            let previous = points[max(index - 1, 0)]
            let current = points[index]
            let next = points[index + 1]
            let afterNext = points[min(index + 2, points.count - 1)]
            let control1 = CGPoint(
                x: current.x + (next.x - previous.x) / 6,
                y: current.y + (next.y - previous.y) / 6
            )
            let control2 = CGPoint(
                x: next.x - (afterNext.x - current.x) / 6,
                y: next.y - (afterNext.y - current.y) / 6
            )
            path.addCurve(to: next, control1: control1, control2: control2)
        }
    }

    private func jellyOffset(edge: Int, unit: Double, time: Double, amplitude: CGFloat) -> CGFloat {
        let edgeSeed = seed * 19.37 + Double(edge) * 0.731
        let slow = sin((unit * (1.7 + edgeSeed.truncatingRemainder(dividingBy: 1.9)) + time * (0.31 + edgeSeed * 0.017) + edgeSeed) * .pi * 2)
        let medium = sin((unit * (3.1 + edgeSeed.truncatingRemainder(dividingBy: 2.4)) - time * (0.47 + seed * 0.09) + edgeSeed * 1.41) * .pi * 2)
        let fast = sin((unit * (4.6 + seed * 1.7) + time * (0.61 + Double(edge) * 0.017) + edgeSeed * 2.17) * .pi * 2)
        let drift = sin((time * 0.113 + seed * 8.0 + Double(edge)) * .pi * 2)
        let value = slow * 0.52 + medium * 0.31 + fast * 0.11 + drift * 0.06
        return CGFloat(value) * amplitude
    }
}
