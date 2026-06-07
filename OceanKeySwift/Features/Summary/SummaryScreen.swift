import SwiftUI

struct SummaryScreen: View {
    @Bindable var workSession: WorkSessionStore
    @State private var expandedActionMenuRoomID: RoomCell.ID?
    @State private var roomDetailsRoute: RoomDetailsRoute?
    @State private var cartDetailsRoute: CartDetailsRoute?
    @State private var isSettingsPresented = false

    var body: some View {
        ZStack {
            SpriteKitEffectView(.matrixRain)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                SummaryHeader(
                    counts: workSession.counts,
                    onOpenSettings: { isSettingsPresented = true }
                )

                ScrollView {
                    LazyVStack(spacing: 18) {
                        ForEach($workSession.carts) { $cart in
                            CartSummarySection(
                                cart: $cart,
                                expandedActionMenuRoomID: $expandedActionMenuRoomID,
                                onOpenCartDetails: { cartID in
                                    expandedActionMenuRoomID = nil
                                    cartDetailsRoute = CartDetailsRoute(cartID: cartID)
                                },
                                onOpenDetails: { roomID, mode in
                                    expandedActionMenuRoomID = nil
                                    roomDetailsRoute = RoomDetailsRoute(roomID: roomID, mode: mode)
                                },
                                onOpenToggle: workSession.toggleOpen,
                                onTaskToggle: workSession.toggleTask,
                                onVIPToggle: workSession.toggleVIP,
                                onScheduleToggle: workSession.toggleSchedule
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.top, 18)
        }
        .sheet(item: $roomDetailsRoute) { route in
            RoomDetailsScreen(route: route, workSession: workSession)
                .preferredColorScheme(.dark)
        }
        .sheet(item: $cartDetailsRoute) { route in
            CartDetailsScreen(route: route, workSession: workSession)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsScreen(workSession: workSession)
                .preferredColorScheme(.dark)
        }
    }
}

#Preview {
    SummaryScreen(workSession: .preview())
}
