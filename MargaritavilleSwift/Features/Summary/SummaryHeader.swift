import SwiftUI

struct SummaryHeader: View {
    struct StatusChip: Identifiable, Equatable {
        let status: RoomStatus
        let count: Int
        let usesPurpleScheduled: Bool

        var id: RoomStatus { status }
    }

    let counts: SummaryCounts
    var statusChips: [StatusChip] = []
    var activeStatusFilter: RoomStatus? = nil
    var onStatusFilterChanged: ((RoomStatus?) -> Void)? = nil
    let onOpenSettings: () -> Void
    let onOpenSelection: () -> Void
    @Environment(\.interactionFeedback) private var feedback

    var body: some View {
        HStack(spacing: 12) {
            headerIconButton(
                systemName: "line.3.horizontal",
                accessibilityLabel: "Открыть настройки",
                action: onOpenSettings
            )

            Spacer(minLength: 8)

            centerStats
                .frame(maxWidth: .infinity)

            Spacer(minLength: 8)

            headerIconButton(
                systemName: "square.grid.3x3",
                accessibilityLabel: "Открыть выбор комнат",
                action: openSelection
            )
        }
        .padding(.horizontal, 18)
        .frame(height: 48)
    }

    private func headerIconButton(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 23, weight: .black))
                .frame(width: 48, height: 48)
                .foregroundStyle(OceanKeyTheme.secondaryText)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private func openSelection() {
        feedback.confirm()
        onOpenSelection()
    }

    @ViewBuilder
    private var centerStats: some View {
        HStack(spacing: statusChips.isEmpty ? 12 : 7) {
            progressCount("\(counts.total)", color: OceanKeyTheme.pending)
            progressCount("\(counts.completed)", color: OceanKeyTheme.ready)
            progressCount("\(counts.remaining)", color: Color(hex: 0xFF3B30))

            if !statusChips.isEmpty {
                ForEach(statusChips) { chip in
                    statusChipButton(chip)
                }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.58)
    }

    private func progressCount(_ value: String, color: Color) -> some View {
        Text(value)
            .font(.system(size: 25, weight: .black, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(color)
            .shadow(color: .black.opacity(0.82), radius: 1.4, x: 0, y: 1)
            .frame(minWidth: 26)
    }

    private func statusChipButton(_ chip: StatusChip) -> some View {
        let isActive = activeStatusFilter == chip.status
        let fill = OceanKeyTheme.fill(
            for: chip.status,
            usesPurpleScheduled: chip.usesPurpleScheduled
        )
        return Button {
            feedback.tap()
            onStatusFilterChanged?(isActive ? nil : chip.status)
        } label: {
            Text("\(chip.count)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.black)
                .frame(minWidth: 38, minHeight: 34)
                .background(fill.opacity(activeStatusFilter == nil || isActive ? 1 : 0.48))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isActive ? .white.opacity(0.9) : .clear, lineWidth: 2)
                }
        }
        .buttonStyle(.plain)
        .disabled(onStatusFilterChanged == nil)
    }

}

#Preview {
    SummaryHeader(
        counts: SummaryCounts(total: 10, completed: 10, remaining: 0),
        onOpenSettings: {},
        onOpenSelection: {}
    )
        .background(OceanKeyTheme.background)
}
