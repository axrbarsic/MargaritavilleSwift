import CoreGraphics
import Foundation

struct MatrixRainConfiguration: Equatable, Sendable {
    var colorRichness: Double

    static let `default` = MatrixRainConfiguration(colorRichness: 1.25)

    var normalizedColorRichness: CGFloat {
        CGFloat(min(max(colorRichness, 0.65), 2.40))
    }
}
