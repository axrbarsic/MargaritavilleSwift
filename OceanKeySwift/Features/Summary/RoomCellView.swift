import SwiftUI
import UIKit

struct RoomCellView: View {
    @Environment(\.interactionFeedback) private var feedback
    @Environment(\.experimentalGlassVIPEnabled) private var experimentalGlassVIPEnabled
    @Environment(\.experimentalVIPParticlesEnabled) private var experimentalVIPParticlesEnabled
    @Environment(\.experimentalCellPhysicsEnabled) private var experimentalCellPhysicsEnabled
    @Environment(\.experimentalCellVolumeEnabled) private var experimentalCellVolumeEnabled
    @Environment(\.experimentalCellVolumeIntensity) private var experimentalCellVolumeIntensity
    @Environment(\.experimentalCellSpringIntensity) private var experimentalCellSpringIntensity
    @Environment(\.experimentalCellSpringSpeed) private var experimentalCellSpringSpeed
    @Environment(\.experimentalVIPZebraIntensity) private var experimentalVIPZebraIntensity
    @Environment(\.experimentalVIPZebraSpeed) private var experimentalVIPZebraSpeed

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
                .gesture(actionMenuDragGesture, including: .gesture)

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
        .background(cellBackground)
        .clipShape(tileShape)
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
                tileShape
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.03),
                                OceanKeyTheme.accent.opacity(0.10 + swipeProgress * 0.22),
                                .white.opacity(0.08 + swipeProgress * 0.20)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .blendMode(.screen)
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
        .experimentalCellVolume(
            enabled: experimentalCellVolumeEnabled,
            shape: tileShape,
            intensity: experimentalCellVolumeIntensity
        )
        .vipZebraEffect(
            enabled: room.isVIP,
            shape: tileShape,
            intensity: experimentalVIPZebraIntensity,
            speed: experimentalVIPZebraSpeed
        )
        .experimentalVIPGlass(enabled: experimentalGlassVIPEnabled && room.isVIP, shape: tileShape)
        .anchorPreference(key: VIPParticleAnchorPreferenceKey.self, value: .bounds) { anchor in
            guard room.isVIP, experimentalVIPParticlesEnabled else { return [] }
            return [
                VIPParticleAnchor(
                    id: room.id,
                    tintColor: UIColor(OceanKeyTheme.fill(for: room.status, saturation: statusPaletteSaturation)),
                    bounds: anchor
                )
            ]
        }
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
        .overlay(alignment: .bottomLeading) {
            if !room.noteIndicatorIcons.isEmpty {
                HStack(spacing: 5) {
                    ForEach(room.noteIndicatorIcons, id: \.self) { iconName in
                        Image(systemName: iconName)
                            .font(.system(size: 11, weight: .black))
                    }
                    if room.noteIndicatorCount > room.noteIndicatorIcons.count {
                        Text("+\(room.noteIndicatorCount - room.noteIndicatorIcons.count)")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .monospacedDigit()
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.black.opacity(0.72))
                .clipShape(Capsule())
                .padding(.leading, 10)
                .padding(.bottom, isActionMenuExpanded ? 7 : 8)
                .allowsHitTesting(false)
            }
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
            .onEnded { _ in
                finishActionMenuDrag()
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

        let threshold = actionMenuSwipeThreshold
        swipeProgress = min(max(absX / threshold, 0), 1)
        let armed = absX >= threshold
        if armed, !swipeArmed {
            feedback.holdCommit()
        } else if !armed, absX > threshold * 0.72, !swipeArmed {
            feedback.holdWarning()
        }
        swipeArmed = armed
    }

    private func finishActionMenuDrag() {
        defer { resetActionMenuDrag() }
        guard swipeDirection > 0, swipeArmed else { return }
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
        let visibleWidth = tileWidth > 0 ? tileWidth : UIScreen.main.bounds.width - 32
        return max(300, visibleWidth * 0.92)
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

    private var cellBackground: some View {
        tileShape
            .fill(OceanKeyTheme.fill(for: room.status, saturation: statusPaletteSaturation))
            .shadow(color: .black.opacity(geometry.tileShadowOpacity), radius: 5, x: 0, y: 4)
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
}

private extension View {
    @ViewBuilder
    func experimentalVIPGlass(enabled: Bool, shape: UnevenRoundedRectangle) -> some View {
        if enabled {
            if #available(iOS 26.0, *) {
                self.glassEffect(.regular.tint(.white.opacity(0.12)).interactive(), in: shape)
            } else {
                self.overlay {
                    shape
                        .stroke(.white.opacity(0.32), lineWidth: 1.5)
                        .blendMode(.screen)
                }
            }
        } else {
            self
        }
    }

    @ViewBuilder
    func experimentalCellVolume(
        enabled: Bool,
        shape: UnevenRoundedRectangle,
        intensity: Double
    ) -> some View {
        if enabled {
            let normalized = min(max(intensity, 0), 1)
            self
                .overlay {
                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.30 * normalized),
                                    .white.opacity(0.08 * normalized),
                                    .clear,
                                    .black.opacity(0.20 * normalized)
                                ],
                                startPoint: UnitPoint(x: 0.05, y: 0.0),
                                endPoint: UnitPoint(x: 0.92, y: 1.0)
                            )
                        )
                        .blendMode(.overlay)
                        .allowsHitTesting(false)
                }
                .overlay(alignment: .topLeading) {
                    GeometryReader { proxy in
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        .white.opacity(0.42 * normalized),
                                        .white.opacity(0.11 * normalized),
                                        .clear
                                    ],
                                    center: UnitPoint(x: 0.22, y: 0.24),
                                    startRadius: 2,
                                    endRadius: max(proxy.size.width, proxy.size.height) * 0.58
                                )
                            )
                            .frame(
                                width: proxy.size.width * 0.58,
                                height: proxy.size.height * 0.48
                            )
                            .offset(x: proxy.size.width * 0.04, y: proxy.size.height * 0.04)
                            .blendMode(.screen)
                            .allowsHitTesting(false)
                    }
                    .clipShape(shape)
                }
                .overlay {
                    shape
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.42 * normalized),
                                    .white.opacity(0.06 * normalized),
                                    .black.opacity(0.20 * normalized)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.2 + 1.6 * normalized
                        )
                        .blendMode(.screen)
                        .allowsHitTesting(false)
                }
                .shadow(
                    color: .black.opacity(0.18 + 0.18 * normalized),
                    radius: 7 + 9 * normalized,
                    x: 0,
                    y: 4 + 4 * normalized
                )
        } else {
            self
        }
    }

    @ViewBuilder
    func vipZebraEffect(
        enabled: Bool,
        shape: UnevenRoundedRectangle,
        intensity: Double,
        speed: Double
    ) -> some View {
        if enabled {
            self.overlay {
                VIPZebraOverlay(
                    shape: shape,
                    intensity: intensity,
                    speed: speed
                )
                .allowsHitTesting(false)
            }
        } else {
            self
        }
    }
}

