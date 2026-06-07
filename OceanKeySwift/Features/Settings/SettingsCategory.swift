import Foundation

enum SettingsCategory: String, CaseIterable, Identifiable {
    case appearance
    case workflow
    case sync
    case tools
    case developer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance:
            "Внешний вид"
        case .workflow:
            "Работа"
        case .sync:
            "Синхронизация"
        case .tools:
            "Инструменты"
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
        case .sync:
            "icloud.fill"
        case .tools:
            "wrench.adjustable.fill"
        case .developer:
            "hammer.fill"
        }
    }
}
