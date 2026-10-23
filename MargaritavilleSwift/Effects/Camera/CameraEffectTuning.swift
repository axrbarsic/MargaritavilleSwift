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
    }

    static let amountRange = 0.0...1.0
    static let brightnessRange = 0.5...1.6
    static let reliefDepthRange = 0.25...3.0
    static let lightAngleRange = 0.0...360.0
    static let edgeSensitivityRange = 0.4...2.5
    static let detailScaleRange = 0.5...2.0

    /// Свет по умолчанию падает сверху слева (ось y направлена вниз).
    static let defaultLightAngle = 225.0
    static let `default` = CameraEffectTuning()

    var amount = 1.0
    var brightness = 1.0
    var reliefDepth = 1.0
    var lightAngle = defaultLightAngle
    var edgeSensitivity = 1.0
    var detailScale = 1.0

    /// Значения, приведённые к допустимым диапазонам.
    var clamped: CameraEffectTuning {
        CameraEffectTuning(
            amount: Self.clamp(amount, Self.amountRange),
            brightness: Self.clamp(brightness, Self.brightnessRange),
            reliefDepth: Self.clamp(reliefDepth, Self.reliefDepthRange),
            lightAngle: Self.clamp(lightAngle, Self.lightAngleRange),
            edgeSensitivity: Self.clamp(edgeSensitivity, Self.edgeSensitivityRange),
            detailScale: Self.clamp(detailScale, Self.detailScaleRange)
        )
    }

    private static func clamp(_ value: Double, _ range: ClosedRange<Double>) -> Double {
        guard value.isFinite else { return range.lowerBound }
        return min(max(value, range.lowerBound), range.upperBound)
    }
}

extension CameraBackgroundEffect {
    /// Рельефные эффекты: глубина и направление света.
    var usesRelief: Bool {
        switch self {
        case .emboss, .goldRelief, .silverRelief, .copperRelief, .stoneRelief, .paperRelief, .woodRelief, .liveRelief:
            true
        default:
            false
        }
    }

    /// Эффекты на контурах: чувствительность выделения линий.
    var usesEdges: Bool {
        switch self {
        case .neonEdges, .comic, .sketch, .cartoon, .neonShadow, .neonGlow, .tron, .blueprint, .chalk, .electric:
            true
        default:
            false
        }
    }

    /// Эффекты с ячейками: размер пикселей, символов, кубиков и клеток.
    var usesDetailScale: Bool {
        switch self {
        case .grid, .pixels, .ascii, .dither, .halftone, .gameBoy, .lego, .sketch, .blueprint:
            true
        default:
            false
        }
    }

    /// У «Живого рельефа» свет движется сам, направление не настраивается.
    var usesLightAngle: Bool { usesRelief && self != .liveRelief }
}
