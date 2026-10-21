import SwiftUI

struct WorkSetupScreen: View {
    @Bindable var workSession: WorkSessionStore
    @Bindable var appSettings: AppSettingsStore
    @Bindable var aiVisualPresetStore: AIVisualPresetStore
    @Bindable var performanceTelemetry: PerformanceTelemetryStore
    let activeHotel: HotelProfile
    let onSelectHotel: (HotelProfile) -> Void
    @Environment(\.interactionFeedback) private var feedback

    @State private var selectedCartNumber = 1
    @State private var isSettingsPresented = false
    @State private var selectionFlashGeneration = 0
    @State private var selectionFlashEvents: [RoomID: RoomSelectionHDRFlashEvent] = [:]
    @State private var cleanerSearchDismissGeneration = 0

    var body: some View {
        ZStack {
            if isSettingsPresented {
                Color.black.ignoresSafeArea()
            } else {
                AppBackgroundView()
            }

            VStack(spacing: 16) {
                WorkSetupHeader(
                    selectedCount: workSession.selection.selectedRooms.count,
                    canStart: workSession.selection.hasSelectedRooms,
                    onOpenSettings: openSettings,
                    onStart: startWorkday
                )

                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HousekeeperWorkPicker(
                                housekeepers: appSettings.housekeepers,
                                selectedIDs: selectedHousekeeperIDs,
                                focusedID: focusedHousekeeperID,
                                dismissRequestGeneration: cleanerSearchDismissGeneration,
                                onSelect: activateHousekeeper,
                                onSelectSuggestion: selectHousekeeperSuggestion
                            )

                            ForEach(workSession.selectedCartNumbers, id: \.self) { cartNumber in
                                CartSetupCard(
                                    territory: effectiveTerritory(forCart: cartNumber),
                                    selectedRooms: workSession.selectedRooms(forCart: cartNumber),
                                    reservedRooms: reservedRooms(forCart: cartNumber),
                                    isFocused: selectedCartNumber == cartNumber,
                                    territories: workSession.effectiveCatalog,
                                    layout: workSession.hotelProfile.summaryLayout,
                                    housekeeper: housekeeper(forCart: cartNumber),
                                    offTerritorySelectionGroups: offTerritorySelectionGroups(
                                        forCart: cartNumber,
                                        currentTerritory: effectiveTerritory(forCart: cartNumber)
                                    ),
                                    roomGridAnchorID: roomGridAnchorID(cartNumber),
                                    onFocus: {
                                        dismissCleanerSearch()
                                        selectedCartNumber = cartNumber
                                    },
                                    onRemove: {
                                        removeWorkItem(cartNumber)
                                    },
                                    onTerritoryChanged: { territory in
                                        dismissCleanerSearch()
                                        feedback.confirm()
                                        selectedCartNumber = cartNumber
                                        workSession.setCartBinding(cartNumber: cartNumber, territory: territory)
                                    },
                                    onRoomToggle: { room in
                                        dismissCleanerSearch()
                                        selectedCartNumber = cartNumber
                                        toggleRoom(cartNumber: cartNumber, room: room)
                                    }
                                )
                            }

                        if workSession.selectedCartNumbers.isEmpty {
                            EmptySetupHint()
                                .onTapGesture(perform: dismissCleanerSearch)
                        }
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 26)
                    }
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                    .overlayPreferenceValue(WorkSetupRoomBoundsPreferenceKey.self) { bounds in
                        WorkSetupSelectionHDRFlashOverlay(
                            events: selectionFlashEvents,
                            bounds: bounds,
                            layout: workSession.hotelProfile.summaryLayout
                        )
                    }
                    .onChange(of: focusedHousekeeperID) { oldID, newID in
                        guard let newID, newID != oldID,
                              let cartNumber = cartNumber(forHousekeeperID: newID)
                        else { return }
                        dismissCleanerSearch()
                        Task { @MainActor in
                            await Task.yield()
                            withAnimation(.easeOut(duration: 0.22)) {
                                scrollProxy.scrollTo(roomGridAnchorID(cartNumber), anchor: .top)
                            }
                        }
                    }
                }
            }
            .padding(.top, 18)
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
    }

    private func openSettings() {
        isSettingsPresented = true
    }

    private func startWorkday() {
        feedback.confirm()
        workSession.lockWorkday()
    }

    private func playRoomSelectionFeedback(cartNumber: Int, room: RoomID) {
        if workSession.selectedRooms(forCart: cartNumber).contains(room) {
            feedback.deselect()
        } else {
            feedback.select()
        }
    }

    private func toggleRoom(cartNumber: Int, room: RoomID) {
        let wasSelected = workSession.selectedRooms(forCart: cartNumber).contains(room)
        playRoomSelectionFeedback(cartNumber: cartNumber, room: room)
        let result = workSession.toggleRoomSelection(cartNumber: cartNumber, room: room)
        let isSelected = workSession.selectedRooms(forCart: cartNumber).contains(room)
        guard !wasSelected, result == .changed, isSelected else { return }
        recordSelectionFlash(cartNumber: cartNumber, room: room)
    }

    private func recordSelectionFlash(cartNumber: Int, room: RoomID) {
        selectionFlashGeneration += 1
        let event = RoomSelectionHDRFlashEvent(
            generation: selectionFlashGeneration,
            roomID: room,
            palette: housekeeper(forCart: cartNumber)?.palette ?? .mint,
            startedAt: Date()
        )
        selectionFlashEvents[room] = event
        trimSelectionFlashEventsIfNeeded()

        Task { @MainActor in
            try? await Task.sleep(for: RoomSelectionHDRFlashEvent.envelope.cleanupDelay)
            guard selectionFlashEvents[room]?.generation == event.generation else { return }
            selectionFlashEvents[room] = nil
        }
    }

    private func trimSelectionFlashEventsIfNeeded() {
        let maximumActiveEvents = 32
        guard selectionFlashEvents.count > maximumActiveEvents else { return }
        let overflow = selectionFlashEvents.count - maximumActiveEvents
        for event in selectionFlashEvents.values.sorted(by: { $0.startedAt < $1.startedAt }).prefix(overflow) {
            selectionFlashEvents[event.roomID] = nil
        }
    }

    private func effectiveTerritory(forCart cartNumber: Int) -> Territory {
        if let territoryID = workSession.selection.cartBindings[cartNumber]?.territoryID,
           let territory = workSession.catalogTerritory(id: territoryID) {
            return territory
        }
        if let territory = workSession.territory(forCart: cartNumber) {
            return territory
        }
        let boundTerritoryIDs = Set(workSession.selection.cartBindings.values.map(\.territoryID))
        return workSession.effectiveCatalog.first { !boundTerritoryIDs.contains($0.id) }
            ?? WorkSessionSelectionRules.preferredTerritory(
                forCart: cartNumber,
                existingBindings: workSession.selection.cartBindings,
                hotelProfile: workSession.hotelProfile
            )
    }

    private func reservedRooms(forCart cartNumber: Int) -> [RoomID: WorkSetupRoomReservation] {
        let territory = effectiveTerritory(forCart: cartNumber)
        var reservations: [RoomID: WorkSetupRoomReservation] = [:]

        for room in territory.rooms {
            guard let ownerCart = workSession.selection.roomOwnerCart(room), ownerCart != cartNumber else {
                continue
            }
            let owner = housekeeper(forCart: ownerCart)
            reservations[room] = WorkSetupRoomReservation(
                cartNumber: ownerCart,
                displayName: owner?.displayName ?? "Занято",
                paletteColor: owner?.palette.color ?? OceanKeyTheme.secondaryText
            )
        }

        return reservations
    }

    private func offTerritorySelectionGroups(
        forCart cartNumber: Int,
        currentTerritory: Territory
    ) -> [WorkSetupTerritorySelectionGroup] {
        let selectedRooms = workSession.selectedRooms(forCart: cartNumber)
        guard !selectedRooms.isEmpty else { return [] }
        return workSession.effectiveCatalog.compactMap { territory in
            guard territory.id != currentTerritory.id else { return nil }
            let rooms = territory.rooms.filter { selectedRooms.contains($0) }
            guard !rooms.isEmpty else { return nil }
            return WorkSetupTerritorySelectionGroup(territory: territory, rooms: rooms)
        }
    }

    private func housekeeper(forCart cartNumber: Int) -> Housekeeper? {
        appSettings.housekeeper(id: workSession.housekeeperID(forCart: cartNumber))
    }

    private var selectedHousekeeperIDs: Set<HousekeeperID> {
        Set(workSession.selectedCartNumbers.compactMap { workSession.housekeeperID(forCart: $0) })
    }

    private var focusedHousekeeperID: HousekeeperID? {
        workSession.housekeeperID(forCart: selectedCartNumber)
    }

    private func selectHousekeeperSuggestion(_ housekeeper: Housekeeper) {
        if let cartNumber = cartNumber(forHousekeeperID: housekeeper.id) {
            feedback.select()
            selectedCartNumber = cartNumber
            return
        }
        activateHousekeeper(housekeeper)
    }

    private func activateHousekeeper(_ housekeeper: Housekeeper) {
        if let cartNumber = cartNumber(forHousekeeperID: housekeeper.id) {
            removeWorkItem(cartNumber)
            return
        }

        guard let cartNumber = firstAvailableCartNumber else {
            feedback.invalid()
            return
        }

        feedback.select()
        selectedCartNumber = cartNumber
        workSession.toggleCartSelection(cartNumber)
        workSession.setCartHousekeeper(cartNumber: cartNumber, housekeeperID: housekeeper.id)
    }

    private func removeWorkItem(_ cartNumber: Int) {
        guard workSession.selectedCartNumbers.contains(cartNumber) else { return }
        feedback.deselect()
        workSession.toggleCartSelection(cartNumber)
        selectedCartNumber = workSession.selectedCartNumbers.first ?? WorkSessionSelectionRules.cartRange.lowerBound
    }

    private func dismissCleanerSearch() {
        cleanerSearchDismissGeneration += 1
    }

    private func roomGridAnchorID(_ cartNumber: Int) -> String {
        "work-setup-room-grid-\(cartNumber)"
    }

    private func cartNumber(forHousekeeperID housekeeperID: HousekeeperID) -> Int? {
        workSession.selectedCartNumbers.first { cartNumber in
            workSession.housekeeperID(forCart: cartNumber) == housekeeperID
        }
    }

    private var firstAvailableCartNumber: Int? {
        let selected = Set(workSession.selectedCartNumbers)
        return WorkSessionSelectionRules.cartRange.first { !selected.contains($0) }
    }
}

#Preview {
    WorkSetupScreen(
        workSession: .preview(),
        appSettings: AppSettingsStore(),
        aiVisualPresetStore: try! AIVisualPresetStore(inMemory: true),
        performanceTelemetry: PerformanceTelemetryStore(),
        activeHotel: .current,
        onSelectHotel: { _ in }
    )
        .preferredColorScheme(.dark)
}
