import SwiftUI

struct MargaritavilleRoomZoomOverlay: View {
    let room: RoomCell
    let namespace: Namespace.ID
    let statusPaletteSaturation: Double
    let phase: RoomCommandCenterPhase
    let onSelectStatus: (RoomStatus) -> Void
    let onToggleVIP: () -> Void
    let onOpenSchedule: () -> Void
    let onOpenDetails: (RoomDetailsMode) -> Void
    let onCollapse: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .opacity(0.56)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onCollapse)

            commandCenter
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Командный центр комнаты \(room.id)")
    }

    private var commandCenter: some View {
        VStack(spacing: 12) {
            roomHeader

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    statusSection
                    vipAndTimeSection
                    roomFlowsSection
                }
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                fillColor
                LinearGradient(
                    colors: [.black.opacity(0.05), .black.opacity(0.42)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.24), lineWidth: 1)
        }
        .shadow(color: fillColor.opacity(0.46), radius: 36)
        .matchedGeometryEffect(id: room.id, in: namespace)
        .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .onTapGesture {}
    }

    private var roomHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(room.id)
                    .font(.system(
                        size: CGFloat(RoomCellTypography.production.roomNumberSize),
                        weight: RoomCellTypography.production.roomNumberWeight.fontWeight,
                        design: .rounded
                    ))
                    .monospacedDigit()
                    .offset(y: CGFloat(RoomCellTypography.production.roomNumberVerticalOffset))

                Text(timeLabel)
                    .font(.system(
                        size: CGFloat(RoomCellTypography.production.activationTimeSize),
                        weight: RoomCellTypography.production.activationTimeWeight.fontWeight,
                        design: .rounded
                    ))
                    .monospacedDigit()
                    .offset(y: CGFloat(RoomCellTypography.production.activationTimeVerticalOffset))
            }
            .foregroundStyle(OceanKeyTheme.roomForeground)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 7) {
                stateBadge(title: statusTitle, systemName: statusSystemName)
                if room.isVIP {
                    stateBadge(title: "VIP", systemName: "diamond.fill")
                }
                if room.attachmentIndicatorCount > 0 {
                    stateBadge(title: "Медиа \(room.attachmentIndicatorCount)", systemName: "paperclip")
                }
            }

            if controlsDisabled {
                ProgressView()
                    .tint(OceanKeyTheme.roomForeground)
                    .controlSize(.small)
            }
        }
        .frame(minHeight: 86)
    }

    private var statusSection: some View {
        commandSection(title: "Быстрый статус", subtitle: "Выбор применяется к живой комнате и закрывает центр после commit.") {
            LazyVGrid(columns: statusColumns, spacing: 8) {
                ForEach(commandStatuses, id: \.self) { status in
                    statusButton(status)
                }
            }
        }
    }

    private var vipAndTimeSection: some View {
        commandSection(title: "VIP и время", subtitle: scheduleStateLabel) {
            HStack(spacing: 8) {
                commandButton(
                    title: room.isVIP ? "VIP включён" : "Включить VIP",
                    systemName: room.isVIP ? "diamond.fill" : "diamond",
                    value: room.isVIP ? "Выключить" : nil,
                    action: onToggleVIP
                )

                commandButton(
                    title: room.scheduledTime == nil ? "Назначить время" : "Изменить время",
                    systemName: "clock.fill",
                    value: room.scheduledTime.map(commandCenterTimeFormatter.string(from:)),
                    action: onOpenSchedule
                )
            }
        }
    }

    private var roomFlowsSection: some View {
        commandSection(
            title: "Заметки и медиа",
            subtitle: "Capture и редакторы закрывают увеличенную ячейку только после успешного сохранения."
        ) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    flowButton(.voice, value: audioCount == 0 ? nil : "Аудио \(audioCount)")
                    flowButton(.media, value: visualMediaCount == 0 ? nil : "Файлов \(visualMediaCount)")
                }
                flowButton(.text, value: hasTextNote ? "Есть текст" : nil)
            }
        }
    }

    private func commandSection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            content()
        }
        .foregroundStyle(.white)
        .padding(12)
        .background(.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        }
    }

    private func statusButton(_ status: RoomStatus) -> some View {
        let isActive = room.status(in: .simpleCycle) == status
        return Button {
            if status == .scheduled {
                onOpenSchedule()
            } else {
                onSelectStatus(status)
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: status.commandSystemName)
                Text(status.commandTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Spacer(minLength: 2)
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            .font(.system(size: 14, weight: .black, design: .rounded))
            .foregroundStyle(OceanKeyTheme.roomForeground)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(statusColor(status))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isActive ? .white : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .disabled(controlsDisabled || (isActive && status != .scheduled))
    }

    private func flowButton(_ mode: RoomDetailsMode, value: String?) -> some View {
        commandButton(
            title: mode.commandTitle,
            systemName: mode.commandSystemName,
            value: value,
            action: { onOpenDetails(mode) }
        )
    }

    private func commandButton(
        title: String,
        systemName: String,
        value: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: systemName)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                    if let value {
                        Text(value)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.70))
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 2)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .black))
                    .opacity(0.68)
            }
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 11)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(controlsDisabled)
    }

    private func stateBadge(title: String, systemName: String) -> some View {
        Label(title, systemImage: systemName)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .frame(height: 25)
            .background(.black.opacity(0.42), in: Capsule())
    }

    private var controlsDisabled: Bool {
        phase != .idle
    }

    private var commandStatuses: [RoomStatus] {
        [.pending, .open, .ready, .scheduled]
    }

    private var statusColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
    }

    private var fillColor: Color {
        statusColor(room.status(in: .simpleCycle))
    }

    private func statusColor(_ status: RoomStatus) -> Color {
        OceanKeyTheme.fill(
            for: status,
            saturation: statusPaletteSaturation,
            usesPurpleScheduled: false
        )
    }

    private var statusTitle: String { room.status(in: .simpleCycle).commandTitle }
    private var statusSystemName: String { room.status(in: .simpleCycle).commandSystemName }

    private var timeLabel: String {
        let date = room.status(in: .simpleCycle) == .scheduled
            ? room.scheduledTime
            : (room.statusChangedAt ?? room.timeline.selectedAt)
        return date.map(commandCenterTimeFormatter.string(from:)) ?? "--"
    }

    private var scheduleStateLabel: String {
        guard let scheduledTime = room.scheduledTime else {
            return "Время не назначено. Штатный экран поддерживает назначение, изменение и очистку."
        }
        return "Назначено: \(commandCenterTimeFormatter.string(from: scheduledTime)). Нажми для изменения или очистки."
    }

    private var audioCount: Int {
        room.mediaAttachments?.filter { $0.kind == .audio }.count ?? 0
    }

    private var visualMediaCount: Int {
        room.mediaAttachments?.filter { $0.kind == .photo || $0.kind == .video }.count ?? 0
    }

    private var hasTextNote: Bool {
        room.textNote?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
}

private extension RoomStatus {
    var commandTitle: String {
        switch self {
        case .pending: "Жёлтый"
        case .open: "Красный"
        case .inProgress: "Синий"
        case .ready: "Зелёный"
        case .scheduled: "Розовый"
        }
    }

    var commandSystemName: String {
        switch self {
        case .pending: "arrow.counterclockwise"
        case .open: "door.left.hand.open"
        case .inProgress: "progress.indicator"
        case .ready: "checkmark"
        case .scheduled: "clock.fill"
        }
    }
}

private extension RoomDetailsMode {
    var commandTitle: String {
        switch self {
        case .text: "Текстовая заметка"
        case .voice: "Голос / аудио"
        case .media: "Фото, видео, галерея"
        }
    }

    var commandSystemName: String {
        switch self {
        case .text: "note.text"
        case .voice: "waveform"
        case .media: "photo.on.rectangle.angled"
        }
    }
}

private let commandCenterTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "h:mm a"
    return formatter
}()
