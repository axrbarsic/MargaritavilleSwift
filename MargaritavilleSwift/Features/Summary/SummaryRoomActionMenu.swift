import SwiftUI

struct SummaryRoomActionMenu: View {
    @Environment(\.interactionFeedback) private var feedback

    let room: RoomCell
    let onMultimodalNote: () -> Void
    let onVIPToggle: () -> Void
    let onScheduleToggle: () -> Void

    private var fillColor: Color {
        OceanKeyTheme.fill(for: room.status)
    }

    var body: some View {
        HStack(spacing: 7) {
            actionButton(systemName: "mic.and.signal.meter.fill", title: "Голос/медиа", action: onMultimodalNote)
            actionButton(
                systemName: room.isVIP ? "crown.fill" : "diamond.fill",
                title: "VIP",
                selected: room.isVIP,
                action: onVIPToggle
            )
            actionButton(
                systemName: "clock.fill",
                title: "Время",
                selected: room.scheduledTime != nil,
                action: onScheduleToggle
            )
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .frame(height: 86)
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
        Button(action: {
            playButtonFeedback(selected: selected, enabled: enabled)
            action()
        }) {
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

    private func playButtonFeedback(selected: Bool, enabled: Bool) {
        guard enabled else {
            feedback.invalid()
            return
        }
        if selected {
            feedback.deselect()
        } else {
            feedback.tap()
        }
    }
}
