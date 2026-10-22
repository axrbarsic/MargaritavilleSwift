import Foundation

/// Процедурные живые обои на Metal-шейдерах. Каждая обоина — одна функция
/// в `ShaderWallpapers.metal`; отрисовка и бюджет кадров общие в `ShaderWallpaperView`.
enum ShaderWallpaperKind: String, CaseIterable, Sendable {
    case aurora
    case liquidNeon
    case hyperspace
    case synthwave

    var shaderFunctionName: String {
        switch self {
        case .aurora: "wallpaperAurora"
        case .liquidNeon: "wallpaperLiquidNeon"
        case .hyperspace: "wallpaperHyperspace"
        case .synthwave: "wallpaperSynthwave"
        }
    }

    var title: String {
        switch self {
        case .aurora: "Сияние"
        case .liquidNeon: "Жидкий неон"
        case .hyperspace: "Космос"
        case .synthwave: "Синтвейв"
        }
    }

    var description: String {
        switch self {
        case .aurora: "Северное сияние"
        case .liquidNeon: "Перетекающий неон"
        case .hyperspace: "Полёт сквозь звёзды"
        case .synthwave: "Ретро-закат 80-х"
        }
    }

    var subtitle: String {
        switch self {
        case .aurora: "Переливающиеся ленты сияния над звёздным небом."
        case .liquidNeon: "Медленно перетекающие неоновые разводы в розово-бирюзовой гамме."
        case .hyperspace: "Бесконечный пролёт сквозь звёзды и туманность."
        case .synthwave: "Полосатое ретро-солнце и бегущая к горизонту неоновая сетка."
        }
    }
}

/// Бюджет кадров живых обоев: 30 кадров, 15 в энергосбережении,
/// стоп-кадр при «Уменьшении движения» и вне активной сцены.
struct ShaderWallpaperFramePolicy: Equatable, Sendable {
    static let normalInterval: TimeInterval = 1.0 / 30.0
    static let lowPowerInterval: TimeInterval = 1.0 / 15.0

    let minimumInterval: TimeInterval
    let isPaused: Bool

    init(isSceneActive: Bool, isLowPowerModeEnabled: Bool, reduceMotion: Bool) {
        minimumInterval = isLowPowerModeEnabled ? Self.lowPowerInterval : Self.normalInterval
        isPaused = !isSceneActive || reduceMotion
    }
}
