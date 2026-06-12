import SwiftUI

struct MargaritavilleSummarySection: View {
    @Binding var cart: CartSection
    let territories: [Territory]
    let statusPaletteSaturation: Double
    let onAdvance: (RoomCell.ID) -> Void
    let onOpenDetails: (RoomCell.ID, RoomDetailsMode) -> Void
    let onVIPToggle: (RoomCell.ID) -> Void
    let onReset: (RoomCell.ID) -> Void
    let onSchedule: (RoomCell.ID) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 4
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(roomGroups) { group in
                roomGroup(group)
            }
        }
        .padding(.vertical, 8)
    }

    private func roomGroup(_ group: MargaritavilleSummaryRoomGroup) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            groupHeader(group)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(group.rooms) { room in
                    tile(for: room)
                }
            }
        }
    }

    private func groupHeader(_ group: MargaritavilleSummaryRoomGroup) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Тележка \(cart.id)")
            Spacer()
            Text(group.label)
            Text("\(group.rooms.count)")
                .monospacedDigit()
                .foregroundStyle(OceanKeyTheme.secondaryText)
        }
        .font(.system(size: 22, weight: .black, design: .rounded))
        .foregroundStyle(.white)
        .padding(.horizontal, 4)
    }

    private func tile(for room: RoomCell) -> some View {
        MargaritavilleRoomTile(
            room: room,
            statusPaletteSaturation: statusPaletteSaturation,
            onAdvance: { onAdvance(room.id) },
            onOpenDetails: { mode in onOpenDetails(room.id, mode) },
            onVIPToggle: { onVIPToggle(room.id) },
            onReset: { onReset(room.id) },
            onSchedule: { onSchedule(room.id) }
        )
    }

    private var roomGroups: [MargaritavilleSummaryRoomGroup] {
        MargaritavilleSummaryRoomGrouping.groups(
            rooms: cart.rooms,
            territories: territories,
            fallbackLabel: cart.building
        )
    }
}

private struct MargaritavilleRoomTile: View {
    let room: RoomCell
    let statusPaletteSaturation: Double
    let onAdvance: () -> Void
    let onOpenDetails: (RoomDetailsMode) -> Void
    let onVIPToggle: () -> Void
    let onReset: () -> Void
    let onSchedule: () -> Void
    @Environment(\.interactionFeedback) private var feedback
    @Environment(\.experimentalVIPJellyEnabled) private var experimentalVIPJellyEnabled
    @Environment(\.experimentalVIPJellySpeed) private var experimentalVIPJellySpeed

    var body: some View {
        tileBody
            .contextMenu {
                Button("Голос/медиа", systemImage: "mic.and.signal.meter.fill") {
                    feedback.tap()
                    onOpenDetails(.voice)
                }
                Button(room.isVIP ? "VIP выключить" : "VIP включить", systemImage: room.isVIP ? "crown.fill" : "diamond.fill") {
                    feedback.confirm()
                    onVIPToggle()
                }
                Button("Назначить время", systemImage: "clock.fill") {
                    feedback.tap()
                    onSchedule()
                }
                if room.status(in: .simpleCycle) == .ready {
                    Button("Вернуть в жёлтый", systemImage: "arrow.counterclockwise") {
                        feedback.deselect()
                        onReset()
                    }
                }
            }
    }

    @ViewBuilder
    private var tileBody: some View {
        if vipJellyActive {
            TimelineView(.animation(minimumInterval: 1.0 / 120.0)) { timeline in
                tileBodyContent(vipJellyTime: timeline.date.timeIntervalSinceReferenceDate)
            }
        } else {
            tileBodyContent(vipJellyTime: nil)
        }
    }

    private func tileBodyContent(vipJellyTime: TimeInterval?) -> some View {
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
            .overlay(alignment: .topTrailing) {
                RoomMediaIndicator(room: room)
                    .padding(6)
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .topLeading) {
                if room.isVIP {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 25, height: 25)
                        .background(OceanKeyTheme.pending.opacity(0.92), in: Circle())
                        .shadow(color: .black.opacity(0.28), radius: 3, x: 0, y: 1)
                        .padding(6)
                        .allowsHitTesting(false)
                }
            }
            .roomCellStaticClip(enabled: !vipJellyActive, shape: tileShape)
            .vipJellyUnifiedLayer(
                enabled: vipJellyActive,
                time: vipJellyTime,
                speed: experimentalVIPJellySpeed,
                seed: vipJellySeed,
                cornerRadius: tileCornerRadius
            )
            .vipJellyShapeMask(
                enabled: vipJellyActive,
                time: vipJellyTime,
                speed: experimentalVIPJellySpeed,
                seed: vipJellySeed,
                cornerRadius: tileCornerRadius,
                isMenuExpanded: false
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var fill: some View {
        let color = OceanKeyTheme.fill(
            for: room.status(in: .simpleCycle),
            saturation: statusPaletteSaturation,
            usesPurpleScheduled: true
        )
        if vipJellyActive {
            Rectangle().fill(color)
        } else {
            tileShape.fill(color)
        }
    }

    private var tileShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: tileCornerRadius,
            bottomLeadingRadius: tileCornerRadius,
            bottomTrailingRadius: tileCornerRadius,
            topTrailingRadius: tileCornerRadius,
            style: .continuous
        )
    }

    private var tileCornerRadius: CGFloat {
        16
    }

    private var timeLabel: String {
        let date = room.status(in: .simpleCycle) == .scheduled
            ? room.scheduledTime
            : (room.statusChangedAt ?? room.timeline.selectedAt)
        return date.map(margaritavilleTimeFormatter.string(from:)) ?? "--"
    }

    private var vipJellyActive: Bool {
        room.isVIP && experimentalVIPJellyEnabled
    }

    private var vipJellySeed: Double {
        Double(abs(room.id.hashValue % 10_000)) / 10_000
    }
}

private let margaritavilleTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "h:mm a"
    return formatter
}()
