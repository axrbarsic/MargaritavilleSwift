import SwiftUI

struct CartSummarySection: View {
    @Binding var cart: CartSection
    @Binding var expandedActionMenuRoomID: RoomCell.ID?
    let onOpenCartDetails: (CartSection.ID) -> Void
    let onOpenDetails: (RoomCell.ID, RoomDetailsMode) -> Void
    let onOpenToggle: (RoomCell.ID) -> Void
    let onTaskToggle: (RoomTask, RoomCell.ID) -> Void
    let onVIPToggle: (RoomCell.ID) -> Void
    let onScheduleToggle: (RoomCell.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Label("Тележка \(cart.id)", systemImage: "circle.fill")
                    .labelStyle(.titleAndIcon)
                Spacer()
                Text(cart.building)
            }
            .font(.system(size: 30, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.bottom, 3)
            .contentShape(Rectangle())
            .onLongPressGesture {
                onOpenCartDetails(cart.id)
            }

            ForEach($cart.rooms) { $room in
                RoomCellView(
                    room: $room,
                    isActionMenuExpanded: expandedActionMenuRoomID == room.id,
                    onActionMenuToggle: {
                        expandedActionMenuRoomID = expandedActionMenuRoomID == room.id ? nil : room.id
                    },
                    onOpenNotes: { onOpenDetails(room.id, .text) },
                    onOpenVoice: { onOpenDetails(room.id, .voice) },
                    onOpenToggle: { onOpenToggle(room.id) },
                    onTaskToggle: { task in onTaskToggle(task, room.id) },
                    onVIPToggle: { onVIPToggle(room.id) },
                    onScheduleToggle: { onScheduleToggle(room.id) }
                )
            }
        }
        .padding(.horizontal, 5)
    }
}

#Preview {
    @Previewable @State var cart = WorkSessionStore.preview().carts[0]
    @Previewable @State var expanded: RoomCell.ID?
    return CartSummarySection(
        cart: $cart,
        expandedActionMenuRoomID: $expanded,
        onOpenCartDetails: { _ in },
        onOpenDetails: { _, _ in },
        onOpenToggle: { _ in },
        onTaskToggle: { _, _ in },
        onVIPToggle: { _ in },
        onScheduleToggle: { _ in }
    )
        .background(OceanKeyTheme.background)
}
