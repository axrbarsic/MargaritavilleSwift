import SwiftUI

struct SummaryScreen: View {
    private let scheduleTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    @Bindable var workSession: WorkSessionStore
    @Bindable var appSettings: AppSettingsStore
    @Bindable var aiVisualPresetStore: AIVisualPresetStore
    @Bindable var performanceTelemetry: PerformanceTelemetryStore
    let activeHotel: HotelProfile
    let onSelectHotel: (HotelProfile) -> Void
    @Environment(\.interactionFeedback) private var feedback
    @Environment(\.scheduleNotifications) private var scheduleNotifications
    @State private var expandedActionMenuRoomIDs: Set<RoomCell.ID> = []
    @State private var roomDetailsRoute: RoomDetailsRoute?
    @State private var cartDetailsRoute: CartDetailsRoute?
    @State private var scheduleRoute: RoomScheduleRoute?
    @State private var isSettingsPresented = false
    @State private var activeSimpleCycleStatusFilter: RoomStatus?
    @State private var zoomedRoom: RoomCell?
    @State private var roomStatusHDRPulseGeneration = 0
    @State private var roomStatusHDRPulseEvents: [RoomCell.ID: RoomStatusHDRPulseEvent] = [:]
    @Namespace private var roomZoomNamespace

    var body: some View {
        ZStack {
            if isSettingsPresented {
                Color.black.ignoresSafeArea()
            } else {
                AppBackgroundView()
            }

            VStack(spacing: 18) {
                SummaryHeader(
                    counts: workSession.counts,
                    statusChips: summaryStatusChips,
                    activeStatusFilter: activeSimpleCycleStatusFilter,
                    onStatusFilterChanged: setSimpleCycleStatusFilter,
                    onOpenSettings: openSettings,
                    onOpenSelection: openSelection
                )

                ScrollView {
                    summarySections
                    .padding(.horizontal, 8)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.top, 18)

            if let zoomedRoom {
                MargaritavilleRoomZoomOverlay(
                    room: zoomedRoom,
                    namespace: roomZoomNamespace,
                    statusPaletteSaturation: appSettings.statusPaletteSaturation,
                    onCollapse: collapseRoomZoom
                )
                .zIndex(20)
            }
        }
        .sheet(item: $roomDetailsRoute, onDismiss: closeActionMenus) { route in
            RoomDetailsScreen(route: route, workSession: workSession)
                .preferredColorScheme(.dark)
        }
        .sheet(item: $cartDetailsRoute) { route in
            CartDetailsScreen(route: route, workSession: workSession, appSettings: appSettings)
                .preferredColorScheme(.dark)
        }
        .sheet(item: $scheduleRoute) { route in
            RoomScheduleSheet(route: route, onSet: setSchedule, onClear: clearSchedule)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsScreen(
                workSession: workSession,
                appSettings: appSettings,
                aiVisualPresetStore: aiVisualPresetStore,
                activeHotel: activeHotel,
                onSelectHotel: onSelectHotel
            )
                .preferredColorScheme(.dark)
        }
        .onAppear {
            advanceScheduledRooms()
        }
        .onChange(of: appSettings.summaryActionMenuAllowsMultiple) { _, allowsMultiple in
            expandedActionMenuRoomIDs = SummaryActionMenuExpansion.normalized(
                expandedActionMenuRoomIDs,
                allowsMultiple: allowsMultiple
            )
        }
        .onReceive(scheduleTimer) { date in
            advanceScheduledRooms(now: date)
        }
    }

    private func openSettings() {
        feedback.playEvent(.settingsOpen)
        isSettingsPresented = true
    }

    private func openSelection() {
        feedback.playEvent(.selectionOpen)
        workSession.unlockWorkdayForEditing()
    }

    private func toggleOpen(roomID: RoomCell.ID) {
        let previousStatus = statusForSound(roomID: roomID)
        let hadSchedule = workSession.room(id: roomID)?.scheduledTime != nil
        workSession.toggleOpen(roomId: roomID)
        handleRoomStatusChange(roomID: roomID, previousStatus: previousStatus)
        if hadSchedule, workSession.room(id: roomID)?.scheduledTime == nil {
            scheduleNotifications.cancelRoom(roomID)
        }
    }

    @ViewBuilder
    private var summarySections: some View {
        if workSession.hotelProfile.summaryLayout == .squareGrid4 {
            LazyVStack(spacing: 20) {
                ForEach(margaritavilleSummarySections) { section in
                    MargaritavilleSummarySection(
                        section: section,
                        housekeeper: housekeeper(id: section.housekeeperID),
                        consumableTickerText: consumableTickerTextBySectionID[section.id],
                        geometry: appSettings.roomCellGeometry,
                        zoomedRoomID: zoomedRoom?.id,
                        roomZoomNamespace: roomZoomNamespace,
                        statusPaletteSaturation: appSettings.statusPaletteSaturation,
                        statusHDRPulseEvents: roomStatusHDRPulseEvents,
                        onOpenCartDetails: { cartID, subtitle in
                            openCartDetails(cartID: cartID, subtitle: subtitle)
                        },
                        onZoomRoom: zoomRoom,
                        onAdvance: toggleOpen,
                        onOpenDetails: { roomID, mode in
                            roomDetailsRoute = RoomDetailsRoute(roomID: roomID, mode: mode)
                        },
                        onVIPToggle: workSession.toggleVIP,
                        onReset: resetSimpleCycle,
                        onSchedule: openSchedule
                    )
                }

                SummaryConsumablesTable(report: consumablesReport)
            }
        } else {
            LazyVStack(spacing: 18) {
                ForEach($workSession.carts) { $cart in
                    CartSummarySection(
                        cart: $cart,
                        geometry: appSettings.roomCellGeometry,
                        taskControlsUseLongPress: appSettings.roomTaskLongPress,
                        statusPaletteSaturation: appSettings.statusPaletteSaturation,
                        actionMenuAllowsMultiple: appSettings.summaryActionMenuAllowsMultiple,
                        expandedActionMenuRoomIDs: $expandedActionMenuRoomIDs,
                        statusHDRPulseEvents: roomStatusHDRPulseEvents,
                        onOpenCartDetails: { cartID in
                            expandedActionMenuRoomIDs.removeAll()
                            openCartDetails(cartID: cartID)
                        },
                        onOpenDetails: { roomID, mode in
                            roomDetailsRoute = RoomDetailsRoute(roomID: roomID, mode: mode)
                        },
                        onOpenToggle: toggleOpen,
                        onTaskToggle: toggleTask,
                        onVIPToggle: workSession.toggleVIP,
                        onScheduleToggle: openSchedule
                    )
                }
            }
        }
    }

    private var margaritavilleSummarySections: [MargaritavilleSummaryHousekeeperSection] {
        MargaritavilleSummaryRoomGrouping.housekeeperSections(
            carts: workSession.carts,
            selection: workSession.selection,
            hotelProfile: workSession.hotelProfile,
            statusFilter: activeSimpleCycleStatusFilter
        )
    }

    private var consumablesReport: SummaryConsumablesReport {
        SummaryConsumablesAggregator.makeReport(
            sections: margaritavilleSummarySections,
            carts: workSession.carts,
            housekeepers: appSettings.housekeepers,
            catalog: appSettings.cartConsumableCatalog
        )
    }

    private var consumableTickerTextBySectionID: [String: String] {
        Dictionary(uniqueKeysWithValues: consumablesReport.housekeepers.map { ($0.id, $0.tickerText) })
    }

    private var summaryStatusChips: [SummaryHeader.StatusChip] {
        guard workSession.hotelProfile.workflowKind == .simpleCycle else { return [] }
        let rooms = workSession.carts.flatMap(\.rooms)
        return [.open, .ready, .scheduled, .pending].map { status in
            SummaryHeader.StatusChip(
                status: status,
                count: rooms.filter { $0.status(in: .simpleCycle) == status }.count,
                usesPurpleScheduled: false
            )
        }
    }

    private func setSimpleCycleStatusFilter(_ status: RoomStatus?) {
        activeSimpleCycleStatusFilter = status
    }

    private func zoomRoom(_ room: RoomCell) {
        guard appSettings.roomCellGeometry.margaritavilleHoldZoomEnabled else { return }
        withAnimation(roomZoomAnimation) {
            zoomedRoom = room
        }
    }

    private func collapseRoomZoom() {
        withAnimation(roomZoomAnimation) {
            zoomedRoom = nil
        }
    }

    private func openSchedule(roomID: RoomCell.ID) {
        scheduleRoute = RoomScheduleRoute(
            roomID: roomID,
            initialDate: workSession.room(id: roomID)?.scheduledTime
        )
    }

    private func setSchedule(roomID: RoomCell.ID, dueAt: Date) {
        let previousStatus = statusForSound(roomID: roomID)
        workSession.setSchedule(dueAt, roomId: roomID)
        expandedActionMenuRoomIDs.remove(roomID)
        if dueAt <= Date() {
            advanceScheduledRooms()
        } else {
            handleRoomStatusChange(roomID: roomID, previousStatus: previousStatus)
            scheduleNotifications.scheduleRoom(roomID, dueAt)
        }
    }

    private func clearSchedule(roomID: RoomCell.ID) {
        let previousStatus = statusForSound(roomID: roomID)
        workSession.setSchedule(nil, roomId: roomID)
        expandedActionMenuRoomIDs.remove(roomID)
        handleRoomStatusChange(roomID: roomID, previousStatus: previousStatus)
        scheduleNotifications.cancelRoom(roomID)
    }

    private func closeActionMenus() {
        expandedActionMenuRoomIDs.removeAll()
    }

    private func openCartDetails(cartID: CartSection.ID, subtitle: String? = nil) {
        feedback.confirm()
        expandedActionMenuRoomIDs.removeAll()
        cartDetailsRoute = CartDetailsRoute(
            cartID: cartID,
            title: housekeeper(forCart: cartID)?.displayName,
            subtitle: subtitle ?? workSession.cart(id: cartID)?.building
        )
    }

    private func advanceScheduledRooms(now: Date = Date()) {
        let openedRoomIDs = workSession.advanceScheduledRooms(now: now)
        for roomID in openedRoomIDs {
            handleRoomStatusChange(roomID: roomID, previousStatus: .scheduled)
            scheduleNotifications.cancelRoom(roomID)
        }
    }

    private func toggleTask(_ task: RoomTask, roomID: RoomCell.ID) {
        let previousStatus = statusForSound(roomID: roomID)
        workSession.toggleTask(task, roomId: roomID)
        handleRoomStatusChange(roomID: roomID, previousStatus: previousStatus)
    }

    private func resetSimpleCycle(roomID: RoomCell.ID) {
        let previousStatus = statusForSound(roomID: roomID)
        workSession.resetSimpleCycle(roomId: roomID)
        handleRoomStatusChange(roomID: roomID, previousStatus: previousStatus)
    }

    private func statusForSound(roomID: RoomCell.ID) -> RoomStatus? {
        workSession.room(id: roomID)?.status(in: workSession.hotelProfile.workflowKind)
    }

    private func handleRoomStatusChange(roomID: RoomCell.ID, previousStatus: RoomStatus?) {
        guard let nextStatus = statusForSound(roomID: roomID),
              nextStatus != previousStatus
        else { return }
        feedback.playEvent(nextStatus.interactionSoundEvent)
        recordStatusHDRPulse(roomID: roomID, status: nextStatus)
    }

    private func recordStatusHDRPulse(roomID: RoomCell.ID, status: RoomStatus) {
        guard appSettings.developerStatusHDRPulseEnabled else { return }
        roomStatusHDRPulseGeneration += 1
        roomStatusHDRPulseEvents[roomID] = RoomStatusHDRPulseEvent(
            generation: roomStatusHDRPulseGeneration,
            status: status
        )
    }

    private func housekeeper(forCart cartNumber: Int) -> Housekeeper? {
        appSettings.housekeeper(id: workSession.housekeeperID(forCart: cartNumber))
    }

    private func housekeeper(id: HousekeeperID?) -> Housekeeper? {
        appSettings.housekeeper(id: id)
    }
}

private extension RoomStatus {
    var interactionSoundEvent: InteractionSoundEvent {
        switch self {
        case .pending: .roomPending
        case .open: .roomOpen
        case .inProgress: .roomInProgress
        case .ready: .roomReady
        case .scheduled: .roomScheduled
        }
    }
}

private let roomZoomAnimation = Animation.spring(
    response: 0.42,
    dampingFraction: 0.82,
    blendDuration: 0.08
)

#Preview {
    SummaryScreen(
        workSession: .preview(),
        appSettings: AppSettingsStore(),
        aiVisualPresetStore: try! AIVisualPresetStore(inMemory: true),
        performanceTelemetry: PerformanceTelemetryStore(),
        activeHotel: .current,
        onSelectHotel: { _ in }
    )
}
