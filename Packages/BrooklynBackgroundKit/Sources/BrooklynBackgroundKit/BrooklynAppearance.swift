import Foundation
import simd

/// Пользовательский вид Brooklyn: размер ячеек (зум камеры с бесконечной сеткой),
/// круговой оттенок, яркость и контраст финальной цветокоррекции.
/// Диапазоны и значения по умолчанию совпадают с бывшей веб-версией.
public struct BrooklynAppearance: Codable, Equatable, Sendable {
    public static let cellScaleRange = 0.45...1.25
    public static let hueRange = 0.0...1.0
    public static let brightnessRange = 0.45...1.55
    public static let contrastRange = -0.5...0.5

    /// Оттенок исходного розового цвета `#f51155` в HSL.
    public static let donorHue = 0.9502923976608187
    public static let `default` = BrooklynAppearance()

    public let cellScale: Double
    public let hue: Double
    public let brightness: Double
    public let contrast: Double

    public init(
        cellScale: Double = 1,
        hue: Double = donorHue,
        brightness: Double = 1,
        contrast: Double = 0
    ) {
        self.cellScale = Self.clamped(cellScale, to: Self.cellScaleRange, fallback: 1)
        self.hue = Self.clamped(hue, to: Self.hueRange, fallback: Self.donorHue)
        self.brightness = Self.clamped(brightness, to: Self.brightnessRange, fallback: 1)
        self.contrast = Self.clamped(contrast, to: Self.contrastRange, fallback: 0)
    }

    /// Цвет сцены после поворота оттенка: сдвиг относительно donor hue
    /// с сохранением насыщенности и светлоты, как `THREE.Color.setHSL`.
    func shiftedColor(_ srgb: SIMD3<Float>) -> SIMD3<Float> {
        guard hue != Self.donorHue else { return srgb }
        var hsl = BrooklynHSL(srgb: srgb)
        hsl.hue = (hsl.hue + hue - Self.donorHue + 1).truncatingRemainder(dividingBy: 1)
        return hsl.srgb
    }

    private static func clamped(_ value: Double, to range: ClosedRange<Double>, fallback: Double) -> Double {
        guard value.isFinite else { return fallback }
        return min(max(value, range.lowerBound), range.upperBound)
    }
}

struct BrooklynHSL {
    var hue: Double
    var saturation: Double
    var lightness: Double

    init(srgb: SIMD3<Float>) {
        let r = Double(srgb.x), g = Double(srgb.y), b = Double(srgb.z)
        let maximum = max(r, g, b), minimum = min(r, g, b)
        lightness = (maximum + minimum) / 2
        guard maximum != minimum else {
            hue = 0
            saturation = 0
            return
        }
        let delta = maximum - minimum
        saturation = lightness <= 0.5 ? delta / (maximum + minimum) : delta / (2 - maximum - minimum)
        switch maximum {
        case r: hue = (g - b) / delta + (g < b ? 6 : 0)
        case g: hue = (b - r) / delta + 2
        default: hue = (r - g) / delta + 4
        }
        hue /= 6
    }

    var srgb: SIMD3<Float> {
        guard saturation > 0 else { return SIMD3(repeating: Float(lightness)) }
        let q = lightness <= 0.5 ? lightness * (1 + saturation) : lightness + saturation - lightness * saturation
        let p = 2 * lightness - q
        return SIMD3(
            Float(Self.channel(p, q, hue + 1.0 / 3.0)),
            Float(Self.channel(p, q, hue)),
            Float(Self.channel(p, q, hue - 1.0 / 3.0))
        )
    }

    private static func channel(_ p: Double, _ q: Double, _ t: Double) -> Double {
        var t = t
        if t < 0 { t += 1 }
        if t > 1 { t -= 1 }
        if t < 1.0 / 6.0 { return p + (q - p) * 6 * t }
        if t < 1.0 / 2.0 { return q }
        if t < 2.0 / 3.0 { return p + (q - p) * (2.0 / 3.0 - t) * 6 }
        return p
    }
}
