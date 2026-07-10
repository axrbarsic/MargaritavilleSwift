import SwiftUI

struct MargaritavilleSummarySection: View {
    let section: MargaritavilleSummaryHousekeeperSection
    let housekeeper: Housekeeper?
    let consumableTickerText: String?
    let geometry: RoomCellGeometry
    let zoomedRoomID: RoomCell.ID?
    let roomZoomNamespace: Namespace.ID
    let statusPaletteSaturation: Double
    let statusHDRPulseEvents: [RoomCell.ID: RoomStatusHDRPulseEvent]
    let onOpenCartDetails: (CartSection.ID, String) -> Void
    let onZoomRoom: (RoomCell) -> Void
    let onAdvance: (RoomCell.ID) -> Void
    let onOpenDetails: (RoomCell.ID, RoomDetailsMode) -> Void
    let onVIPToggle: (RoomCell.ID) -> Void
    let onReset: (RoomCell.ID) -> Void
    let onSchedule: (RoomCell.ID) -> Void

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: geometry.margaritavilleGridSpacing),
            count: geometry.margaritavilleGridColumnCount
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            groupHeader
            LazyVGrid(columns: columns, spacing: geometry.margaritavilleGridSpacing) {
                ForEach(section.rooms) { room in
                    tile(for: room)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    private var groupHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            HousekeeperSummaryNameButton(
                title: housekeeper?.displayName ?? "Уборщица",
                palette: housekeeper?.palette.color ?? OceanKeyTheme.accent,
                action: { onOpenCartDetails(section.primaryCartID, section.locationLabel) }
            )

            if let consumableTickerText, !consumableTickerText.isEmpty {
                SummaryConsumableTicker(text: consumableTickerText)
                    .frame(maxWidth: .infinity)
            } else {
                Spacer(minLength: 8)
            }

            Text(section.locationLabel)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.58)
        }
        .font(.system(size: 22, weight: .black, design: .rounded))
    }

    private func tile(for room: RoomCell) -> some View {
        MargaritavilleRoomTile(
            room: room,
            geometry: geometry,
            isZoomed: zoomedRoomID == room.id,
            zoomNamespace: roomZoomNamespace,
            statusPaletteSaturation: statusPaletteSaturation,
            statusHDRPulseEvent: statusHDRPulseEvents[room.id],
            onZoom: { onZoomRoom(room) },
            onAdvance: { onAdvance(room.id) },
            onOpenDetails: { mode in onOpenDetails(room.id, mode) },
            onVIPToggle: { onVIPToggle(room.id) },
            onReset: { onReset(room.id) },
            onSchedule: { onSchedule(room.id) }
        )
    }
}

private struct HousekeeperSummaryNameButton: View {
    let title: String
    let palette: Color
    let action: () -> Void
    @Environment(\.interactionFeedback) private var feedback

    var body: some View {
        Text(title)
            .font(.system(size: 25, weight: .black, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.62)
            .foregroundStyle(palette)
            .shadow(color: .black.opacity(0.92), radius: 1.6, x: 0, y: 1)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.black.opacity(0.34), in: Capsule())
            .background(palette.opacity(0.20), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(palette.opacity(0.72), lineWidth: 1.5)
            }
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 0.58, maximumDistance: 7) {
                feedback.longPress()
                action()
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Открывает меню уборщицы по долгому нажатию.")
    }
}

private struct MargaritavilleRoomTile: View {
    let room: RoomCell
    let geometry: RoomCellGeometry
    let isZoomed: Bool
    let zoomNamespace: Namespace.ID
    let statusPaletteSaturation: Double
    let statusHDRPulseEvent: RoomStatusHDRPulseEvent?
    let onZoom: () -> Void
    let onAdvance: () -> Void
    let onOpenDetails: (RoomDetailsMode) -> Void
    let onVIPToggle: () -> Void
    let onReset: () -> Void
    let onSchedule: () -> Void
    @Environment(\.interactionFeedback) private var feedback
    @Environment(\.experimentalVIPJellyEnabled) private var experimentalVIPJellyEnabled
    @Environment(\.experimentalVIPJellySpeed) private var experimentalVIPJellySpeed
    @Environment(\.experimentalVIPHDREnabled) private var experimentalVIPHDREnabled
    @Environment(\.experimentalStatusHDRPulseEnabled) private var experimentalStatusHDRPulseEnabled
    @Environment(\.experimentalCellPhysicsEnabled) private var experimentalCellPhysicsEnabled
    @Environment(\.experimentalCellSpringIntensity) private var experimentalCellSpringIntensity
    @Environment(\.experimentalCellSpringSpeed) private var experimentalCellSpringSpeed
    @State private var isActionDialogPresented = false
    @State private var actionSwipeArmed = false
    @State private var actionSwipeFeedbackStarted = false
    @State private var measuredTileWidth: CGFloat = 0
    @State private var statusHDRPulseStatus: RoomStatus?
    @State private var statusHDRPulseGeneration = 0
    @State private var cellPulseStartedAt: Date?
    @State private var cellPulseCleanupTask: Task<Void, Never>?

