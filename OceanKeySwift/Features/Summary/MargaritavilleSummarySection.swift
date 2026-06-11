import SwiftUI

struct MargaritavilleSummarySection: View {
    @Binding var cart: CartSection
    let statusPaletteSaturation: Double
    let onAdvance: (RoomCell.ID) -> Void
    let onReset: (RoomCell.ID) -> Void
    let onSchedule: (RoomCell.ID) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 4
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text(cart.building)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                Spacer()
                Text("\(cart.rooms.count)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach($cart.rooms) { $room in
                    MargaritavilleRoomTile(
                        room: room,
                        statusPaletteSaturation: statusPaletteSaturation,
                        onAdvance: { onAdvance(room.id) },
                        onReset: { onReset(room.id) },
                        onSchedule: { onSchedule(room.id) }
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private struct MargaritavilleRoomTile: View {
    let room: RoomCell
    let statusPaletteSaturation: Double
    let onAdvance: () -> Void
    let onReset: () -> Void
    let onSchedule: () -> Void
    @Environment(\.interactionFeedback) private var feedback

    var body: some View {
        Button {
            feedback.confirm()
            onAdvance()
        } label: {
            VStack(spacing: 4) {
                Text(room.id)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                Text(timeLabel)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
            }
            .foregroundStyle(OceanKeyTheme.roomForeground)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Назначить время", systemImage: "clock.fill", action: onSchedule)
            if room.status(in: .simpleCycle) == .ready {
                Button("Вернуть в жёлтый", systemImage: "arrow.counterclockwise", action: onReset)
            }
        }
    }

    private var fill: Color {
        OceanKeyTheme.fill(
            for: room.status(in: .simpleCycle),
            saturation: statusPaletteSaturation,
            usesPurpleScheduled: true
        )
    }

    private var timeLabel: String {
        let date = room.status(in: .simpleCycle) == .scheduled
            ? room.scheduledTime
            : (room.statusChangedAt ?? room.timeline.selectedAt)
        return date.map(margaritavilleTimeFormatter.string(from:)) ?? "--"
    }
}

private let margaritavilleTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "h:mm a"
    return formatter
}()
