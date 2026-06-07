import SwiftUI

struct RoomCellView: View {
    @Binding var room: RoomCell
    let isActionMenuExpanded: Bool
    let onActionMenuToggle: () -> Void
    let onOpenNotes: () -> Void
    let onOpenVoice: () -> Void
    let onOpenMedia: () -> Void
    let onOpenToggle: () -> Void
    let onTaskToggle: (RoomTask) -> Void
    let onVIPToggle: () -> Void
    let onScheduleToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            tileBody

            if isActionMenuExpanded {
                SummaryRoomActionMenu(
                    room: room,
                    onNotes: onOpenNotes,
                    onVoice: onOpenVoice,
                    onMedia: onOpenMedia,
                    onVIPToggle: onVIPToggle,
                    onScheduleToggle: onScheduleToggle
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.smooth(duration: 0.26), value: isActionMenuExpanded)
        .gesture(
            DragGesture(minimumDistance: 24, coordinateSpace: .local)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) * 1.35 else { return }
                    if value.translation.width > 56 {
                        onActionMenuToggle()
                    }
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Room \(room.id)")
    }

    private var tileBody: some View {
        HStack(spacing: 6) {
            Button(action: onOpenToggle) {
                Text(room.id)
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(OceanKeyTheme.roomForeground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            ForEach(RoomTask.allCases) { taskButton($0) }
        }
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .frame(height: 66)
        .foregroundStyle(OceanKeyTheme.roomForeground)
        .background(cellBackground)
        .clipShape(tileShape)
        .overlay(alignment: .topTrailing) {
            if room.isVIP {
                VIPPulseOverlay()
                    .clipShape(tileShape)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if let scheduleLabel = room.scheduleLabel {
                Text(scheduleLabel)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.72))
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 8,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: isActionMenuExpanded ? 0 : 13,
                            topTrailingRadius: 0,
                            style: .continuous
                        )
                    )
            }
        }
        .onLongPressGesture(perform: onVIPToggle)
    }

    private func taskButton(_ task: RoomTask) -> some View {
        Button(action: { onTaskToggle(task) }) {
            Text(task.rawValue)
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(taskColor(task))
                .frame(width: 50, height: 54)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!room.opened)
    }

    private var cellBackground: some View {
        tileShape
            .fill(OceanKeyTheme.fill(for: room.status))
            .shadow(color: .black.opacity(0.23), radius: 5, x: 0, y: 4)
    }

    private var tileShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 13,
            bottomLeadingRadius: isActionMenuExpanded ? 0 : 13,
            bottomTrailingRadius: isActionMenuExpanded ? 0 : 13,
            topTrailingRadius: 13,
            style: .continuous
        )
    }

    private func taskColor(_ task: RoomTask) -> Color {
        guard room.opened else { return OceanKeyTheme.roomForeground.opacity(0.25) }
        return room.completedTasks.contains(task) ? OceanKeyTheme.roomForeground : OceanKeyTheme.roomForeground.opacity(0.32)
    }
}

private extension RoomCell {
    var scheduleLabel: String? {
        guard let scheduledTime else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: scheduledTime)
    }
}

#Preview {
    @Previewable @State var room = WorkSessionStore.preview().carts[0].rooms[0]
    return RoomCellView(
        room: $room,
        isActionMenuExpanded: true,
        onActionMenuToggle: {},
        onOpenNotes: {},
        onOpenVoice: {},
        onOpenMedia: {},
        onOpenToggle: {},
        onTaskToggle: { _ in },
        onVIPToggle: {},
        onScheduleToggle: {}
    )
        .padding()
        .background(OceanKeyTheme.background)
}
