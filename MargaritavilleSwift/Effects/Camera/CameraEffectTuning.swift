import Foundation

/// Пользовательская настройка эффектов камеры. Значения хранятся в
/// `@AppStorage` по ключам `Keys` и передаются в шейдер каждым кадром.
struct CameraEffectTuning: Equatable, Sendable {
    enum Keys {
        static let amount = "cameraEffectAmount"
        static let brightness = "cameraEffectBrightness"
        static let reliefDepth = "cameraReliefDepth"
        static let lightAngle = "cameraLightAngle"
        static let edgeSensitivity = "cameraEdgeSensitivity"
        static let detailScale = "cameraDetailScale"
        static let metalHue = "cameraMetalHue"
        static let metalSaturation = "cameraMetalSaturation"
        static let liveLight = "cameraLiveLight"
        static let glowAmount = "cameraGlowAmount"
    }

    static let amountRange = 0.0...1.0
    static let brightnessRange = 0.5...1.6
    static let reliefDepthRange = 0.25...3.0
    static let lightAngleRange = 0.0...360.0
    static let edgeSensitivityRange = 0.4...2.5
    static let detailScaleRange = 0.5...2.0
    static let metalHueRange = 0.0...360.0
    static let metalSaturationRange = 0.0...1.0
    static let glowAmountRange = 0.0...1.0

    /// Свет по умолчанию падает сверху слева (ось y направлена вниз).
    static let defaultLightAngle = 225.0
    static let `default` = CameraEffectTuning()

    var amount = 1.0
    var brightness = 1.0
    var reliefDepth = 1.0
    var lightAngle = defaultLightAngle
    var edgeSensitivity = 1.0
    var detailScale = 1.0
    /// Металл по умолчанию — золото.
    var metalHue = 42.0
    var metalSaturation = 0.75
    var liveLight = false
    var glowAmount = 0.5

    /// Значения, приведённые к допустимым диапазонам.
    var clamped: CameraEffectTuning {
        var result = self
        result.amount = Self.clamp(amount, Self.amountRange)
        result.brightness = Self.clamp(brightness, Self.brightnessRange)
        result.reliefDepth = Self.clamp(reliefDepth, Self.reliefDepthRange)
        result.lightAngle = Self.clamp(lightAngle, Self.lightAngleRange)
        result.edgeSensitivity = Self.clamp(edgeSensitivity, Self.edgeSensitivityRange)
        result.detailScale = Self.clamp(detailScale, Self.detailScaleRange)
        result.metalHue = Self.clamp(metalHue, Self.metalHueRange)
        result.metalSaturation = Self.clamp(metalSaturation, Self.metalSaturationRange)
        result.glowAmount = Self.clamp(glowAmount, Self.glowAmountRange)
        return result
    }

    /// Понятное имя металла под ползунком цвета.
    static func metalName(hue: Double, saturation: Double) -> String {
        if saturation < 0.12 { return "Серебро" }
        switch hue {
        case ..<20: return "Медь"
        case ..<50: return "Золото"
        case ..<75: return "Латунь"
        case ..<160: return "Зелёная патина"
        case ..<250: return "Синяя сталь"
        case ..<320: return "Фиолетовый титан"
        default: return "Розовое золото"
        }
    }

    private static func clamp(_ value: Double, _ range: ClosedRange<Double>) -> Double {
        guard value.isFinite else { return range.lowerBound }
        return min(max(value, range.lowerBound), range.upperBound)
    }
}

extension CameraBackgroundEffect {
    /// Рельефные эффекты: глубина, направление и движение света.
    var usesRelief: Bool {
        switch self {
        case .emboss, .metal, .periodicMetals, .stoneRelief, .paperRelief, .woodRelief: true
        default: false
        }
    }

    /// Эффекты на контурах: чувствительность выделения линий.
    var usesEdges: Bool {
        switch self {
        case .comic, .sketch, .cartoon, .neon, .neonShadow, .tron, .blueprint, .chalk, .electric: true
        default: false
        }
    }

    /// Эффекты с ячейками: размер пикселей, символов, кубиков и клеток.
    var usesDetailScale: Bool {
        switch self {
        case .grid, .pixels, .ascii, .dither, .halftone, .gameBoy, .lego, .sketch, .blueprint: true
        default: false
        }
    }

    var usesMetalColor: Bool { self == .metal }
    var usesGlow: Bool { self == .neon }
}

/// Перенос старых эффектов, объединённых в «Металл» и «Неон», на новые с
/// похожими настройками. Вызывается один раз при запуске приложения.
enum CameraEffectMigration {
    static func migrate(_ defaults: UserDefaults = .standard) {
        guard let stored = defaults.string(forKey: CameraBackgroundEffect.storageKey),
              CameraBackgroundEffect(rawValue: stored) == nil
        else { return }
        let keys = CameraEffectTuning.Keys.self
        var effect = CameraBackgroundEffect.normal
        switch stored {
        case "goldRelief":
            effect = .metal
            defaults.set(42.0, forKey: keys.metalHue)
            defaults.set(0.75, forKey: keys.metalSaturation)
        case "silverRelief":
            effect = .metal
            defaults.set(0.0, forKey: keys.metalSaturation)
        case "copperRelief":
            effect = .metal
            defaults.set(18.0, forKey: keys.metalHue)
            defaults.set(0.7, forKey: keys.metalSaturation)
        case "liveRelief":
            effect = .metal
            defaults.set(0.0, forKey: keys.metalSaturation)
            defaults.set(true, forKey: keys.liveLight)
        case "neonEdges":
            effect = .neon
            defaults.set(0.0, forKey: keys.glowAmount)
        case "neonGlow":
            effect = .neon
            defaults.set(0.6, forKey: keys.glowAmount)
        default:
            break
        }
        defaults.set(effect.rawValue, forKey: CameraBackgroundEffect.storageKey)
    }
}
