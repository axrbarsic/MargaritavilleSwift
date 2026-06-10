import SwiftUI
import UIKit

struct RoomCellView: View {
    @Environment(\.interactionFeedback) private var feedback
    @Environment(\.experimentalCellPhysicsEnabled) private var experimentalCellPhysicsEnabled
    @Environment(\.experimentalCellSpringIntensity) private var experimentalCellSpringIntensity
    @Environment(\.experimentalCellSpringSpeed) private var experimentalCellSpringSpeed
    @Environment(\.experimentalVIPFlickerEnabled) private var experimentalVIPFlickerEnabled
    @Environment(\.experimentalVIPFlickerSpeed) private var experimentalVIPFlickerSpeed
    @Environment(\.experimentalVIPJellyEnabled) private var experimentalVIPJellyEnabled
    @Environment(\.experimentalVIPJellySpeed) private var experimentalVIPJellySpeed
    @Environment(\.experimentalVIPJellyDepthEnabled) private var experimentalVIPJellyDepthEnabled

    @Binding var room: RoomCell
    let geometry: RoomCellGeometry
    let taskControlsUseLongPress: Bool
    let statusPaletteSaturation: Double
    let isActionMenuExpanded: Bool
    let onActionMenuToggle: () -> Void
    let onOpenMultimodalNote: () -> Void
    let onOpenToggle: () -> Void
    let onTaskToggle: (RoomTask) -> Void
    let onVIPToggle: () -> Void
    let onScheduleToggle: () -> Void
    @State private var swipeFeedbackActive = false
    @State private var swipeDX: CGFloat = 0
    @State private var swipeDY: CGFloat = 0
    @State private var swipeDirection = 0
    @State private var swipeArmed = false
    @State private var swipeProgress: CGFloat = 0
    @State private var tileWidth: CGFloat = 0
    @State private var physicsPulse = false

