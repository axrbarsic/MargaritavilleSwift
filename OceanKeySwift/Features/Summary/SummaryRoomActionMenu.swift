import SwiftUI

struct SummaryRoomActionMenu: View {
    let room: RoomCell
    let onNotes: () -> Void
    let onVoice: () -> Void
    let onVIPToggle: () -> Void
    let onScheduleToggle: () -> Void

    private var fillColor: Color {
        OceanKeyTheme.fill(for: room.status)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                actionButton(systemName: "book.pages.fill", title: "Заметки", action: onNotes)
                actionButton(systemName: "mic.fill", title: "Голос", action: onVoice)
                actionButton(
                    systemName: room.isVIP ? "crown.fill" : "diamond.fill",
                    title: "VIP",
                    selected: room.isVIP,
                    action: onVIPToggle
                )
                actionButton(
                    systemName: "clock.fill",
                    title: room.scheduleLabel ?? "Время",
                    selected: room.scheduledTime != nil,
                    action: onScheduleToggle
                )
                actionButton(systemName: "ellipsis", title: nil, enabled: false, action: {})
                    .frame(width: 58)
            }

            RoomTimelineStrip(room: room)
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .frame(height: 132)
        .foregroundStyle(OceanKeyTheme.roomForeground)
        .background(fillColor)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 13,
                bottomTrailingRadius: 13,
                topTrailingRadius: 0,
                style: .continuous
            )
        )
        .overlay {
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 13,
                bottomTrailingRadius: 13,
                topTrailingRadius: 0,
                style: .continuous
            )
            .stroke(.black.opacity(0.18), lineWidth: 1)
        }
    }

    private func actionButton(
        systemName: String,
        title: String?,
        selected: Bool = false,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemName)
                    .font(.system(size: 22, weight: .black))
                if let title {
                    Text(title)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .foregroundStyle(enabled ? OceanKeyTheme.roomForeground : OceanKeyTheme.roomForeground.opacity(0.35))
            .background(selected ? OceanKeyTheme.pending.opacity(0.92) : .black.opacity(enabled ? 0.10 : 0.045))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.black.opacity(selected ? 0.34 : 0.18), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

private struct RoomTimelineStrip: View {
    let room: RoomCell

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                let chips = chipLabels
                if chips.isEmpty {
                    chip("...")
                } else {
                    ForEach(chips, id: \.self) { label in
                        chip(label)
                    }
                }
            }
            .frame(height: 36)
        }
    }

    private var chipLabels: [String] {
        var labels = room.timeline.visibleMilestones.map { "\($0.0) \(timeLabel($0.1))" }
        if let scheduleLabel = room.scheduleLabel {
            labels.append("P \(scheduleLabel)")
        }
        return labels
    }

    private func chip(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(OceanKeyTheme.roomForeground.opacity(0.86))
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(.black.opacity(0.10))
            .clipShape(Capsule())
            .overlay {
                Capsule().stroke(.black.opacity(0.18), lineWidth: 1)
            }
    }

    private func timeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
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

