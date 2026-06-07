import Foundation

enum SettingsCategory: String, CaseIterable, Identifiable {
    case appearance
    case workflow
    case data
    case developer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance:
            "Внешний вид"
        case .workflow:
            "Работа"
        case .data:
            "Данные"
        case .developer:
            "Разработчик"
        }
    }

    var iconName: String {
        switch self {
        case .appearance:
            "paintpalette.fill"
        case .workflow:
            "hand.tap.fill"
        case .data:
            "externaldrive.fill"
        case .developer:
            "wrench.and.screwdriver.fill"
        }
    }
}
