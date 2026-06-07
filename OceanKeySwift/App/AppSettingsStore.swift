import Foundation
import Observation

enum AppBackgroundMode: String, CaseIterable, Identifiable, Codable {
    case off
    case matrixRain
    case video

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off:
            "Выкл"
        case .matrixRain:
            "Matrix"
        case .video:
            "Видео"
        }
    }

    var description: String {
        switch self {
        case .off:
            "Чёрный фон"
        case .matrixRain:
            "Matrix Rain"
        case .video:
            "Видео фон"
        }
    }
}

@Observable
final class AppSettingsStore {
    private enum Keys {
        static let appBackgroundMode = "appBackgroundMode"
        static let roomCellGeometry = "roomCellGeometry"
        static let roomTaskLongPress = "roomTaskLongPress"
        static let summaryActionMenuAllowsMultiple = "summaryActionMenuAllowsMultiple"
        static let statusPaletteSaturation = "statusPaletteSaturation"
        static let matrixSpeed = "matrixSpeed"
        static let backgroundVideoRelativePath = "backgroundVideoRelativePath"
        static let backgroundVideoBlur = "backgroundVideoBlur"
        static let developerLiquidGlassEnabled = "developerLiquidGlassEnabled"
        static let developerGlassVIPEnabled = "developerGlassVIPEnabled"
    }

    @ObservationIgnored private let userDefaults: UserDefaults
    private var storedStatusPaletteSaturation: Double
    private var storedMatrixSpeed: Double
    private var storedBackgroundVideoBlur: Double

    var appBackgroundMode: AppBackgroundMode {
        didSet {
            userDefaults.set(appBackgroundMode.rawValue, forKey: Keys.appBackgroundMode)
        }
    }

    var roomCellGeometry: RoomCellGeometry {
        didSet {
            userDefaults.set(roomCellGeometry.rawValue, forKey: Keys.roomCellGeometry)
        }
    }

    var roomTaskLongPress: Bool {
        didSet {
            userDefaults.set(roomTaskLongPress, forKey: Keys.roomTaskLongPress)
        }
    }

    var summaryActionMenuAllowsMultiple: Bool {
        didSet {
            userDefaults.set(summaryActionMenuAllowsMultiple, forKey: Keys.summaryActionMenuAllowsMultiple)
        }
    }

    var statusPaletteSaturation: Double {
        get { storedStatusPaletteSaturation }
        set {
            storedStatusPaletteSaturation = Self.normalizedStatusPaletteSaturation(newValue)
            userDefaults.set(storedStatusPaletteSaturation, forKey: Keys.statusPaletteSaturation)
        }
    }

    var matrixSpeed: Double {
        get { storedMatrixSpeed }
        set {
            storedMatrixSpeed = Self.normalizedMatrixSpeed(newValue)
            userDefaults.set(storedMatrixSpeed, forKey: Keys.matrixSpeed)
        }
    }

    var backgroundVideoRelativePath: String? {
        didSet {
            userDefaults.set(backgroundVideoRelativePath, forKey: Keys.backgroundVideoRelativePath)
        }
    }

    var backgroundVideoBlur: Double {
        get { storedBackgroundVideoBlur }
        set {
            storedBackgroundVideoBlur = Self.normalizedBackgroundVideoBlur(newValue)
            userDefaults.set(storedBackgroundVideoBlur, forKey: Keys.backgroundVideoBlur)
        }
    }

    var developerLiquidGlassEnabled: Bool {
        didSet {
            userDefaults.set(developerLiquidGlassEnabled, forKey: Keys.developerLiquidGlassEnabled)
        }
    }

    var developerGlassVIPEnabled: Bool {
        didSet {
            userDefaults.set(developerGlassVIPEnabled, forKey: Keys.developerGlassVIPEnabled)
        }
    }

    var matrixConfiguration: MatrixRainConfiguration {
        MatrixRainConfiguration(speed: matrixSpeed)
    }

    var backgroundVideoURL: URL? {
        guard let backgroundVideoRelativePath else { return nil }
        return BackgroundVideoFileStore().url(for: backgroundVideoRelativePath)
    }

