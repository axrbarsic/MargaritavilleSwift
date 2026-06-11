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

    var body: some View {
        ZStack {
            if workSession.hotelProfile.summaryLayout == .squareGrid4 {
                Color.black.ignoresSafeArea()
            } else if isSettingsPresented {
                Color.black.ignoresSafeArea()
            } else {
                AppBackgroundView()
            }

            VStack(spacing: 18) {
                SummaryHeader(
                    counts: workSession.counts,
                    progressLabel: summaryProgressLabel,
                    statusChips: summaryStatusChips,
                    personalCartMarkers: $appSettings.personalCartMarkers,
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

        }
        .sheet(item: $roomDetailsRoute, onDismiss: closeActionMenus) { route in
            RoomDetailsScreen(route: route, workSession: workSession)
                .preferredColorScheme(.dark)
        }
        .sheet(item: $cartDetailsRoute) { route in
            CartDetailsScreen(route: route, workSession: workSession)
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
        feedback.tap()
        isSettingsPresented = true
    }

    private func openSelection() {
        feedback.confirm()
        workSession.unlockWorkdayForEditing()
    }

    private func toggleOpen(roomID: RoomCell.ID) {
        let hadSchedule = workSession.room(id: roomID)?.scheduledTime != nil
        workSession.toggleOpen(roomId: roomID)
        if hadSchedule, workSession.room(id: roomID)?.scheduledTime == nil {
            scheduleNotifications.cancelRoom(roomID)
        }
    }

    @ViewBuilder
    private var summarySections: some View {
        if workSession.hotelProfile.summaryLayout == .squareGrid4 {
            LazyVStack(spacing: 20) {
                ForEach($workSession.carts) { $cart in
                    MargaritavilleSummarySection(
                        cart: $cart,
                        statusPaletteSaturation: appSettings.statusPaletteSaturation,
                        onAdvance: toggleOpen,
                        onReset: workSession.resetSimpleCycle,
                        onSchedule: openSchedule
                    )
                }
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
                        onOpenCartDetails: { cartID in
                            expandedActionMenuRoomIDs.removeAll()
                            cartDetailsRoute = CartDetailsRoute(cartID: cartID)
                        },
                        onOpenDetails: { roomID, mode in
                            roomDetailsRoute = RoomDetailsRoute(roomID: roomID, mode: mode)
                        },
                        onOpenToggle: toggleOpen,
                        onTaskToggle: workSession.toggleTask,
                        onVIPToggle: workSession.toggleVIP,
                        onScheduleToggle: openSchedule
                    )
                }
            }
        }
    }

    private var summaryProgressLabel: String? {
        guard workSession.hotelProfile.workflowKind == .simpleCycle else { return nil }
        return "\(workSession.counts.completed)/\(workSession.counts.total)"
    }

    private var summaryStatusChips: [SummaryHeader.StatusChip] {
        guard workSession.hotelProfile.workflowKind == .simpleCycle else { return [] }
        let rooms = workSession.carts.flatMap(\.rooms)
        return [.open, .ready, .scheduled, .pending].map { status in
            SummaryHeader.StatusChip(
                status: status,
                count: rooms.filter { $0.status(in: .simpleCycle) == status }.count,
                usesPurpleScheduled: true
            )
        }
    }

    private func openSchedule(roomID: RoomCell.ID) {
        scheduleRoute = RoomScheduleRoute(
            roomID: roomID,
            initialDate: workSession.room(id: roomID)?.scheduledTime
        )
    }

    private func setSchedule(roomID: RoomCell.ID, dueAt: Date) {
        workSession.setSchedule(dueAt, roomId: roomID)
        expandedActionMenuRoomIDs.remove(roomID)
        if dueAt <= Date() {
            advanceScheduledRooms()
        } else {
            scheduleNotifications.scheduleRoom(roomID, dueAt)
        }
    }

    private func clearSchedule(roomID: RoomCell.ID) {
        workSession.setSchedule(nil, roomId: roomID)
        expandedActionMenuRoomIDs.remove(roomID)
        scheduleNotifications.cancelRoom(roomID)
    }

    private func closeActionMenus() {
        expandedActionMenuRoomIDs.removeAll()
    }

    private func advanceScheduledRooms(now: Date = Date()) {
        let openedRoomIDs = workSession.advanceScheduledRooms(now: now)
        for roomID in openedRoomIDs {
            scheduleNotifications.cancelRoom(roomID)
        }
    }
}

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
