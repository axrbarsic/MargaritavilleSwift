import SwiftUI
import UIKit

struct RoomCellView: View {
    @Environment(\.interactionFeedback) private var feedback
    @Environment(\.experimentalCellPhysicsEnabled) private var experimentalCellPhysicsEnabled
    @Environment(\.experimentalCellSpringIntensity) private var experimentalCellSpringIntensity
    @Environment(\.experimentalCellSpringSpeed) private var experimentalCellSpringSpeed
    @Environment(\.experimentalVIPZebraIntensity) private var experimentalVIPZebraIntensity
    @Environment(\.experimentalVIPZebraSpeed) private var experimentalVIPZebraSpeed
    @Environment(\.experimentalVIPZebraSharpness) private var experimentalVIPZebraSharpness

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
        .vipZebraEffect(
            enabled: room.isVIP,
            shape: tileShape,
            intensity: experimentalVIPZebraIntensity,
            speed: experimentalVIPZebraSpeed,
            sharpness: experimentalVIPZebraSharpness
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
    func vipZebraEffect(
        enabled: Bool,
        shape: UnevenRoundedRectangle,
        intensity: Double,
        speed: Double,
        sharpness: Double
    ) -> some View {
        if enabled {
            self.overlay {
                VIPZebraOverlay(
                    shape: shape,
                    intensity: intensity,
                    speed: speed,
                    sharpness: sharpness
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
    let sharpness: Double

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

    private var normalizedSharpness: Double {
        min(max(sharpness, 0), 1)
    }

    private var zebraStops: [Gradient.Stop] {
        let bright = (0.20 + 0.32 * normalizedSharpness) * normalizedIntensity
        let soft = (0.11 - 0.075 * normalizedSharpness) * normalizedIntensity
        let dark = (0.10 + 0.18 * normalizedSharpness) * normalizedIntensity
        let edge = max(0.018, 0.060 - 0.042 * normalizedSharpness)
        return [
            .init(color: .clear, location: 0.00),
            .init(color: .white.opacity(soft), location: 0.12 - edge),
            .init(color: .white.opacity(bright), location: 0.12),
            .init(color: .clear, location: 0.12 + edge),
            .init(color: .black.opacity(dark), location: 0.31),
            .init(color: .clear, location: 0.31 + edge),
            .init(color: .white.opacity(bright * 0.86), location: 0.48),
            .init(color: .clear, location: 0.48 + edge),
            .init(color: .black.opacity(dark * 0.78), location: 0.68),
            .init(color: .clear, location: 0.68 + edge),
            .init(color: .white.opacity(bright), location: 0.88),
            .init(color: .clear, location: min(1, 0.88 + edge))
        ]
    }
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
