import Foundation

public enum BrooklynSurfaceStyle: String, CaseIterable, Identifiable, Sendable {
    case donorExact
    case enhanced

    public var id: String { rawValue }
}

public struct BrooklynBackgroundConfiguration: Equatable, Sendable {
    public let style: BrooklynSurfaceStyle
    public let appearance: BrooklynAppearance

    public static let donorExact = BrooklynBackgroundConfiguration(style: .donorExact)
    public static let enhanced = BrooklynBackgroundConfiguration(style: .enhanced)
    public static let authorPreset = donorExact

    public init(style: BrooklynSurfaceStyle = .donorExact, appearance: BrooklynAppearance = .default) {
        self.style = style
        self.appearance = appearance
    }
}
