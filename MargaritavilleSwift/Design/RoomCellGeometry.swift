import CoreGraphics
import Foundation

enum RoomCellGeometry: String, CaseIterable, Codable, Identifiable {
    case roomy
    case compact

    var id: String { rawValue }

    var title: String {
        switch self {
        case .roomy:
            "Крупные"
        case .compact:
            "Компактные"
        }
    }

    var description: String {
        switch self {
        case .roomy:
            "Первый Swift-тест"
        case .compact:
            "Плотный Flutter-parity"
        }
    }

    var sectionSpacing: CGFloat {
        switch self {
        case .roomy: 10
        case .compact: 7
        }
    }

    var sectionHorizontalPadding: CGFloat {
        switch self {
        case .roomy: 6
        case .compact: 5
        }
    }

    var taskSpacing: CGFloat {
        switch self {
        case .roomy: 18
        case .compact: 6
        }
    }

    var tileLeadingPadding: CGFloat {
        switch self {
        case .roomy: 20
        case .compact: 14
        }
    }

    var tileTrailingPadding: CGFloat {
        switch self {
        case .roomy: 20
        case .compact: 8
        }
    }

    var tileHeight: CGFloat {
        switch self {
        case .roomy: 76
        case .compact: 66
        }
    }

    var tileCornerRadius: CGFloat {
        switch self {
        case .roomy: 14
        case .compact: 13
        }
    }

    var tileShadowOpacity: Double {
        switch self {
        case .roomy: 0.25
        case .compact: 0.23
        }
    }
}