    func resetToDefaults() {
        appBackgroundMode = .matrixRain
        roomCellGeometry = .roomy
        roomTaskLongPress = true
        summaryActionMenuAllowsMultiple = false
        statusPaletteSaturation = 1
        matrixSpeed = MatrixRainConfiguration.default.speed
        backgroundVideoRelativePath = nil
        backgroundVideoBlur = 0.28
        developerLiquidGlassEnabled = false
        developerGlassVIPEnabled = false
    }

    init(
        appBackgroundMode: AppBackgroundMode = .matrixRain,
        roomCellGeometry: RoomCellGeometry = .roomy,
        roomTaskLongPress: Bool = true,
        summaryActionMenuAllowsMultiple: Bool = false,
        statusPaletteSaturation: Double = 1,
        matrixSpeed: Double = MatrixRainConfiguration.default.speed,
        backgroundVideoRelativePath: String? = nil,
        backgroundVideoBlur: Double = 0.28,
        developerLiquidGlassEnabled: Bool = false,
        developerGlassVIPEnabled: Bool = false,
        userDefaults: UserDefaults = .standard
    ) {
        self.appBackgroundMode = appBackgroundMode
        self.roomCellGeometry = roomCellGeometry
        self.roomTaskLongPress = roomTaskLongPress
        self.summaryActionMenuAllowsMultiple = summaryActionMenuAllowsMultiple
        self.backgroundVideoRelativePath = backgroundVideoRelativePath
        self.storedStatusPaletteSaturation = Self.normalizedStatusPaletteSaturation(statusPaletteSaturation)
        self.storedMatrixSpeed = Self.normalizedMatrixSpeed(matrixSpeed)
        self.storedBackgroundVideoBlur = Self.normalizedBackgroundVideoBlur(backgroundVideoBlur)
        self.developerLiquidGlassEnabled = developerLiquidGlassEnabled
        self.developerGlassVIPEnabled = developerGlassVIPEnabled
        self.userDefaults = userDefaults
    }

    static func load(userDefaults: UserDefaults = .standard) -> AppSettingsStore {
        let backgroundRawValue = userDefaults.string(forKey: Keys.appBackgroundMode)
        let appBackgroundMode = backgroundRawValue.flatMap(AppBackgroundMode.init(rawValue:)) ?? .matrixRain
        let rawValue = userDefaults.string(forKey: Keys.roomCellGeometry)
        let geometry = rawValue.flatMap(RoomCellGeometry.init(rawValue:)) ?? .roomy
        let roomTaskLongPress = userDefaults.object(forKey: Keys.roomTaskLongPress) as? Bool ?? true
        let summaryActionMenuAllowsMultiple = userDefaults.object(forKey: Keys.summaryActionMenuAllowsMultiple) as? Bool ?? false
        let statusPaletteSaturation = userDefaults.object(forKey: Keys.statusPaletteSaturation) as? Double ?? 1
        let matrixSpeed = userDefaults.object(forKey: Keys.matrixSpeed) as? Double
            ?? MatrixRainConfiguration.default.speed
        let backgroundVideoRelativePath = userDefaults.string(forKey: Keys.backgroundVideoRelativePath)
        let backgroundVideoBlur = userDefaults.object(forKey: Keys.backgroundVideoBlur) as? Double ?? 0.28
        let developerLiquidGlassEnabled = userDefaults.object(forKey: Keys.developerLiquidGlassEnabled) as? Bool ?? false
        let developerGlassVIPEnabled = userDefaults.object(forKey: Keys.developerGlassVIPEnabled) as? Bool ?? false
        return AppSettingsStore(
            appBackgroundMode: appBackgroundMode,
            roomCellGeometry: geometry,
            roomTaskLongPress: roomTaskLongPress,
            summaryActionMenuAllowsMultiple: summaryActionMenuAllowsMultiple,
            statusPaletteSaturation: statusPaletteSaturation,
            matrixSpeed: matrixSpeed,
            backgroundVideoRelativePath: backgroundVideoRelativePath,
            backgroundVideoBlur: backgroundVideoBlur,
            developerLiquidGlassEnabled: developerLiquidGlassEnabled,
            developerGlassVIPEnabled: developerGlassVIPEnabled,
            userDefaults: userDefaults
        )
    }

    static func normalizedStatusPaletteSaturation(_ value: Double) -> Double {
        min(max(value, 0.70), 1.65)
    }

    static func normalizedMatrixSpeed(_ value: Double) -> Double {
        min(max(value, 0.08), 3.0)
    }

    static func normalizedBackgroundVideoBlur(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