    var body: some View {
        VStack(spacing: 0) {
            tileBody
                .contentShape(Rectangle())
                .highPriorityGesture(closeExpandedMenuTapGesture, including: .gesture)
                .simultaneousGesture(actionMenuDragGesture, including: .gesture)

            if isActionMenuExpanded {
                SummaryRoomActionMenu(
                    room: room,
                    onMultimodalNote: onOpenMultimodalNote,
                    onVIPToggle: onVIPToggle,
                    onScheduleToggle: onScheduleToggle
                )
                .transition(.roomActionMenuLamp)
            }
        }
        .animation(.smooth(duration: 1.15), value: isActionMenuExpanded)
        .onChange(of: room.status) { _, _ in
            triggerPhysicsPulse()
        }
        .onChange(of: room.completedTasks) { _, _ in
            triggerPhysicsPulse()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Room \(room.id)")
    }

    private var tileBody: some View {
        Group {
            if vipJellyActive {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                    tileBodyContent(vipJellyTime: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                tileBodyContent(vipJellyTime: nil)
            }
        }
    }

    private func tileBodyContent(vipJellyTime: TimeInterval?) -> some View {
        HStack(spacing: geometry.taskSpacing) {
            HoldActionTarget(
                enabled: true,
                useLongPress: taskControlsUseLongPress,
                semanticLabel: "Room \(room.id)",
                onActivate: activateOpenToggle
            ) {
                Text(room.id)
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(OceanKeyTheme.roomForeground)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ForEach(RoomTask.allCases) { taskButton($0) }
        }
        .padding(.leading, geometry.tileLeadingPadding)
        .padding(.trailing, geometry.tileTrailingPadding)
        .frame(height: geometry.tileHeight)
        .foregroundStyle(OceanKeyTheme.roomForeground)
        .vipJellyLayerWarp(
            enabled: vipJellyActive,
            time: vipJellyTime,
            speed: experimentalVIPJellySpeed,
            seed: vipJellySeed,
            size: CGSize(width: actionMenuCellWidth, height: geometry.tileHeight)
        )
        .background(cellBackground(time: vipJellyTime))
        .vipFlickerEffect(
            enabled: room.isVIP && experimentalVIPFlickerEnabled && !vipJellyActive,
            shape: tileShape,
            speed: experimentalVIPFlickerSpeed
        )
        .mask(cellMask(time: vipJellyTime))
        .scaleEffect(
            x: experimentalCellPhysicsEnabled && physicsPulse ? 1 + 0.09 * experimentalCellSpringIntensity : 1,
            y: experimentalCellPhysicsEnabled && physicsPulse ? 1 - 0.12 * experimentalCellSpringIntensity : 1
        )
        .offset(y: experimentalCellPhysicsEnabled && physicsPulse ? -7 * experimentalCellSpringIntensity : 0)
        .offset(x: swipeProgress * 10)
        .rotation3DEffect(
            .degrees(experimentalCellPhysicsEnabled && physicsPulse ? 7.5 * experimentalCellSpringIntensity : 0),
            axis: (x: 0.0, y: 1.0, z: 0.0),
            perspective: 0.72
        )
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        tileWidth = proxy.size.width
                    }
                    .onChange(of: proxy.size.width) { _, width in
                        tileWidth = width
                    }
            }
        }
        .overlay {
            if swipeProgress > 0 {
                RoomActionPuzzlePullOverlay(progress: swipeProgress)
                    .clipShape(tileShape)
                    .allowsHitTesting(false)
            }
        }
        .animation(
            experimentalCellPhysicsEnabled
                ? .interpolatingSpring(
                    stiffness: 180 + 220 * experimentalCellSpringSpeed,
                    damping: max(5, 15 - 7 * experimentalCellSpringIntensity)
                )
                : .default,
            value: physicsPulse
        )
        .overlay(alignment: .bottomTrailing) {
            if let scheduleLabel = room.scheduleLabel {
                Text(scheduleLabel)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.72))
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 8,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: isActionMenuExpanded ? 0 : 13,
                            topTrailingRadius: 0,
                            style: .continuous
                        )
                    )
            }
        }
        .overlay(alignment: .topTrailing) {
            RoomMediaIndicator(room: room)
                .padding(.top, 7)
                .padding(.trailing, 10)
                .allowsHitTesting(false)
        }
    }

    private func taskButton(_ task: RoomTask) -> some View {
        HoldActionTarget(
            enabled: room.opened,
            useLongPress: taskControlsUseLongPress,
            semanticLabel: "Room \(room.id) task \(task.rawValue)",
            onActivate: { activateTask(task) }
        ) {
            Text(task.rawValue)
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(taskColor(task))
                .frame(width: 50, height: 54)
        }
    }

    private var actionMenuDragGesture: some Gesture {
        DragGesture(minimumDistance: 26, coordinateSpace: .local)
            .onChanged { value in
                updateActionMenuDrag(value)
            }
            .onEnded { value in
                finishActionMenuDrag(value)
            }
    }

    private var closeExpandedMenuTapGesture: some Gesture {
        TapGesture()
            .onEnded {
                guard isActionMenuExpanded else { return }
                feedback.deselect()
                onActionMenuToggle()
            }
    }

    private func updateActionMenuDrag(_ value: DragGesture.Value) {
        swipeDX = value.translation.width
        swipeDY = value.translation.height

        let absX = abs(swipeDX)
        let absY = abs(swipeDY)
        if absY > 10, absY > absX {
            resetActionMenuDrag()
            return
        }

        if swipeDirection == 0 {
            guard absX >= 36, absX >= absY * 2.6 else { return }
            guard swipeDX > 0 else {
                resetActionMenuDrag()
                return
            }
            swipeDirection = 1
            if !swipeFeedbackActive {
                swipeFeedbackActive = true
                feedback.holdStart()
            }
        }

        swipeProgress = SummarySwipeCommitPolicy.roomActionMenuProgress(
            translation: max(swipeDX, 0),
            cellWidth: actionMenuCellWidth
        )
        let armed = swipeProgress >= 1
        if armed, !swipeArmed {
            feedback.holdCommit()
        } else if !armed, swipeProgress > 0.86, !swipeArmed {
            feedback.holdWarning()
        }
        swipeArmed = armed
    }

    private func finishActionMenuDrag(_ value: DragGesture.Value) {
        defer { resetActionMenuDrag() }
        let armed = swipeArmed || SummarySwipeCommitPolicy.roomActionMenuArmed(
            translation: value.translation.width,
            predictedTranslation: value.predictedEndTranslation.width,
            cellWidth: actionMenuCellWidth
        )
        guard swipeDirection > 0, armed else { return }
        feedback.confirm()
        onActionMenuToggle()
    }

    private func resetActionMenuDrag() {
        swipeFeedbackActive = false
        swipeDX = 0
        swipeDY = 0
        swipeDirection = 0
        swipeArmed = false
        withAnimation(.smooth(duration: 0.18)) {
            swipeProgress = 0
        }
    }

    private var actionMenuSwipeThreshold: CGFloat {
        SummarySwipeCommitPolicy.roomActionMenuThreshold(cellWidth: actionMenuCellWidth)
    }

    private var actionMenuCellWidth: CGFloat {
        tileWidth > 0 ? tileWidth : UIScreen.main.bounds.width - 32
    }

    private func triggerPhysicsPulse() {
        guard experimentalCellPhysicsEnabled else { return }
        physicsPulse = true
        Task { @MainActor in
            let duration = max(110, Int(280 / experimentalCellSpringSpeed))
            try? await Task.sleep(for: .milliseconds(duration))
            physicsPulse = false
        }
    }

    private func activateOpenToggle() {
        if !taskControlsUseLongPress {
            feedback.confirm()
        }
        triggerPhysicsPulse()
        onOpenToggle()
    }

    private func activateTask(_ task: RoomTask) {
        if !taskControlsUseLongPress {
            if room.completedTasks.contains(task) {
                feedback.deselect()
            } else {
                feedback.select()
            }
        }
        triggerPhysicsPulse()
        onTaskToggle(task)
    }

    private func cellBackground(time: TimeInterval?) -> some View {
        let statusColor = OceanKeyTheme.fill(for: room.status, saturation: statusPaletteSaturation)
        return Group {
            if vipJellyActive, let time {
                VIPJellyCellChrome(
                    time: time,
                    color: statusColor,
                    cornerRadius: geometry.tileCornerRadius,
                    isMenuExpanded: isActionMenuExpanded,
                    speed: experimentalVIPJellySpeed,
                    seed: vipJellySeed,
                    shadowOpacity: geometry.tileShadowOpacity,
                    flickerEnabled: experimentalVIPFlickerEnabled,
                    flickerSpeed: experimentalVIPFlickerSpeed,
                    depthEnabled: experimentalVIPJellyDepthEnabled
                )
            } else {
                tileShape
                    .fill(statusColor)
                    .shadow(color: .black.opacity(geometry.tileShadowOpacity), radius: 5, x: 0, y: 4)
            }
        }
    }

    private func cellMask(time: TimeInterval?) -> some View {
        Group {
            if vipJellyActive, let time {
                VIPJellyCellMask(
                    time: time,
                    cornerRadius: geometry.tileCornerRadius,
                    isMenuExpanded: isActionMenuExpanded,
                    speed: experimentalVIPJellySpeed,
                    seed: vipJellySeed
                )
            } else {
                tileShape.fill(.black)
            }
        }
    }

    private var tileShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: geometry.tileCornerRadius,
            bottomLeadingRadius: isActionMenuExpanded ? 0 : geometry.tileCornerRadius,
            bottomTrailingRadius: isActionMenuExpanded ? 0 : geometry.tileCornerRadius,
            topTrailingRadius: geometry.tileCornerRadius,
            style: .continuous
        )
    }

    private func taskColor(_ task: RoomTask) -> Color {
        guard room.opened else { return OceanKeyTheme.roomForeground.opacity(0.25) }
        return room.completedTasks.contains(task) ? OceanKeyTheme.roomForeground : OceanKeyTheme.roomForeground.opacity(0.32)
    }

    private var vipJellyActive: Bool {
        room.isVIP && experimentalVIPJellyEnabled
    }

    private var vipJellySeed: Double {
        Double(abs(room.id.hashValue % 10_000)) / 10_000
    }
}

