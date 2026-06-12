import CoreGraphics
import Foundation

struct MatrixRainConfiguration: Equatable, Sendable {
    var speed: Double

    static let `default` = MatrixRainConfiguration(speed: 1)

    var normalizedSpeed: CGFloat {
        CGFloat(min(max(speed, 0.08), 3.0))
    }
}
