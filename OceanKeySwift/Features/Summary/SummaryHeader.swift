import SwiftUI

struct SummaryHeader: View {
    let counts: SummaryCounts

    var body: some View {
        HStack(spacing: 8) {
            softButton(systemName: "line.3.horizontal")

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

            puzzleHandle
        }
        .frame(height: 48)
        .padding(.horizontal, 18)
    }

    private func softButton(systemName: String) -> some View {
        Button(action: {}) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .black))
                .frame(width: 48, height: 48)
                .foregroundStyle(OceanKeyTheme.secondaryText)
                .background(OceanKeyTheme.surface.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(OceanKeyTheme.accent.opacity(0.22), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var puzzleHandle: some View {
        HStack(spacing: 8) {
            Image(systemName: "puzzlepiece.extension.fill")
                .foregroundStyle(OceanKeyTheme.accent.opacity(0.55))
                .frame(width: 33, height: 33)
                .background(OceanKeyTheme.accent.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Image(systemName: "puzzlepiece.fill")
                .foregroundStyle(OceanKeyTheme.secondaryText)
                .frame(width: 33, height: 33)
                .background(OceanKeyTheme.surface.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(.horizontal, 8)
        .frame(width: 86, height: 42)
        .background(OceanKeyTheme.surface.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(OceanKeyTheme.accent.opacity(0.22), lineWidth: 1)
        }
    }
}

#Preview {
    SummaryHeader(counts: SummaryCounts(total: 10, completed: 10, remaining: 0))
        .background(OceanKeyTheme.background)
}
