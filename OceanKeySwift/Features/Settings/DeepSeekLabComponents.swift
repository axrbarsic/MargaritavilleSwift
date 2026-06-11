import SwiftUI

struct DeepSeekPresetCard: View {
    let preset: AIVisualPresetDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(preset.kind.title, systemImage: preset.kind == .matrixCodeRain ? "terminal.fill" : "sparkle")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.accent)
                Spacer()
                Text("\(String(format: "%.2f", preset.payload.speed))x")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.secondaryText)
            }
            Text(preset.title)
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(preset.summary)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)
            Text("palette: \(preset.payload.palette), motion: \(preset.payload.motion)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(OceanKeyTheme.secondaryText.opacity(0.78))
                .lineLimit(2)
        }
        .padding(14)
        .background(OceanKeyTheme.surface.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(OceanKeyTheme.accent.opacity(0.18), lineWidth: 1)
        }
    }
}

struct SavedDeepSeekPresetRow: View {
    let preset: AIVisualPreset
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: preset.kind == .matrixCodeRain ? "terminal.fill" : "sparkle")
                .font(.system(size: 18, weight: .black))
                .frame(width: 34, height: 34)
                .foregroundStyle(OceanKeyTheme.accent)
                .background(OceanKeyTheme.accent.opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(preset.title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                Text(preset.summary)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.secondaryText.opacity(0.82))
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Text(preset.modelTier.title)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)

            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 15, weight: .black))
                    .frame(width: 34, height: 34)
                    .foregroundStyle(.yellow)
                    .background(.yellow.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(OceanKeyTheme.surface.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(OceanKeyTheme.accent.opacity(0.18), lineWidth: 1)
        }
    }
}

struct DeepSeekActionButtonLabel: View {
    let title: String
    let systemName: String
    var destructive = false

    var body: some View {
        Label(title, systemImage: systemName)
            .font(.system(size: 16, weight: .black, design: .rounded))
            .foregroundStyle(destructive ? .yellow : OceanKeyTheme.roomForeground)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(destructive ? OceanKeyTheme.surface.opacity(0.84) : OceanKeyTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke((destructive ? .yellow : OceanKeyTheme.accent).opacity(0.2), lineWidth: 1)
            }
    }
}
