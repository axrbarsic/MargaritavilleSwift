import BrooklynBackgroundKit
import SwiftUI

struct BrooklynAppearanceControls: View {
    @Bindable var appSettings: AppSettingsStore
    @Environment(\.interactionFeedback) private var feedback

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsInfoRow(
                title: "Вид Brooklyn",
                value: "Metal",
                systemName: "cube.fill",
                subtitle: "Размер, оттенок, яркость и контраст применяются к живой сцене сразу."
            )

            SettingsSliderRow(
                title: "Размер ячеек",
                valueLabel: "\(Int((appSettings.brooklynCellScale * 100).rounded()))%",
                systemName: "square.resize",
                range: BrooklynAppearance.cellScaleRange,
                defaultValue: BrooklynAppearance.default.cellScale,
                value: $appSettings.brooklynCellScale
            )

            BrooklynHueWheel(
                hue: $appSettings.brooklynHue,
                defaultHue: BrooklynAppearance.default.hue
            )

            SettingsSliderRow(
                title: "Яркость",
                valueLabel: "\(Int((appSettings.brooklynBrightness * 100).rounded()))%",
                systemName: "sun.max.fill",
                range: BrooklynAppearance.brightnessRange,
                defaultValue: BrooklynAppearance.default.brightness,
                value: $appSettings.brooklynBrightness
            )

            SettingsSliderRow(
                title: "Контраст",
                valueLabel: contrastLabel,
                systemName: "circle.lefthalf.filled",
                range: BrooklynAppearance.contrastRange,
                defaultValue: BrooklynAppearance.default.contrast,
                value: $appSettings.brooklynContrast
            )

            Button(action: resetAll) {
                Label("Сбросить вид Brooklyn", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(canReset ? OceanKeyTheme.accent : OceanKeyTheme.secondaryText.opacity(0.42))
                    .background(OceanKeyTheme.accent.opacity(canReset ? 0.14 : 0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canReset)
        }
    }

    private var canReset: Bool {
        appSettings.brooklynAppearance != .default
    }

    private var contrastLabel: String {
        let value = Int((appSettings.brooklynContrast * 100).rounded())
        return value > 0 ? "+\(value)%" : "\(value)%"
    }

    private func resetAll() {
        appSettings.resetBrooklynAppearance()
        feedback.confirm()
    }
}

private struct BrooklynHueWheel: View {
    @Binding var hue: Double
    let defaultHue: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 18, weight: .black))
                    .frame(width: 34, height: 34)
                    .foregroundStyle(Color(hue: hue, saturation: 0.92, brightness: 1))
                    .background(Color(hue: hue, saturation: 0.92, brightness: 1).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text("Оттенок")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Spacer(minLength: 12)

                Text("\(degrees)°")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.secondaryText)
            }

            GeometryReader { proxy in
                let diameter = min(proxy.size.width, proxy.size.height)
                let thumbRadius = max(0, diameter / 2 - 16)
                let angle = Angle.radians(hue * 2 * .pi)

                ZStack {
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red],
                                center: .center
                            )
                        )

                    Circle()
                        .fill(Color.black.opacity(0.22))
                        .frame(width: diameter * 0.42, height: diameter * 0.42)

                    Circle()
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)

                    Circle()
                        .fill(Color(hue: hue, saturation: 0.92, brightness: 1))
                        .frame(width: 24, height: 24)
                        .overlay {
                            Circle().stroke(Color.white, lineWidth: 3)
                        }
                        .shadow(color: .black.opacity(0.55), radius: 4, y: 2)
                        .offset(
                            x: CGFloat(cos(angle.radians)) * thumbRadius,
                            y: CGFloat(sin(angle.radians)) * thumbRadius
                        )
                }
                .frame(width: diameter, height: diameter)
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updateHue(at: value.location, diameter: diameter)
                        }
                )
                .accessibilityElement()
                .accessibilityLabel("Оттенок Brooklyn Web")
                .accessibilityValue("\(degrees) градусов")
                .accessibilityAdjustableAction(adjustHue)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
            .frame(height: 164)

            HStack {
                Text("0°")
                Spacer()
                Text("Проведите пальцем по кругу")
                Spacer()
                Text("360°")
            }
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(OceanKeyTheme.secondaryText.opacity(0.78))

            Button(action: reset) {
                Label("Вернуть розовый donor", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(canReset ? OceanKeyTheme.accent : OceanKeyTheme.secondaryText.opacity(0.42))
                    .background(OceanKeyTheme.accent.opacity(canReset ? 0.14 : 0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canReset)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(OceanKeyTheme.surface.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(OceanKeyTheme.accent.opacity(0.18), lineWidth: 1)
        }
    }

    private var degrees: Int {
        Int((hue * 360).rounded()) % 360
    }

    private var canReset: Bool {
        abs(hue - defaultHue) > 0.000_1
    }

    private func updateHue(at location: CGPoint, diameter: CGFloat) {
        let center = CGPoint(x: diameter / 2, y: diameter / 2)
        let radians = atan2(location.y - center.y, location.x - center.x)
        let normalized = radians >= 0 ? radians : radians + 2 * .pi
        hue = Double(normalized / (2 * .pi))
    }

    private func adjustHue(_ direction: AccessibilityAdjustmentDirection) {
        let step = 5.0 / 360.0
        switch direction {
        case .increment:
            hue = (hue + step).truncatingRemainder(dividingBy: 1)
        case .decrement:
            hue = (hue - step + 1).truncatingRemainder(dividingBy: 1)
        @unknown default:
            break
        }
    }

    private func reset() {
        hue = defaultHue
    }
}
