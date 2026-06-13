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

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HousekeeperWorkPicker(
                            housekeepers: appSettings.housekeepers,
                            selectedIDs: selectedHousekeeperIDs,
                            focusedID: focusedHousekeeperID,
                            onSelect: activateHousekeeper
                        )

                        ForEach(workSession.selectedCartNumbers, id: \.self) { cartNumber in
                            CartSetupCard(
                                territory: effectiveTerritory(forCart: cartNumber),
                                selectedRooms: workSession.selectedRooms(forCart: cartNumber),
                                blockedRooms: blockedRooms(forCart: cartNumber),
                                isFocused: selectedCartNumber == cartNumber,
                                territories: workSession.effectiveCatalog,
                                layout: workSession.hotelProfile.summaryLayout,
                                housekeeper: housekeeper(forCart: cartNumber),
                                offTerritorySelectionGroups: offTerritorySelectionGroups(
                                    forCart: cartNumber,
                                    currentTerritory: effectiveTerritory(forCart: cartNumber)
                                ),
                                onFocus: { selectedCartNumber = cartNumber },
                                onRemove: {
                                    removeWorkItem(cartNumber)
                                },
                                onTerritoryChanged: { territory in
                                    feedback.confirm()
                                    selectedCartNumber = cartNumber
                                    workSession.setCartBinding(cartNumber: cartNumber, territory: territory)
                                },
                                onRoomToggle: { room in
                                    selectedCartNumber = cartNumber
                                    toggleRoom(cartNumber: cartNumber, room: room)
                                }
                            )
                        }

                        if workSession.selectedCartNumbers.isEmpty {
                            EmptySetupHint()
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 26)
                }
                .scrollIndicators(.hidden)
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
        feedback.tap()
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
        playRoomSelectionFeedback(cartNumber: cartNumber, room: room)
        workSession.toggleRoomSelection(cartNumber: cartNumber, room: room)
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

    private func blockedRooms(forCart cartNumber: Int) -> [RoomID: Int] {
        workSession.blockedRooms(forCart: cartNumber, territory: effectiveTerritory(forCart: cartNumber))
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
