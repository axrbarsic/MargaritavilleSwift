import Foundation

public struct BrooklynWebConfiguration: Codable, Equatable, Sendable {
    public static let cellScaleRange = 0.45...1.25
    public static let hueRange = 0.0...1.0
    public static let brightnessRange = 0.45...1.55
    public static let contrastRange = -0.5...0.5

    public static let donorHue = 0.9502923976608187
    public static let `default` = BrooklynWebConfiguration(
        cellScale: 1,
        hue: donorHue,
        brightness: 1,
        contrast: 0
    )

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
        self.cellScale = Self.clamped(
            cellScale,
            to: Self.cellScaleRange,
            fallback: 1
        )
        self.hue = Self.clamped(
            hue,
            to: Self.hueRange,
            fallback: Self.donorHue
        )
        self.brightness = Self.clamped(
            brightness,
            to: Self.brightnessRange,
            fallback: 1
        )
        self.contrast = Self.clamped(
            contrast,
            to: Self.contrastRange,
            fallback: 0
        )
    }

    private static func clamped(
        _ value: Double,
        to range: ClosedRange<Double>,
        fallback: Double
    ) -> Double {
        guard value.isFinite else { return fallback }
        return min(max(value, range.lowerBound), range.upperBound)
    }
}
