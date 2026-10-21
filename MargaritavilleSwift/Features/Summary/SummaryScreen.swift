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
    @State private var zoomedRoomID: RoomCell.ID?
    @State private var roomCommandCenterState = RoomCommandCenterStateMachine()
    @State private var roomStatusHDRPulseGeneration = 0
    @State private var roomStatusHDRPulseEvents: [RoomCell.ID: RoomStatusHDRPulseEvent] = [:]
    @State private var summaryLiveCells = SummaryLiveCellCollection()
    @State private var summaryLiveCellRendererReady = false
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

                summaryScrollViewport
            }
            .padding(.top, 18)

            if let zoomedRoom {
                MargaritavilleRoomZoomOverlay(
                    room: zoomedRoom,
                    namespace: roomZoomNamespace,
                    statusPaletteSaturation: appSettings.statusPaletteSaturation,
                    phase: roomCommandCenterState.phase,
                    onSelectStatus: { status in
                        selectCommandCenterStatus(status, roomID: zoomedRoom.id)
                    },
                    onToggleVIP: { toggleCommandCenterVIP(roomID: zoomedRoom.id) },
                    onOpenSchedule: { openSchedule(roomID: zoomedRoom.id) },
                    onOpenDetails: { mode in openRoomDetails(roomID: zoomedRoom.id, mode: mode) },
                    onCollapse: collapseRoomZoom
                )
                .zIndex(20)
            }
        }
        .sheet(item: $roomDetailsRoute, onDismiss: childFlowDidDismiss) { route in
            RoomDetailsScreen(
                route: route,
                workSession: workSession,
                onSuccessfulMutation: { completeChildFlowAfterMutation(roomID: route.roomID) }
            )
                .preferredColorScheme(.dark)
        }
        .sheet(item: $cartDetailsRoute) { route in
            CartDetailsScreen(route: route, workSession: workSession, appSettings: appSettings)
                .preferredColorScheme(.dark)
        }
        .sheet(item: $scheduleRoute, onDismiss: childFlowDidDismiss) { route in
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
        .onChange(of: appSettings.developerLive3DCellsEnabled) { _, isEnabled in
            if !isEnabled {
                summaryLiveCells = SummaryLiveCellCollection()
                summaryLiveCellRendererReady = false
            }
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

    @ViewBuilder
    private var summaryScrollViewport: some View {
        if appSettings.developerLive3DCellsEnabled {
            liveSummaryScrollViewport
        } else {
            standardSummaryScrollView
        }
    }

    private var standardSummaryScrollView: some View {
        ScrollView {
            summarySections
                .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
#if DEBUG
        .debugSummaryScrollProbe(performanceTelemetry)
#endif
    }

    private var liveSummaryScrollViewport: some View {
        GeometryReader { viewportProxy in
            ZStack {
                if !isSettingsPresented {
                    SummaryLiveCellViewport(
                        collection: summaryLiveCells,
                        vipHDREnabled: appSettings.developerVIPHDREnabled,
                        onRendererAvailabilityChange: { isAvailable in
                            summaryLiveCellRendererReady = isAvailable
                        }
                    )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                standardSummaryScrollView
                    .environment(
                        \.experimentalLive3DCellsRendererReady,
                        summaryLiveCellRendererReady
                    )
            }
            .coordinateSpace(name: SummaryLiveCellCoordinateSpace.name)
            .clipped()
            .onPreferenceChange(SummaryLiveCellPreferenceKey.self) { preferences in
                summaryLiveCells = SummaryLiveCellCollection(
                    preferences: preferences,
                    viewportSize: viewportProxy.size
                )
            }
        }
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
                        gridColumnCount: appSettings.margaritavilleGridColumnCount,
                        zoomedRoomID: zoomedRoomID,
                        roomZoomNamespace: roomZoomNamespace,
                        statusPaletteSaturation: appSettings.statusPaletteSaturation,
                        statusHDRPulseEvents: roomStatusHDRPulseEvents,
                        onOpenCartDetails: { cartID, subtitle in
                            openCartDetails(cartID: cartID, subtitle: subtitle)
                        },
                        onZoomRoom: zoomRoom,
                        onAdvance: toggleOpen,
                        onOpenDetails: openRoomDetails,
                        onVIPToggle: workSession.toggleVIP,
                        onReset: resetSimpleCycle,
                        onSchedule: openSchedule
                    )
                }

                SummaryConsumablesTable(report: consumablesReport)
                    .padding(.horizontal, 8)
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
            .padding(.horizontal, 8)
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

    private var zoomedRoom: RoomCell? {
        guard let zoomedRoomID else { return nil }
        return workSession.room(id: zoomedRoomID)
    }

    private func setSimpleCycleStatusFilter(_ status: RoomStatus?) {
        activeSimpleCycleStatusFilter = status
    }

    private func zoomRoom(_ room: RoomCell) {
        guard appSettings.roomCellGeometry.margaritavilleHoldZoomEnabled else { return }
        roomCommandCenterState.reset()
        withAnimation(roomZoomAnimation) {
            zoomedRoomID = room.id
        }
    }

    private func collapseRoomZoom() {
        roomCommandCenterState.reset()
        withAnimation(roomZoomAnimation) {
            zoomedRoomID = nil
        }
    }

    private func openSchedule(roomID: RoomCell.ID) {
        if zoomedRoomID == roomID {
            guard roomCommandCenterState.begin(.schedule) else { return }
        }
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
        completeChildFlowAfterMutation(roomID: roomID)
    }

    private func clearSchedule(roomID: RoomCell.ID) {
        let previousStatus = statusForSound(roomID: roomID)
        workSession.setSchedule(nil, roomId: roomID)
        expandedActionMenuRoomIDs.remove(roomID)
        handleRoomStatusChange(roomID: roomID, previousStatus: previousStatus)
        scheduleNotifications.cancelRoom(roomID)
        completeChildFlowAfterMutation(roomID: roomID)
    }

    private func childFlowDidDismiss() {
        expandedActionMenuRoomIDs.removeAll()
        if zoomedRoomID != nil {
            roomCommandCenterState.childDismissedWithoutMutation()
        }
    }

    private func openRoomDetails(roomID: RoomCell.ID, mode: RoomDetailsMode) {
        if zoomedRoomID == roomID {
            guard roomCommandCenterState.begin(.details(mode)) else { return }
        }
        roomDetailsRoute = RoomDetailsRoute(roomID: roomID, mode: mode)
    }

    private func selectCommandCenterStatus(_ status: RoomStatus, roomID: RoomCell.ID) {
        guard roomCommandCenterState.begin(.status(status)) else { return }
        let previousStatus = statusForSound(roomID: roomID)
        let hadSchedule = workSession.room(id: roomID)?.scheduledTime != nil

        switch status {
        case .pending:
            workSession.resetSimpleCycle(roomId: roomID)
        case .open, .ready:
            workSession.setSimpleCycleStatus(status, roomId: roomID)
        case .scheduled:
            _ = roomCommandCenterState.finishAtomic(succeeded: false)
            openSchedule(roomID: roomID)
            return
        case .inProgress:
            _ = roomCommandCenterState.finishAtomic(succeeded: false)
            return
        }

        handleRoomStatusChange(roomID: roomID, previousStatus: previousStatus)
        if hadSchedule, workSession.room(id: roomID)?.scheduledTime == nil {
            scheduleNotifications.cancelRoom(roomID)
        }
        finishAtomicCommand(succeeded: statusForSound(roomID: roomID) == status)
    }

    private func toggleCommandCenterVIP(roomID: RoomCell.ID) {
        guard roomCommandCenterState.begin(.vip),
              let previousValue = workSession.room(id: roomID)?.isVIP
        else { return }
        feedback.confirm()
        workSession.toggleVIP(roomId: roomID)
        finishAtomicCommand(succeeded: workSession.room(id: roomID)?.isVIP == !previousValue)
    }

    private func finishAtomicCommand(succeeded: Bool) {
        if roomCommandCenterState.finishAtomic(succeeded: succeeded) == .collapse {
            collapseRoomZoom()
        }
    }

    private func completeChildFlowAfterMutation(roomID: RoomCell.ID) {
        guard zoomedRoomID == roomID else { return }
        if roomCommandCenterState.childDidMutateRoom() == .collapse {
            collapseRoomZoom()
        }
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
        let event = RoomStatusHDRPulseEvent(
            generation: roomStatusHDRPulseGeneration,
            status: status,
            startedAt: Date()
        )
        roomStatusHDRPulseEvents[roomID] = event

        Task { @MainActor in
            try? await Task.sleep(for: RoomStatusHDRPulseTiming.cleanupDelay)
            guard roomStatusHDRPulseEvents[roomID]?.generation == event.generation else { return }
            roomStatusHDRPulseEvents[roomID] = nil
        }
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

#if DEBUG
private extension View {
    @ViewBuilder
    func debugSummaryScrollProbe(
        _ performanceTelemetry: PerformanceTelemetryStore
    ) -> some View {
        if #available(iOS 18.0, *) {
            onScrollPhaseChange { _, phase in
                performanceTelemetry.updateDebugSummaryScrollPhase(
                    isNonIdle: phase != .idle
                )
            }
            .onDisappear {
                performanceTelemetry.updateDebugSummaryScrollPhase(
                    isNonIdle: false
                )
            }
        } else {
            self
        }
    }
}
#endif

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