    var body: some View {
        tileBody
            .opacity(isZoomed ? 0 : 1)
            .simultaneousGesture(actionMenuSwipeGesture)
            .confirmationDialog("Комната \(room.id)", isPresented: $isActionDialogPresented, titleVisibility: .visible) {
                Button("Голос/медиа", systemImage: "mic.and.signal.meter.fill", action: openVoiceDetails)
                Button(room.isVIP ? "VIP выключить" : "VIP включить", systemImage: room.isVIP ? "diamond.fill" : "diamond", action: toggleVIP)
                Button("Назначить время", systemImage: "clock.fill", action: scheduleRoom)
                if canResetRoomToYellow {
                    Button("Вернуть в жёлтый", systemImage: "arrow.counterclockwise", action: resetRoom)
                }
            }
            .onChange(of: room.status(in: .simpleCycle)) { _, newStatus in
                if experimentalCellPhysicsEnabled, !experimentalStatusHDRPulseEnabled {
                    startCellPulse(status: nil)
                }
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
    }

    @ViewBuilder
    private var tileBody: some View {
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

    @ViewBuilder
    private func tileBodyContent(vipJellyTime: TimeInterval?, pulseHeat: CGFloat) -> some View {
        if geometry.margaritavilleHoldZoomEnabled {
            roomTileContent(vipJellyTime: vipJellyTime, pulseHeat: pulseHeat)
                .contentShape(Rectangle())
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Комната \(room.id)")
                .onLongPressGesture(
                    minimumDuration: 0.52,
                    maximumDistance: 8,
                    perform: zoomRoom
                )
        } else {
            HoldActionTarget(
                enabled: true,
                useLongPress: true,
                feedbackProfile: .roomCell,
                semanticLabel: "Комната \(room.id)",
                onActivate: advanceRoomWithPulse
            ) {
                roomTileContent(vipJellyTime: vipJellyTime, pulseHeat: pulseHeat)
            }
        }
    }

    private func roomTileContent(vipJellyTime: TimeInterval?, pulseHeat: CGFloat) -> some View {
        VStack(spacing: 6) {
            Text(room.id)
                .font(.system(size: 44, weight: .black, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.50)
            Text(timeLabel)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .foregroundStyle(OceanKeyTheme.roomForeground)
        .padding(.horizontal, 4)
        .padding(.vertical, 10)
        .frame(
            maxWidth: .infinity,
            minHeight: geometry.margaritavilleTileHeight,
            maxHeight: geometry.margaritavilleTileHeight
        )
        .background {
            fill(vipJellyTime: vipJellyTime, pulseHeat: pulseHeat)
        }
        .overlay(alignment: .bottomTrailing) {
            RoomMediaIndicator(room: room)
                .allowsHitTesting(false)
        }
        .roomCellStaticClip(enabled: !vipJellyActive, shape: tileShape)
        .vipJellyUnifiedLayer(
            enabled: vipJellyActive,
            time: vipJellyTime,
            speed: experimentalVIPJellySpeed,
            seed: vipJellySeed,
            cornerRadius: tileCornerRadius
        )
        .vipJellyShapeMask(
            enabled: vipJellyActive,
            time: vipJellyTime,
            speed: experimentalVIPJellySpeed,
            seed: vipJellySeed,
            cornerRadius: tileCornerRadius,
            isMenuExpanded: false
        )
        .matchedGeometryEffect(id: room.id, in: zoomNamespace)
        .scaleEffect(
            x: 1 + 0.10 * experimentalCellSpringIntensity * pulseRubberAmount(pulseHeat),
            y: 1 + 0.10 * experimentalCellSpringIntensity * pulseRubberAmount(pulseHeat)
        )
        .offset(y: -7.5 * experimentalCellSpringIntensity * pulseRubberAmount(pulseHeat))
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        measuredTileWidth = proxy.size.width
                    }
                    .onChange(of: proxy.size.width) { _, width in
                        measuredTileWidth = width
                    }
            }
        }
    }

    private func zoomRoom() {
        feedback.holdCommitHapticOnly()
        onZoom()
    }

    @ViewBuilder
    private func fill(vipJellyTime: TimeInterval?, pulseHeat: CGFloat) -> some View {
        let status = room.status(in: .simpleCycle)
        let pulseStatus = statusHDRPulseStatus ?? status
        let color = OceanKeyTheme.fill(
            for: status,
            saturation: statusPaletteSaturation,
            usesPurpleScheduled: false
        )
        ZStack {
            if vipHDRActive {
                Color.clear.vipHDRStatusFill(
                    enabled: true,
                    status: status,
                    saturation: statusPaletteSaturation,
                    usesPurpleScheduled: false,
                    seed: vipJellySeed,
                    cornerRadius: tileCornerRadius,
                    isMenuExpanded: false,
                    usesExternalMask: vipJellyActive
                )
            } else if vipJellyActive {
                Rectangle().fill(color)
            } else {
                tileShape.fill(color)
            }

            if statusHDRPulseStatus != nil {
                tileShape
                    .fill(
                        OceanKeyTheme.fill(
                            for: pulseStatus,
                            saturation: max(statusPaletteSaturation, 1.5),
                            usesPurpleScheduled: false
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
                    cornerRadius: tileCornerRadius,
                    isMenuExpanded: false,
                    usesExternalMask: vipJellyActive
                )
                .opacity(Double(pulseHeat))
            }
        }
    }

    private var tileShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: tileCornerRadius,
            bottomLeadingRadius: tileCornerRadius,
            bottomTrailingRadius: tileCornerRadius,
            topTrailingRadius: tileCornerRadius,
            style: .continuous
        )
    }

