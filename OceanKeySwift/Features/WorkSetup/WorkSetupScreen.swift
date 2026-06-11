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
                                territories: workSession.hotelProfile.catalog,
                                layout: workSession.hotelProfile.summaryLayout,
                                onFocus: { selectedCartNumber = cartNumber },
                                onTerritoryChanged: { territory in
                                    feedback.confirm()
                                    selectedCartNumber = cartNumber
                                    workSession.setCartBinding(cartNumber: cartNumber, territory: territory)
                                },
                                onRoomToggle: { room in
                                    playRoomSelectionFeedback(cartNumber: cartNumber, room: room)
                                    selectedCartNumber = cartNumber
                                    workSession.toggleRoomSelection(cartNumber: cartNumber, room: room)
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
                appSettings: appSettings,
                aiVisualPresetStore: aiVisualPresetStore,
                activeHotel: activeHotel,
                onSelectHotel: onSelectHotel
            )
                .preferredColorScheme(.dark)
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

    private func effectiveTerritory(forCart cartNumber: Int) -> Territory {
        workSession.territory(forCart: cartNumber)
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
