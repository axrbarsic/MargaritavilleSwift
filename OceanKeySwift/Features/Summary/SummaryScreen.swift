import SwiftUI

struct SummaryScreen: View {
    @Bindable var workSession: WorkSessionStore
    @State private var expandedActionMenuRoomID: RoomCell.ID?

    var body: some View {
        ZStack {
            SpriteKitEffectView(.matrixRain)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                SummaryHeader(counts: workSession.counts)

                ScrollView {
                    LazyVStack(spacing: 18) {
                        ForEach($workSession.carts) { $cart in
                            CartSummarySection(
                                cart: $cart,
                                expandedActionMenuRoomID: $expandedActionMenuRoomID,
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
    }
}

#Preview {
    SummaryScreen(workSession: .preview())
}
