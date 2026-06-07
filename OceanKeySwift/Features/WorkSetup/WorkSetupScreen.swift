import SwiftUI

struct WorkSetupScreen: View {
    @Bindable var workSession: WorkSessionStore
    @Bindable var appSettings: AppSettingsStore

    @State private var selectedCartNumber = 1
    @State private var isSettingsPresented = false

    var body: some View {
        ZStack {
            SpriteKitEffectView(.matrixRain)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                WorkSetupHeader(
                    selectedCount: workSession.selection.selectedRooms.count,
                    canStart: workSession.selection.hasSelectedRooms,
                    onOpenSettings: { isSettingsPresented = true },
                    onStart: { workSession.lockWorkday() }
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
                                onFocus: { selectedCartNumber = cartNumber },
                                onTerritoryChanged: { territory in
                                    selectedCartNumber = cartNumber
                                    workSession.setCartBinding(cartNumber: cartNumber, territory: territory)
                                },
                                onRoomToggle: { room in
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
            SettingsScreen(workSession: workSession, appSettings: appSettings)
                .preferredColorScheme(.dark)
        }
    }

    private func toggleCart(_ cartNumber: Int) {
        selectedCartNumber = cartNumber
        workSession.toggleCartSelection(cartNumber)
    }

    private func effectiveTerritory(forCart cartNumber: Int) -> Territory {
        workSession.territory(forCart: cartNumber)
            ?? WorkSessionSelectionRules.preferredTerritory(
                forCart: cartNumber,
                existingBindings: workSession.selection.cartBindings
            )
    }

    private func blockedRooms(forCart cartNumber: Int) -> [RoomID: Int] {
        workSession.blockedRooms(forCart: cartNumber, territory: effectiveTerritory(forCart: cartNumber))
    }
}

#Preview {
    WorkSetupScreen(workSession: .preview(), appSettings: AppSettingsStore())
        .preferredColorScheme(.dark)
}
