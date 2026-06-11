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
    @State private var activeDayCategory: RoomDayCategory = .dueOut
    @State private var dayCategoryFilter: RoomDayCategory?
    @State private var dayCategoryTimePreset: RoomDayCategoryTimePreset?

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
                        CartNumberPicker(
                            selectedCarts: Set(workSession.selectedCartNumbers),
                            focusedCart: $selectedCartNumber,
                            onToggleCart: toggleCart
                        )

                        ForEach(workSession.selectedCartNumbers, id: \.self) { cartNumber in
                            CartSetupCard(
                                cartNumber: cartNumber,
                                territory: effectiveTerritory(forCart: cartNumber),
                                selectedRooms: workSession.selectedRooms(forCart: cartNumber),
                                blockedRooms: blockedRooms(forCart: cartNumber),
                                isFocused: selectedCartNumber == cartNumber,
                                territories: workSession.effectiveCatalog,
                                layout: workSession.hotelProfile.summaryLayout,
                                dayCategoriesEnabled: workSession.hotelProfile.dayCategoriesEnabled,
                                activeDayCategory: activeDayCategory,
                                dayCategoryFilter: dayCategoryFilter,
                                dayCategoryTimePreset: dayCategoryTimePreset,
                                roomCategory: { roomID in workSession.room(id: roomID)?.dayCategory },
                                roomCategoryTime: { roomID in workSession.room(id: roomID)?.dayCategoryTime },
                                onActiveDayCategoryChanged: setActiveDayCategory,
                                onDayCategoryFilterChanged: { dayCategoryFilter = $0 },
                                onDayCategoryTimePresetChanged: { dayCategoryTimePreset = $0 },
                                onFocus: { selectedCartNumber = cartNumber },
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

    private func setActiveDayCategory(_ category: RoomDayCategory) {
        activeDayCategory = category
        if category != .dueOut {
            dayCategoryTimePreset = nil
        }
    }

    private func toggleCart(_ cartNumber: Int) {
        if workSession.selectedCartNumbers.contains(cartNumber) {
            feedback.deselect()
        } else {
            feedback.select()
        }
        selectedCartNumber = cartNumber
        workSession.toggleCartSelection(cartNumber)
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
        if workSession.hotelProfile.dayCategoriesEnabled {
            toggleMargaritavilleRoom(cartNumber: cartNumber, room: room)
            return
        }
        playRoomSelectionFeedback(cartNumber: cartNumber, room: room)
        workSession.toggleRoomSelection(cartNumber: cartNumber, room: room)
    }

    private func toggleMargaritavilleRoom(cartNumber: Int, room: RoomID) {
        let selectedRooms = workSession.selectedRooms(forCart: cartNumber)
        let existingCategory = workSession.room(id: room)?.dayCategory
        if selectedRooms.contains(room), existingCategory == activeDayCategory {
            feedback.deselect()
            workSession.toggleRoomSelection(cartNumber: cartNumber, room: room)
            return
        }

        if !selectedRooms.contains(room) {
            feedback.select()
            let result = workSession.toggleRoomSelection(cartNumber: cartNumber, room: room)
            guard result == .changed else { return }
        } else {
            feedback.confirm()
        }
        let selectedTime = activeDayCategory == .dueOut ? dayCategoryTimePreset?.dateToday() : nil
        workSession.setDayCategory(activeDayCategory, time: selectedTime, roomId: room)
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
