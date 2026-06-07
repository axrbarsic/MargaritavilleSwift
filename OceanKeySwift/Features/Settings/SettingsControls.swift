import SwiftUI

struct SettingsPanel<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 0) {
                content
            }
            .padding(14)
            .background(OceanKeyTheme.surface.opacity(0.84))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(OceanKeyTheme.accent.opacity(0.22), lineWidth: 1)
            }
        }
    }
}

struct SettingsInfoRow: View {
    let title: String
    let value: String
    let systemName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .black))
                .frame(width: 34, height: 34)
                .foregroundStyle(OceanKeyTheme.accent)
                .background(OceanKeyTheme.accent.opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(title)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Spacer(minLength: 12)

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(minHeight: 48)
    }
}

struct SettingsSliderRow: View {
    let title: String
    let valueLabel: String
    let systemName: String
    let range: ClosedRange<Double>
    let defaultValue: Double
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsInfoRow(title: title, value: valueLabel, systemName: systemName)

            HStack(spacing: 10) {
                Slider(value: $value, in: range)
                    .tint(OceanKeyTheme.accent)

                Button(action: reset) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .black))
                        .frame(width: 36, height: 36)
                        .foregroundStyle(canReset ? OceanKeyTheme.accent : OceanKeyTheme.secondaryText.opacity(0.42))
                        .background(OceanKeyTheme.accent.opacity(canReset ? 0.14 : 0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canReset)
            }
            .padding(.leading, 46)
            .padding(.bottom, 8)
        }
    }

    private var canReset: Bool {
        abs(value - defaultValue) > 0.001
    }

    private func reset() {
        value = defaultValue
    }
}