    private var tileCornerRadius: CGFloat {
        16
    }

    private var actionMenuSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 28, coordinateSpace: .local)
            .onChanged { value in
                updateActionSwipe(value)
            }
            .onEnded { value in
                finishActionSwipe(value)
            }
    }

    private func updateActionSwipe(_ value: DragGesture.Value) {
        let horizontal = value.translation.width
        let absX = abs(horizontal)
        let absY = abs(value.translation.height)
        guard absY <= 10 || absX > absY * 2.8 else {
            resetActionSwipe()
            return
        }
        guard horizontal > 0, absX >= 38, absX > absY * 2.8 else {
            if horizontal < -12 {
                resetActionSwipe()
            }
            return
        }

        let threshold = compactActionMenuThreshold
        let nextArmed = horizontal >= threshold
        if horizontal >= threshold * 0.86, !actionSwipeFeedbackStarted {
            actionSwipeFeedbackStarted = true
            feedback.holdStartHapticOnly()
        }
        if nextArmed, !actionSwipeArmed {
            feedback.holdCommitHapticOnly()
        } else if !nextArmed, horizontal >= threshold * 0.94, !actionSwipeArmed {
            feedback.holdWarningHapticOnly()
        }
        actionSwipeArmed = nextArmed
    }

    private func finishActionSwipe(_ value: DragGesture.Value) {
        defer { resetActionSwipe() }
        let horizontal = value.translation.width
        let predicted = value.predictedEndTranslation.width
        let absY = abs(value.translation.height)
        guard horizontal > 0, horizontal > absY * 2.5 else { return }
        let armed = actionSwipeArmed || SummarySwipeCommitPolicy.compactRoomActionMenuArmed(
            translation: horizontal,
            predictedTranslation: predicted,
            cellWidth: compactActionMenuCellWidth
        )
        guard armed else { return }
        feedback.playEvent(.actionMenuOpen)
        isActionDialogPresented = true
    }

    private func resetActionSwipe() {
        actionSwipeArmed = false
        actionSwipeFeedbackStarted = false
    }

    private var compactActionMenuThreshold: CGFloat {
        SummarySwipeCommitPolicy.compactRoomActionMenuThreshold(cellWidth: compactActionMenuCellWidth)
    }

    private var compactActionMenuCellWidth: CGFloat {
        measuredTileWidth > 0 ? measuredTileWidth : 88
    }

    private func advanceRoomWithPulse() {
        onAdvance()
    }

    private func openVoiceDetails() {
        feedback.tap()
        onOpenDetails(.voice)
    }

    private func toggleVIP() {
        feedback.confirm()
        if experimentalStatusHDRPulseEnabled {
            triggerStatusHDRPulse(for: room.status(in: .simpleCycle))
        } else if experimentalCellPhysicsEnabled {
            startCellPulse(status: nil)
        }
        onVIPToggle()
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

    private func pulseRubberAmount(_ heat: CGFloat) -> CGFloat {
        heat * RoomStatusHDRPulseTiming.rubberAmplitudeMultiplier
    }

    private func scheduleRoom() {
        feedback.tap()
        onSchedule()
    }

    private func resetRoom() {
        feedback.deselect()
        onReset()
    }

    private var timeLabel: String {
        let date = room.status(in: .simpleCycle) == .scheduled
            ? room.scheduledTime
            : (room.statusChangedAt ?? room.timeline.selectedAt)
        return date.map(margaritavilleTimeFormatter.string(from:)) ?? "--"
    }

    private var vipJellyActive: Bool {
        room.isVIP && experimentalVIPJellyEnabled
    }

    private var vipHDRActive: Bool {
        room.isVIP && experimentalVIPHDREnabled
    }

    private var vipJellySeed: Double {
        Double(abs(room.id.hashValue % 10_000)) / 10_000
    }

    private var canResetRoomToYellow: Bool {
        switch room.status(in: .simpleCycle) {
        case .pending:
            false
        case .open, .ready, .scheduled, .inProgress:
            true
        }
    }

}

private let margaritavilleTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "h:mm a"
    return formatter
}()
