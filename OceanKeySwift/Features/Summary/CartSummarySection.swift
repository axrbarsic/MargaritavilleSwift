import SwiftUI

struct CartSummarySection: View {
    @Environment(\.interactionFeedback) private var feedback

    @Binding var cart: CartSection
    let geometry: RoomCellGeometry
    let taskControlsUseLongPress: Bool
    let actionMenuAllowsMultiple: Bool
    @Binding var expandedActionMenuRoomIDs: Set<RoomCell.ID>
    let onOpenCartDetails: (CartSection.ID) -> Void
    let onOpenDetails: (RoomCell.ID, RoomDetailsMode) -> Void
    let onOpenToggle: (RoomCell.ID) -> Void
    let onTaskToggle: (RoomTask, RoomCell.ID) -> Void
    let onVIPToggle: (RoomCell.ID) -> Void
    let onScheduleToggle: (RoomCell.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: geometry.sectionSpacing) {
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
                feedback.longPress()
                onOpenCartDetails(cart.id)
            }

            ForEach($cart.rooms) { $room in
                RoomCellView(
                    room: $room,
                    geometry: geometry,
                    taskControlsUseLongPress: taskControlsUseLongPress,
                    isActionMenuExpanded: expandedActionMenuRoomIDs.contains(room.id),
                    onActionMenuToggle: {
                        expandedActionMenuRoomIDs = SummaryActionMenuExpansion.toggled(
                            roomID: room.id,
                            in: expandedActionMenuRoomIDs,
                            allowsMultiple: actionMenuAllowsMultiple
                        )
                    },
                    onOpenNotes: { onOpenDetails(room.id, .text) },
                    onOpenVoice: { onOpenDetails(room.id, .voice) },
                    onOpenMedia: { onOpenDetails(room.id, .media) },
                    onOpenToggle: { onOpenToggle(room.id) },
                    onTaskToggle: { task in onTaskToggle(task, room.id) },
                    onVIPToggle: { onVIPToggle(room.id) },
                    onScheduleToggle: { onScheduleToggle(room.id) }
                )
            }
        }
        .padding(.horizontal, geometry.sectionHorizontalPadding)
    }
}

#Preview {
    @Previewable @State var cart = WorkSessionStore.preview().carts[0]
    @Previewable @State var expanded: Set<RoomCell.ID> = []
    return CartSummarySection(
        cart: $cart,
        geometry: .roomy,
        taskControlsUseLongPress: true,
        actionMenuAllowsMultiple: false,
        expandedActionMenuRoomIDs: $expanded,
        onOpenCartDetails: { _ in },
        onOpenDetails: { _, _ in },
        onOpenToggle: { _ in },
        onTaskToggle: { _, _ in },
        onVIPToggle: { _ in },
        onScheduleToggle: { _ in }
    )
        .background(OceanKeyTheme.background)
}
