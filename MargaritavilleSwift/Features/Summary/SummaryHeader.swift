import SwiftUI

struct SummaryHeader: View {
    struct StatusChip: Identifiable, Equatable {
        let status: RoomStatus
        let count: Int
        let usesPurpleScheduled: Bool

        var id: RoomStatus { status }
    }

    let counts: SummaryCounts
    var progressLabel: String?
    var statusChips: [StatusChip] = []
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
        if let progressLabel, !statusChips.isEmpty {
            HStack(spacing: 6) {
                Text(progressLabel)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                ForEach(statusChips) { chip in
                    Text("\(chip.count)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.black)
                        .frame(minWidth: 24, minHeight: 22)
                        .background(OceanKeyTheme.fill(
                            for: chip.status,
                            usesPurpleScheduled: chip.usesPurpleScheduled
                        ))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.62)
        } else {
            HStack(spacing: 12) {
                Text("\(counts.total)").foregroundStyle(OceanKeyTheme.pending)
                Text("\(counts.completed)").foregroundStyle(OceanKeyTheme.ready)
                Text("\(counts.remaining)").foregroundStyle(Color(hex: 0xFF4A4A))
            }
            .font(.system(size: 22, weight: .black, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
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