private struct VIPZebraOverlay: View {
    let shape: UnevenRoundedRectangle
    let intensity: Double
    let speed: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate * min(max(speed, 0.2), 1.8)
            let offset = CGFloat(phase.truncatingRemainder(dividingBy: 1))
            shape
                .fill(
                    LinearGradient(
                        stops: zebraStops,
                        startPoint: UnitPoint(x: -0.55 + offset * 1.25, y: -0.08),
                        endPoint: UnitPoint(x: 0.50 + offset * 1.25, y: 1.08)
                    )
                )
                .blendMode(.screen)
                .clipShape(shape)
                .overlay {
                    shape
                        .stroke(.white.opacity(0.10 * normalizedIntensity), lineWidth: 1)
                        .blendMode(.screen)
                }
        }
    }

    private var normalizedIntensity: Double {
        min(max(intensity, 0), 1)
    }

    private var zebraStops: [Gradient.Stop] {
        let bright = 0.30 * normalizedIntensity
        let soft = 0.10 * normalizedIntensity
        let dark = 0.16 * normalizedIntensity
        return [
            .init(color: .clear, location: 0.00),
            .init(color: .white.opacity(soft), location: 0.08),
            .init(color: .white.opacity(bright), location: 0.14),
            .init(color: .clear, location: 0.22),
            .init(color: .black.opacity(dark), location: 0.30),
            .init(color: .clear, location: 0.38),
            .init(color: .white.opacity(bright * 0.86), location: 0.48),
            .init(color: .clear, location: 0.58),
            .init(color: .black.opacity(dark * 0.78), location: 0.68),
            .init(color: .clear, location: 0.78),
            .init(color: .white.opacity(bright), location: 0.88),
            .init(color: .clear, location: 1.00)
        ]
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

    var noteIndicatorIcons: [String] {
        var icons: [String] = []
        if textNote?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            icons.append("text.bubble.fill")
        }
        if voiceTranscript?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            || mediaAttachments?.contains(where: { $0.kind == .audio }) == true {
            icons.append("mic.fill")
        }
        if mediaAttachments?.contains(where: { $0.kind == .photo }) == true {
            icons.append("photo.fill")
        }
        if mediaAttachments?.contains(where: { $0.kind == .video }) == true {
            icons.append("video.fill")
        }
        return Array(icons.prefix(3))
    }

    var noteIndicatorCount: Int {
        let textCount = textNote?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? 1 : 0
        let transcriptCount = voiceTranscript?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? 1 : 0
        let mediaCount = mediaAttachments?.count ?? 0
        return textCount + transcriptCount + mediaCount
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