private extension View {
    @ViewBuilder
    func vipFlickerEffect(
        enabled: Bool,
        shape: UnevenRoundedRectangle,
        speed: Double
    ) -> some View {
        if enabled {
            self.overlay {
                VIPFlickerOverlay(shape: shape, speed: speed)
                    .allowsHitTesting(false)
            }
        } else {
            self
        }
    }

}

private extension View {
    @ViewBuilder
    func vipJellyLayerWarp(
        enabled: Bool,
        time: TimeInterval?,
        speed: Double,
        seed: Double,
        size: CGSize
    ) -> some View {
        if enabled, let time {
            let amplitude = min(size.height * 0.11, 10)
            self.distortionEffect(
                ShaderLibrary.vipJellyContentWarp(
                    .float(Float(time)),
                    .float(Float(speed)),
                    .float(Float(seed)),
                    .float2(Float(size.width), Float(size.height)),
                    .float(Float(amplitude))
                ),
                maxSampleOffset: CGSize(width: amplitude * 0.3, height: amplitude)
            )
        } else {
            self
        }
    }
}

private struct VIPJellyCellChrome: View {
    let time: TimeInterval
    let color: Color
    let cornerRadius: CGFloat
    let isMenuExpanded: Bool
    let speed: Double
    let seed: Double
    let shadowOpacity: Double
    let flickerEnabled: Bool
    let flickerSpeed: Double
    let depthEnabled: Bool

