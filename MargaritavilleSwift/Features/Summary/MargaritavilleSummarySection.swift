import SwiftUI

struct MargaritavilleSummarySection: View {
    let section: MargaritavilleSummaryHousekeeperSection
    let housekeeper: Housekeeper?
    let consumableTickerText: String?
    let statusPaletteSaturation: Double
    let onOpenCartDetails: (CartSection.ID, String) -> Void
    let onAdvance: (RoomCell.ID) -> Void
    let onOpenDetails: (RoomCell.ID, RoomDetailsMode) -> Void
    let onVIPToggle: (RoomCell.ID) -> Void
    let onReset: (RoomCell.ID) -> Void
    let onSchedule: (RoomCell.ID) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 82, maximum: 98), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            groupHeader
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(section.rooms) { room in
                    tile(for: room)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    private var groupHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            HousekeeperSummaryNameButton(
                title: housekeeper?.displayName ?? "Уборщица",
                palette: housekeeper?.palette.color ?? OceanKeyTheme.accent,
                action: { onOpenCartDetails(section.primaryCartID, section.locationLabel) }
            )

            if let consumableTickerText, !consumableTickerText.isEmpty {
                SummaryConsumableTicker(text: consumableTickerText)
                    .frame(maxWidth: .infinity)
            } else {
                Spacer(minLength: 8)
            }

            Text(section.locationLabel)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.58)
        }
        .font(.system(size: 22, weight: .black, design: .rounded))
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
    let action: () -> Void
    @Environment(\.interactionFeedback) private var feedback

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
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 0.38) {
                feedback.longPress()
                action()
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Открывает меню уборщицы по долгому нажатию.")
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
    @State private var isActionDialogPresented = false
    @State private var actionSwipeArmed = false
    @State private var actionSwipeFeedbackStarted = false

    var body: some View {
        tileBody
            .simultaneousGesture(actionMenuSwipeGesture)
            .confirmationDialog("Комната \(room.id)", isPresented: $isActionDialogPresented, titleVisibility: .visible) {
                Button("Голос/медиа", systemImage: "mic.and.signal.meter.fill", action: openVoiceDetails)
                Button(room.isVIP ? "VIP выключить" : "VIP включить", systemImage: room.isVIP ? "diamond.fill" : "diamond", action: toggleVIP)
                Button("Назначить время", systemImage: "clock.fill", action: scheduleRoom)
                if room.status(in: .simpleCycle) == .ready {
                    Button("Вернуть в жёлтый", systemImage: "arrow.counterclockwise", action: resetRoom)
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
        HoldActionTarget(
            enabled: true,
            useLongPress: true,
            semanticLabel: "Комната \(room.id)",
            onActivate: onAdvance
        ) {
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
            .padding(.horizontal, 4)
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

    private var actionMenuSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 24, coordinateSpace: .local)
            .onChanged { value in
                updateActionSwipe(value)
            }
            .onEnded { value in
                finishActionSwipe(value)
            }
    }

    private func updateActionSwipe(_ value: DragGesture.Value) {
        let horizontal = abs(value.translation.width)
        let vertical = abs(value.translation.height)
        guard vertical <= 12 || horizontal > vertical * 2.4 else {
            resetActionSwipe()
            return
        }
        guard horizontal >= 36, horizontal > vertical * 2.4 else { return }
        if !actionSwipeFeedbackStarted {
            actionSwipeFeedbackStarted = true
            feedback.holdStart()
        }
        let nextArmed = horizontal >= 82
        if nextArmed, !actionSwipeArmed {
            feedback.holdCommit()
        } else if !nextArmed, horizontal >= 64, !actionSwipeArmed {
            feedback.holdWarning()
        }
        actionSwipeArmed = nextArmed
    }

    private func finishActionSwipe(_ value: DragGesture.Value) {
        defer { resetActionSwipe() }
        let horizontal = abs(value.translation.width)
        let predicted = abs(value.predictedEndTranslation.width)
        let vertical = abs(value.translation.height)
        guard actionSwipeArmed || (horizontal >= 72 && predicted >= 96 && horizontal > vertical * 2.2) else { return }
        feedback.confirm()
        isActionDialogPresented = true
    }

    private func resetActionSwipe() {
        actionSwipeArmed = false
        actionSwipeFeedbackStarted = false
    }

    private func openVoiceDetails() {
        feedback.tap()
        onOpenDetails(.voice)
    }

    private func toggleVIP() {
        feedback.confirm()
        onVIPToggle()
    }

    private func scheduleRoom() {
        feedback.tap()
        onSchedule()
    }

    private func resetRoom() {
        feedback.deselect()
        onReset()
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
