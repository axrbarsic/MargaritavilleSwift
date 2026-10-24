import SwiftUI

/// Настройки фона «Камера»: какая камера, какой эффект и ползунки эффекта.
/// Показываются только ползунки, которые меняют выбранный эффект.
struct CameraEffectControls: View {
    @Environment(\.interactionFeedback) private var feedback
    @AppStorage(CameraBackgroundEffect.storageKey) private var effect: CameraBackgroundEffect = .normal
    @AppStorage(CameraBackgroundPosition.storageKey) private var position: CameraBackgroundPosition = .back
    @AppStorage(CameraEffectTuning.Keys.amount) private var amount = CameraEffectTuning.default.amount
    @AppStorage(CameraEffectTuning.Keys.brightness) private var brightness = CameraEffectTuning.default.brightness
    @AppStorage(CameraEffectTuning.Keys.reliefDepth) private var reliefDepth = CameraEffectTuning.default.reliefDepth
    @AppStorage(CameraEffectTuning.Keys.lightAngle) private var lightAngle = CameraEffectTuning.default.lightAngle
    @AppStorage(CameraEffectTuning.Keys.edgeSensitivity) private var edgeSensitivity = CameraEffectTuning.default.edgeSensitivity
    @AppStorage(CameraEffectTuning.Keys.detailScale) private var detailScale = CameraEffectTuning.default.detailScale
    @AppStorage(CameraEffectTuning.Keys.metalHue) private var metalHue = CameraEffectTuning.default.metalHue
    @AppStorage(CameraEffectTuning.Keys.metalSaturation) private var metalSaturation = CameraEffectTuning.default.metalSaturation
    @AppStorage(CameraEffectTuning.Keys.liveLight) private var liveLight = CameraEffectTuning.default.liveLight
    @AppStorage(CameraEffectTuning.Keys.glowAmount) private var glowAmount = CameraEffectTuning.default.glowAmount

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Камера", selection: $position) {
                ForEach(CameraBackgroundPosition.allCases) { position in
                    Text(position.title).tag(position)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: position) { _, _ in feedback.confirm() }

            CameraEffectPicker(effect: $effect)

            SettingsInfoRow(
                title: "Эффект камеры",
                value: effect.title,
                systemName: "camera.filters",
                subtitle: effect.subtitle
            )

            if effect != .normal {
                slider("Сила эффекта", percent(amount), "slider.horizontal.3", CameraEffectTuning.amountRange, CameraEffectTuning.default.amount, $amount)
            }
            slider("Яркость", percent(brightness), "sun.max.fill", CameraEffectTuning.brightnessRange, CameraEffectTuning.default.brightness, $brightness)
            if effect.usesMetalColor {
                slider("Цвет металла", "\(CameraEffectTuning.metalName(hue: metalHue, saturation: metalSaturation)) · \(Int(metalHue.rounded()))°", "paintpalette.fill", CameraEffectTuning.metalHueRange, CameraEffectTuning.default.metalHue, $metalHue)
                slider("Насыщенность металла", metalSaturation < 0.12 ? "серебро" : percent(metalSaturation), "drop.fill", CameraEffectTuning.metalSaturationRange, CameraEffectTuning.default.metalSaturation, $metalSaturation)
            }
            if effect.usesRelief {
                slider("Глубина рельефа", multiplier(reliefDepth), "mountain.2.fill", CameraEffectTuning.reliefDepthRange, CameraEffectTuning.default.reliefDepth, $reliefDepth)
                Toggle(isOn: $liveLight) {
                    Label("Свет по кругу", systemImage: "rays")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                .tint(OceanKeyTheme.accent)
                .onChange(of: liveLight) { _, _ in feedback.confirm() }
                if !liveLight {
                    slider("Направление света", "\(Int(lightAngle.rounded()))°", "light.max", CameraEffectTuning.lightAngleRange, CameraEffectTuning.defaultLightAngle, $lightAngle)
                }
            }
            if effect.usesGlow {
                slider("Ореол", percent(glowAmount), "sparkles", CameraEffectTuning.glowAmountRange, CameraEffectTuning.default.glowAmount, $glowAmount)
            }
            if effect.usesEdges {
                slider("Чувствительность контуров", multiplier(edgeSensitivity), "scribble.variable", CameraEffectTuning.edgeSensitivityRange, CameraEffectTuning.default.edgeSensitivity, $edgeSensitivity)
            }
            if effect.usesDetailScale {
                slider("Размер элементов", multiplier(detailScale), "square.grid.3x3.fill", CameraEffectTuning.detailScaleRange, CameraEffectTuning.default.detailScale, $detailScale)
            }

            Button(action: reset) {
                Label("Сбросить настройки эффекта", systemImage: "arrow.counterclockwise")
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

    private var tuning: CameraEffectTuning {
        CameraEffectTuning(
            amount: amount,
            brightness: brightness,
            reliefDepth: reliefDepth,
            lightAngle: lightAngle,
            edgeSensitivity: edgeSensitivity,
            detailScale: detailScale,
            metalHue: metalHue,
            metalSaturation: metalSaturation,
            liveLight: liveLight,
            glowAmount: glowAmount
        )
    }

    private var canReset: Bool { tuning != .default }

    private func reset() {
        let defaults = CameraEffectTuning.default
        amount = defaults.amount
        brightness = defaults.brightness
        reliefDepth = defaults.reliefDepth
        lightAngle = defaults.lightAngle
        edgeSensitivity = defaults.edgeSensitivity
        detailScale = defaults.detailScale
        metalHue = defaults.metalHue
        metalSaturation = defaults.metalSaturation
        liveLight = defaults.liveLight
        glowAmount = defaults.glowAmount
        feedback.confirm()
    }

    private func slider(
        _ title: String,
        _ label: String,
        _ icon: String,
        _ range: ClosedRange<Double>,
        _ defaultValue: Double,
        _ value: Binding<Double>
    ) -> some View {
        SettingsSliderRow(
            title: title,
            valueLabel: label,
            systemName: icon,
            range: range,
            defaultValue: defaultValue,
            value: value
        )
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func multiplier(_ value: Double) -> String {
        String(format: "%.2f×", value)
    }
}