    var body: some View {
        let shimmer = vipFlickerValue(time: time, speed: min(max(flickerSpeed, 0.4), 4.0))
        let flash = flickerEnabled ? pow(shimmer, 2.2) : 0
        let dip = flickerEnabled ? max(0, 0.5 - shimmer) * 0.42 : 0
        let shape = VIPJellyCellShape(
            time: time,
            speed: speed,
            seed: seed,
            cornerRadius: cornerRadius,
            isMenuExpanded: isMenuExpanded
        )
        ZStack {
            shape
                .fill(color)
            if depthEnabled {
                shape
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(0.52 + flash * 0.14),
                                .white.opacity(0.18),
                                .clear
                            ],
                            center: .topLeading,
                            startRadius: 4,
                            endRadius: 210
                        )
                    )
                    .blendMode(.screen)
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .black.opacity(0.08),
                                .black.opacity(0.36 + dip * 0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.multiply)
                shape
                    .stroke(.white.opacity(0.42 + flash * 0.12), lineWidth: 2.4)
                    .blur(radius: 0.45)
                    .offset(x: -1.1, y: -1.1)
                    .blendMode(.screen)
                shape
                    .stroke(.black.opacity(0.34 + dip * 0.18), lineWidth: 3.6)
                    .blur(radius: 1.2)
                    .offset(x: 1.7, y: 1.8)
                    .blendMode(.multiply)
                shape
                    .stroke(.white.opacity(0.18), lineWidth: 0.8)
                    .blur(radius: 0.1)
                    .blendMode(.screen)
            }
            ZStack {
                shape
                    .fill(.white.opacity(flickerEnabled ? 0.04 + flash * 0.38 : 0))
                    .blendMode(.screen)
                shape
                    .fill(.black.opacity(dip))
                    .blendMode(.multiply)
                shape
                    .stroke(.white.opacity(0.16 + flash * 0.22), lineWidth: 2.0)
                    .blendMode(.screen)
            }
            .compositingGroup()
        }
        .compositingGroup()
        .shadow(
            color: .black.opacity(depthEnabled ? shadowOpacity + 0.18 : shadowOpacity),
            radius: depthEnabled ? 10 : 5,
            x: 0,
            y: depthEnabled ? 7 : 4
        )
    }
}

private struct VIPJellyCellMask: View {
    let time: TimeInterval
    let cornerRadius: CGFloat
    let isMenuExpanded: Bool
    let speed: Double
    let seed: Double

    var body: some View {
        VIPJellyCellShape(
            time: time,
            speed: speed,
            seed: seed,
            cornerRadius: cornerRadius,
            isMenuExpanded: isMenuExpanded
        )
        .fill(.black)
    }
}

private struct VIPJellyCellShape: Shape {
    let time: TimeInterval
    let speed: Double
    let seed: Double
    let cornerRadius: CGFloat
    let isMenuExpanded: Bool

