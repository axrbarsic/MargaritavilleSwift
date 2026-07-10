import SwiftUI
import UIKit

struct RoomCellView: View {
    @Environment(\.interactionFeedback) private var feedback
    @Environment(\.experimentalCellPhysicsEnabled) private var experimentalCellPhysicsEnabled
    @Environment(\.experimentalCellSpringIntensity) private var experimentalCellSpringIntensity
    @Environment(\.experimentalCellSpringSpeed) private var experimentalCellSpringSpeed
    @Environment(\.experimentalVIPJellyEnabled) private var experimentalVIPJellyEnabled
    @Environment(\.experimentalVIPJellySpeed) private var experimentalVIPJellySpeed
    @Environment(\.experimentalVIPHDREnabled) private var experimentalVIPHDREnabled
    @Environment(\.experimentalStatusHDRPulseEnabled) private var experimentalStatusHDRPulseEnabled

    @Binding var room: RoomCell
    let geometry: RoomCellGeometry
    let taskControlsUseLongPress: Bool
    let statusPaletteSaturation: Double
    let isActionMenuExpanded: Bool
    let statusHDRPulseEvent: RoomStatusHDRPulseEvent?
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
    @State private var physicsPulseTask: Task<Void, Never>?
    @State private var statusHDRPulseStatus: RoomStatus?
    @State private var statusHDRPulseGeneration = 0
    @State private var cellPulseStartedAt: Date?
    @State private var cellPulseCleanupTask: Task<Void, Never>?

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
                    onVIPToggle: activateVIPToggle,
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
        .task(id: statusHDRPulseEvent?.generation) {
            guard let statusHDRPulseEvent else { return }
            let now = Date()
            guard statusHDRPulseEvent.isActive(at: now) else { return }
            triggerStatusHDRPulse(
                for: statusHDRPulseEvent.status,
                startedAt: statusHDRPulseEvent.startedAt,
                now: now
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Room \(room.id)")
    }

    private var tileBody: some View {
        Group {
            if vipJellyActive || cellPulseStartedAt != nil {
                TimelineView(.animation(minimumInterval: 1.0 / 120.0)) { timeline in
                    tileBodyContent(
                        vipJellyTime: vipJellyActive ? timeline.date.timeIntervalSinceReferenceDate : nil,
                        pulseHeat: RoomStatusHDRPulseTiming.heat(
                            startedAt: cellPulseStartedAt,
                            now: timeline.date
                        )
                    )
                }
            } else {
                tileBodyContent(vipJellyTime: nil, pulseHeat: 0)
            }
        }
    }

    private func tileBodyContent(vipJellyTime: TimeInterval?, pulseHeat: CGFloat) -> some View {
        HStack(spacing: geometry.taskSpacing) {
            HoldActionTarget(
                enabled: true,
                useLongPress: taskControlsUseLongPress,
                feedbackProfile: .roomCell,
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
        .background {
            cellFill(vipJellyTime: vipJellyTime, pulseHeat: pulseHeat)
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
        .overlay(alignment: .bottomTrailing) {
            RoomMediaIndicator(room: room)
                .allowsHitTesting(false)
        }
        .overlay {
            if swipeProgress > 0 {
                RoomActionPuzzlePullOverlay(progress: swipeProgress)
                    .allowsHitTesting(false)
            }
        }
        .roomCellStaticClip(enabled: !vipJellyActive, shape: tileShape)
        .vipJellyUnifiedLayer(
            enabled: vipJellyActive,
            time: vipJellyTime,
            speed: experimentalVIPJellySpeed,
            seed: vipJellySeed,
            cornerRadius: geometry.tileCornerRadius
        )
        .vipJellyShapeMask(
            enabled: vipJellyActive,
            time: vipJellyTime,
            speed: experimentalVIPJellySpeed,
            seed: vipJellySeed,
            cornerRadius: geometry.tileCornerRadius,
            isMenuExpanded: isActionMenuExpanded
        )
        .shadow(color: .black.opacity(geometry.tileShadowOpacity), radius: 5, x: 0, y: 4)
        .scaleEffect(
            x: 1 + 0.09 * experimentalCellSpringIntensity * liveCellRubberPulseAmount(pulseHeat: pulseHeat),
            y: 1 + 0.09 * experimentalCellSpringIntensity * liveCellRubberPulseAmount(pulseHeat: pulseHeat)
        )
        .offset(y: -7 * experimentalCellSpringIntensity * liveCellRubberPulseAmount(pulseHeat: pulseHeat))
        .offset(x: swipeProgress * 10)
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
        .animation(
            liveCellRubberEnabled
                ? .interpolatingSpring(
                    stiffness: 180 + 220 * experimentalCellSpringSpeed,
                    damping: max(5, 15 - 7 * experimentalCellSpringIntensity)
                )
                : .default,
            value: physicsPulse
        )
    }

    private func taskButton(_ task: RoomTask) -> some View {
        HoldActionTarget(
            enabled: room.opened,
            useLongPress: taskControlsUseLongPress,
            feedbackProfile: .roomCell,
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
                feedback.holdStartHapticOnly()
            }
        }

        swipeProgress = SummarySwipeCommitPolicy.roomActionMenuProgress(
            translation: max(swipeDX, 0),
            cellWidth: actionMenuCellWidth
        )
        let armed = swipeProgress >= 1
        if armed, !swipeArmed {
            feedback.holdCommitHapticOnly()
        } else if !armed, swipeProgress > 0.86, !swipeArmed {
            feedback.holdWarningHapticOnly()
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
        if isActionMenuExpanded {
            feedback.deselect()
        } else {
            feedback.playEvent(.actionMenuOpen)
        }
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
        startRubberPulse()
    }

    private func startRubberPulse() {
        physicsPulseTask?.cancel()
        physicsPulse = true
        physicsPulseTask = Task { @MainActor in
            let duration = max(110, Int(280 / experimentalCellSpringSpeed))
            try? await Task.sleep(for: .milliseconds(duration))
            guard !Task.isCancelled else { return }
            physicsPulse = false
            physicsPulseTask = nil
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

    private func activateVIPToggle() {
        triggerPhysicsPulse()
        if experimentalStatusHDRPulseEnabled {
            triggerStatusHDRPulse(for: room.status)
        }
        onVIPToggle()
    }

    // VIP source must stay rectangular here. The shared jelly mask below creates
    // the animated silhouette; a pre-clip would kill the moving contour.
    @ViewBuilder
    private func cellFill(vipJellyTime: TimeInterval?, pulseHeat: CGFloat) -> some View {
        let fill = OceanKeyTheme.fill(for: room.status, saturation: statusPaletteSaturation)
        let pulseStatus = statusHDRPulseStatus ?? room.status
        ZStack {
            if vipHDRActive {
                Color.clear.vipHDRStatusFill(
                    enabled: true,
                    status: room.status,
                    saturation: statusPaletteSaturation,
                    usesPurpleScheduled: false,
                    seed: vipJellySeed,
                    cornerRadius: geometry.tileCornerRadius,
                    isMenuExpanded: isActionMenuExpanded,
                    usesExternalMask: vipJellyActive
                )
            } else if vipJellyActive {
                Rectangle().fill(fill)
            } else {
                tileShape.fill(fill)
            }

            if statusHDRPulseStatus != nil {
                tileShape
                    .fill(
                        OceanKeyTheme.fill(
                            for: pulseStatus,
                            saturation: max(statusPaletteSaturation, 1.5)
                        )
                    )
                    .brightness(min(1, 0.55 * Double(RoomStatusHDRPulseTiming.brightnessMultiplier)))
                    .saturation(1.45)
                    .blendMode(.plusLighter)
                    .opacity(Double(pulseHeat))

                Color.clear.vipHDRStatusFill(
                    enabled: true,
                    intensity: RoomStatusHDRPulseTiming.brightnessMultiplier,
                    status: pulseStatus,
                    saturation: statusPaletteSaturation,
                    usesPurpleScheduled: false,
                    seed: vipJellySeed,
                    cornerRadius: geometry.tileCornerRadius,
                    isMenuExpanded: isActionMenuExpanded,
                    usesExternalMask: vipJellyActive
                )
                .opacity(Double(pulseHeat))
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

    private var vipHDRActive: Bool {
        room.isVIP && experimentalVIPHDREnabled
    }

    private func triggerStatusHDRPulse(
        for status: RoomStatus,
        startedAt: Date = Date(),
        now: Date = Date()
    ) {
        guard experimentalStatusHDRPulseEnabled else { return }
        startCellPulse(status: status, startedAt: startedAt, now: now)
    }

    private func startCellPulse(
        status: RoomStatus?,
        startedAt: Date = Date(),
        now: Date = Date()
    ) {
        guard RoomStatusHDRPulseTiming.isActive(startedAt: startedAt, now: now) else { return }
        cellPulseCleanupTask?.cancel()
        statusHDRPulseGeneration += 1
        let generation = statusHDRPulseGeneration
        statusHDRPulseStatus = status
        cellPulseStartedAt = startedAt
        let remainingCleanupTime = RoomStatusHDRPulseTiming.remainingCleanupTime(
            startedAt: startedAt,
            now: now
        )
        cellPulseCleanupTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int(ceil(remainingCleanupTime * 1_000))))
            guard !Task.isCancelled, generation == statusHDRPulseGeneration else { return }
            cellPulseStartedAt = nil
            statusHDRPulseStatus = nil
            cellPulseCleanupTask = nil
        }
    }

    private var liveCellRubberEnabled: Bool {
        experimentalCellPhysicsEnabled || experimentalStatusHDRPulseEnabled
    }

    private func liveCellRubberPulseAmount(pulseHeat: CGFloat) -> CGFloat {
        let physicsAmount: CGFloat = experimentalCellPhysicsEnabled && physicsPulse ? 1 : 0
        let timedAmount = pulseHeat * RoomStatusHDRPulseTiming.rubberAmplitudeMultiplier
        return max(physicsAmount, timedAmount)
    }

    private var vipJellySeed: Double {
        Double(abs(room.id.hashValue % 10_000)) / 10_000
    }
}

// Кэш формата: body VIP-ячейки пересчитывается каждый кадр (TimelineView),
// создавать DateFormatter на каждый проход — лишние аллокации.
private let roomScheduleLabelFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "h:mm a"
    return formatter
}()

private extension RoomCell {
    var scheduleLabel: String? {
        guard let scheduledTime else { return nil }
        return roomScheduleLabelFormatter.string(from: scheduledTime)
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
        statusHDRPulseEvent: nil,
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
