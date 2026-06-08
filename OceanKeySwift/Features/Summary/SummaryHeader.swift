import SwiftUI

struct SummaryHeader: View {
    let counts: SummaryCounts
    let onOpenSettings: () -> Void
    let onOpenSelection: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            softButton(systemName: "line.3.horizontal", action: onOpenSettings)

            Spacer(minLength: 8)

            HStack(spacing: 12) {
                Text("\(counts.total)").foregroundStyle(OceanKeyTheme.pending)
                Text("\(counts.completed)").foregroundStyle(OceanKeyTheme.ready)
                Text("\(counts.remaining)").foregroundStyle(Color(hex: 0xFF4A4A))
            }
            .font(.system(size: 22, weight: .black, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Spacer(minLength: 8)

            SummarySelectionPuzzleHandle(
                onComplete: onOpenSelection
            )
        }
        .frame(height: 48)
        .padding(.horizontal, 18)
    }

    private func softButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .black))
                .frame(width: 48, height: 48)
                .foregroundStyle(OceanKeyTheme.secondaryText)
                .background(.black.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(OceanKeyTheme.accent.opacity(0.16), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
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