    func path(in rect: CGRect) -> Path {
        let normalizedSpeed = min(max(speed, 0.2), 2.5)
        let t = time * normalizedSpeed
        let amplitude = min(rect.height * 0.16, 14)
        let left = rect.minX
        let right = rect.maxX
        let top = rect.minY
        let bottom = rect.maxY
        let radius = min(cornerRadius, rect.height * 0.46, rect.width * 0.12)
        let bottomRadius = isMenuExpanded ? 0 : radius

        var path = Path()
        path.move(to: CGPoint(x: left + radius, y: top + jellyOffset(edge: 0, unit: 0, time: t, amplitude: amplitude)))
        addHorizontalEdge(to: &path, rect: rect, y: top, fromX: left + radius, toX: right - radius, edge: 0, time: t, amplitude: amplitude)
        path.addQuadCurve(
            to: CGPoint(x: right, y: top + radius),
            control: CGPoint(x: right + jellyOffset(edge: 4, unit: 0.25, time: t, amplitude: amplitude * 0.45), y: top)
        )
        addVerticalEdge(to: &path, rect: rect, x: right, fromY: top + radius, toY: bottom - bottomRadius, edge: 1, time: t, amplitude: amplitude)
        if bottomRadius > 0 {
            path.addQuadCurve(
                to: CGPoint(x: right - bottomRadius, y: bottom),
                control: CGPoint(x: right, y: bottom + jellyOffset(edge: 5, unit: 0.75, time: t, amplitude: amplitude * 0.45))
            )
        }
        addHorizontalEdge(to: &path, rect: rect, y: bottom, fromX: right - bottomRadius, toX: left + bottomRadius, edge: 2, time: t, amplitude: amplitude)
        if bottomRadius > 0 {
            path.addQuadCurve(
                to: CGPoint(x: left, y: bottom - bottomRadius),
                control: CGPoint(x: left + jellyOffset(edge: 6, unit: 0.35, time: t, amplitude: amplitude * 0.45), y: bottom)
            )
        }
        addVerticalEdge(to: &path, rect: rect, x: left, fromY: bottom - bottomRadius, toY: top + radius, edge: 3, time: t, amplitude: amplitude)
        path.addQuadCurve(
            to: CGPoint(x: left + radius, y: top),
            control: CGPoint(x: left, y: top + jellyOffset(edge: 7, unit: 0.9, time: t, amplitude: amplitude * 0.45))
        )
        path.closeSubpath()
        return path
    }

    private func addHorizontalEdge(
        to path: inout Path,
        rect: CGRect,
        y: CGFloat,
        fromX: CGFloat,
        toX: CGFloat,
        edge: Int,
        time: Double,
        amplitude: CGFloat
    ) {
        let steps = 24
        var points: [CGPoint] = []
        points.reserveCapacity(steps + 1)
        points.append(CGPoint(x: fromX, y: y + jellyOffset(edge: edge, unit: 0, time: time, amplitude: amplitude)))
        for index in 1...steps {
            let unit = Double(index) / Double(steps)
            let x = fromX + (toX - fromX) * CGFloat(unit)
            let offset = jellyOffset(edge: edge, unit: unit, time: time, amplitude: amplitude)
            points.append(CGPoint(x: x, y: y + offset))
        }
        addSmoothEdge(to: &path, points: points)
    }

    private func addVerticalEdge(
        to path: inout Path,
        rect: CGRect,
        x: CGFloat,
        fromY: CGFloat,
        toY: CGFloat,
        edge: Int,
        time: Double,
        amplitude: CGFloat
    ) {
        let steps = 10
        var points: [CGPoint] = []
        points.reserveCapacity(steps + 1)
        points.append(CGPoint(x: x + jellyOffset(edge: edge, unit: 0, time: time, amplitude: amplitude * 0.45), y: fromY))
        for index in 1...steps {
            let unit = Double(index) / Double(steps)
            let y = fromY + (toY - fromY) * CGFloat(unit)
            let offset = jellyOffset(edge: edge, unit: unit, time: time, amplitude: amplitude * 0.45)
            points.append(CGPoint(x: x + offset, y: y))
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
        let value = slow * 0.54 + medium * 0.30 + fast * 0.10 + drift * 0.06
        return CGFloat(value) * amplitude
    }
}

private struct VIPFlickerOverlay: View {
    let shape: UnevenRoundedRectangle
    let speed: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let normalizedSpeed = min(max(speed, 0.4), 4.0)
            let shimmer = vipFlickerValue(time: time, speed: normalizedSpeed)
            let flash = pow(shimmer, 2.2)
            let dip = max(0, 0.5 - shimmer) * 0.42
            ZStack {
                shape
                    .fill(.white.opacity(0.06 + flash * 0.42))
                    .blendMode(.screen)
                shape
                    .fill(.black.opacity(dip))
                    .blendMode(.multiply)
                shape
                    .stroke(.white.opacity(0.08 + flash * 0.24), lineWidth: 1.2)
                    .blendMode(.screen)
            }
            .compositingGroup()
        }
    }

}

