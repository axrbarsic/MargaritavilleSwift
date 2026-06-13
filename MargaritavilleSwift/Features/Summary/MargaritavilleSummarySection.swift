import SwiftUI

struct MargaritavilleSummarySection: View {
    let section: MargaritavilleSummaryHousekeeperSection
    let housekeeper: Housekeeper?
    let housekeeperDetailsGestureMode: HousekeeperDetailsGestureMode
    let statusPaletteSaturation: Double
    let onOpenCartDetails: (CartSection.ID, String) -> Void
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
            groupHeader
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(section.rooms) { room in
                    tile(for: room)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var groupHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            HousekeeperSummaryNameButton(
                title: housekeeper?.displayName ?? "Уборщица",
                palette: housekeeper?.palette.color ?? OceanKeyTheme.accent,
                gestureMode: housekeeperDetailsGestureMode,
                action: { onOpenCartDetails(section.primaryCartID, section.locationLabel) }
            )
            Spacer()
            Text(section.locationLabel)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.58)
        }
        .font(.system(size: 22, weight: .black, design: .rounded))
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
}

private struct HousekeeperSummaryNameButton: View {
    let title: String
    let palette: Color
    let gestureMode: HousekeeperDetailsGestureMode
    let action: () -> Void
    @Environment(\.interactionFeedback) private var feedback
    @State private var swipeOffset: CGFloat = 0

    var body: some View {
        Text(title)
            .font(.system(size: 25, weight: .black, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.62)
            .foregroundStyle(palette)
            .shadow(color: .black.opacity(0.92), radius: 1.6, x: 0, y: 1)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.black.opacity(0.34), in: Capsule())
            .background(palette.opacity(0.20), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(palette.opacity(0.72), lineWidth: 1.5)
            }
            .offset(x: swipeOffset)
            .contentShape(Rectangle())
            .onTapGesture {
                guard gestureMode == .tap else {
                    feedback.tap()
                    return
                }
                feedback.confirm()
                action()
            }
            .onLongPressGesture(minimumDuration: 0.38) {
                guard gestureMode == .longPress else { return }
                feedback.longPress()
                action()
            }
            .gesture(
                DragGesture(minimumDistance: 16)
                    .onChanged { value in
                        guard gestureMode == .swipeLeft else { return }
                        swipeOffset = min(0, max(-36, value.translation.width))
                    }
                    .onEnded { value in
                        guard gestureMode == .swipeLeft else {
                            swipeOffset = 0
                            return
                        }
                        if value.translation.width < -42 || value.predictedEndTranslation.width < -72 {
                            feedback.confirm()
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.78)) {
                                swipeOffset = -24
                            }
                            action()
                        }
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.74)) {
                            swipeOffset = 0
                        }
                    }
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(accessibilityHint)
    }

    private var accessibilityHint: String {
        switch gestureMode {
        case .tap: "Открывает меню уборщицы по тапу."
        case .longPress: "Открывает меню уборщицы по долгому нажатию."
        case .swipeLeft: "Открывает меню уборщицы свайпом справа налево."
        }
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
            VStack(spacing: 6) {
                Text(room.id)
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.50)
                Text(timeLabel)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            }
            .foregroundStyle(OceanKeyTheme.roomForeground)
            .padding(.horizontal, 6)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(fill)
            .overlay(alignment: .bottomTrailing) {
                RoomMediaIndicator(room: room)
                    .allowsHitTesting(false)
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
            usesPurpleScheduled: false
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
