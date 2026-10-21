import SwiftUI

enum RoomCellTypographyWeight: String, CaseIterable, Codable, Identifiable, Sendable {
    case regular
    case medium
    case semibold
    case bold
    case black

    var id: String { rawValue }

    var title: String {
        switch self {
        case .regular: "Regular"
        case .medium: "Medium"
        case .semibold: "Semi"
        case .bold: "Bold"
        case .black: "Black"
        }
    }

    var fontWeight: Font.Weight {
        switch self {
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        case .black: .black
        }
    }
}

struct RoomCellTypography: Codable, Equatable, Sendable {
    static let production = RoomCellTypography(
        roomNumberSize: 45,
        roomNumberWeight: .black,
        roomNumberVerticalOffset: 7,
        activationTimeSize: 12,
        activationTimeWeight: .regular,
        activationTimeVerticalOffset: 1
    )

    static let roomNumberSizeRange = 36.0...48.0
    static let activationTimeSizeRange = 12.0...18.0
    static let verticalOffsetRange = -8.0...8.0

    static func sizeStops(in range: ClosedRange<Double>, step: Double = 1) -> [Double] {
        let distance = range.upperBound - range.lowerBound
        return [0, 0.25, 0.5, 0.75, 1].map { fraction in
            let rawValue = range.lowerBound + (distance * fraction)
            let steppedValue = ((rawValue - range.lowerBound) / step).rounded() * step
            return min(max(range.lowerBound + steppedValue, range.lowerBound), range.upperBound)
        }
    }

    var roomNumberSize: Double
    var roomNumberWeight: RoomCellTypographyWeight
    var roomNumberVerticalOffset: Double
    var activationTimeSize: Double
    var activationTimeWeight: RoomCellTypographyWeight
    var activationTimeVerticalOffset: Double
}