private func vipFlickerValue(time: TimeInterval, speed: Double) -> Double {
    let fast = sin(time * 32.0 * speed)
    let faster = sin(time * 71.0 * speed + 1.7)
    let pulse = sin(time * 11.0 * speed + 0.4)
    let combined = fast * 0.42 + faster * 0.34 + pulse * 0.24
    return min(max((combined + 1) * 0.5, 0), 1)
}

private struct RoomMediaIndicator: View {
    let room: RoomCell

    var body: some View {
        if let primaryIcon = room.primaryAttachmentIndicatorIcon {
            HStack(spacing: 4) {
                Image(systemName: primaryIcon)
                    .font(.system(size: 14, weight: .black))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, OceanKeyTheme.accent)

                if room.attachmentIndicatorCount > 1 {
                    Text("\(room.attachmentIndicatorCount)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, room.attachmentIndicatorCount > 1 ? 7 : 6)
            .frame(height: 26)
            .background(.black.opacity(0.26), in: Capsule())
            .background(.ultraThinMaterial.opacity(0.72), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.36), lineWidth: 0.8)
            }
            .foregroundStyle(.white.opacity(0.96))
            .shadow(color: .black.opacity(0.36), radius: 4, x: 0, y: 1)
        }
    }
}

private struct RoomActionPuzzlePullOverlay: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let sinkSize = min(max(proxy.size.height * 0.52, 34), 48)
            let normalized = min(max(progress, 0), 1)
            let startCenterX = sinkSize * 0.5 + 14
            let targetCenterX = width - sinkSize * 0.5 - 16
            let pieceCenterX = startCenterX + (targetCenterX - startCenterX) * normalized

            ZStack(alignment: .leading) {
                LinearGradient(
                    colors: [
                        .white.opacity(0.02),
                        OceanKeyTheme.accent.opacity(0.08 + normalized * 0.15),
                        .white.opacity(0.04 + normalized * 0.16)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .blendMode(.screen)

                PuzzleSocket(progress: normalized)
                    .frame(width: sinkSize, height: sinkSize)
                    .position(x: targetCenterX, y: proxy.size.height * 0.5)

                PuzzlePiece(progress: normalized, systemName: "puzzlepiece.fill")
                    .frame(width: sinkSize, height: sinkSize)
                    .position(x: pieceCenterX, y: proxy.size.height * 0.5)
            }
        }
    }
}

private extension RoomCell {
    var scheduleLabel: String? {
        guard let scheduledTime else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: scheduledTime)
    }

    var primaryAttachmentIndicatorIcon: String? {
        guard let attachments = mediaAttachments, !attachments.isEmpty else { return nil }
        if attachments.contains(where: { $0.kind == .audio }) { return "waveform.circle.fill" }
        if attachments.contains(where: { $0.kind == .video }) { return "play.rectangle.fill" }
        if attachments.contains(where: { $0.kind == .photo }) { return "photo.circle.fill" }
        return "paperclip.circle.fill"
    }

    var attachmentIndicatorCount: Int {
        mediaAttachments?.count ?? 0
    }
}

#Preview {
    @Previewable @State var room = WorkSessionStore.preview().carts[0].rooms[0]
    return RoomCellView(
        room: $room,
        geometry: .roomy,
        taskControlsUseLongPress: true,
        statusPaletteSaturation: 1,
        isActionMenuExpanded: true,
        onActionMenuToggle: {},
        onOpenMultimodalNote: {},
        onOpenToggle: {},
        onTaskToggle: { _ in },
        onVIPToggle: {},
        onScheduleToggle: {}
    )
        .padding()
        .background(OceanKeyTheme.background)
}
