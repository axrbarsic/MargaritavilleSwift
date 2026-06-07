import SwiftUI

struct SettingsPanel<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(subtitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 2)

            VStack(spacing: 10) {
                content
            }
        }
    }
}

struct SettingsInfoRow: View {
    @Environment(\.experimentalLiquidGlassEnabled) private var liquidGlassEnabled

    let title: String
    let value: String
    let systemName: String
    let subtitle: String?

    init(title: String, value: String, systemName: String, subtitle: String? = nil) {
        self.title = title
        self.value = value
        self.systemName = systemName
        self.subtitle = subtitle
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .black))
                .frame(width: 34, height: 34)
                .foregroundStyle(OceanKeyTheme.accent)
                .background(OceanKeyTheme.accent.opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(OceanKeyTheme.secondaryText.opacity(0.82))
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }
            }

            Spacer(minLength: 12)

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(minHeight: 54)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(OceanKeyTheme.surface.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(OceanKeyTheme.accent.opacity(0.18), lineWidth: 1)
        }
        .experimentalLiquidGlass(enabled: liquidGlassEnabled, cornerRadius: 18, interactive: false)
    }
}

struct SettingsSliderRow: View {
    @Environment(\.experimentalLiquidGlassEnabled) private var liquidGlassEnabled

    let title: String
    let valueLabel: String
    let systemName: String
    let range: ClosedRange<Double>
    let defaultValue: Double
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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

                Text(valueLabel)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

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
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(OceanKeyTheme.surface.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(OceanKeyTheme.accent.opacity(0.18), lineWidth: 1)
        }
        .experimentalLiquidGlass(enabled: liquidGlassEnabled, cornerRadius: 18, interactive: true)
    }

    private var canReset: Bool {
        abs(value - defaultValue) > 0.001
    }

    private func reset() {
        value = defaultValue
    }
}

private extension View {
    @ViewBuilder
    func experimentalLiquidGlass(enabled: Bool, cornerRadius: CGFloat, interactive: Bool) -> some View {
        if enabled {
            if #available(iOS 26.0, *) {
                let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                if interactive {
                    self.glassEffect(.regular.tint(OceanKeyTheme.accent.opacity(0.10)).interactive(), in: shape)
                } else {
                    self.glassEffect(.regular.tint(OceanKeyTheme.accent.opacity(0.08)), in: shape)
                }
            } else {
                self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
        } else {
            self
        }
    }
}
