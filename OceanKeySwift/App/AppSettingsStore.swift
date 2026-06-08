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
        static let backgroundVideoBrightness = "backgroundVideoBrightness"
        static let backgroundVideoGreenTint = "backgroundVideoGreenTint"
        static let developerLiquidGlassEnabled = "developerLiquidGlassEnabled"
        static let developerGlassVIPEnabled = "developerGlassVIPEnabled"
        static let developerMetalAuroraEnabled = "developerMetalAuroraEnabled"
        static let developerSoundPackV2Enabled = "developerSoundPackV2Enabled"
        static let developerHapticsV2Enabled = "developerHapticsV2Enabled"
        static let developerVIPParticlesEnabled = "developerVIPParticlesEnabled"
        static let developerCellPhysicsEnabled = "developerCellPhysicsEnabled"
        static let developerAssistantObjectEnabled = "developerAssistantObjectEnabled"
        static let developerCellVolumeEnabled = "developerCellVolumeEnabled"
        static let developerCellVolumeIntensity = "developerCellVolumeIntensity"
        static let developerCellSpringIntensity = "developerCellSpringIntensity"
        static let developerCellSpringSpeed = "developerCellSpringSpeed"
        static let developerVIPZebraIntensity = "developerVIPZebraIntensity"
        static let developerVIPZebraSpeed = "developerVIPZebraSpeed"
    }

    @ObservationIgnored private let userDefaults: UserDefaults
    private var storedStatusPaletteSaturation: Double
    private var storedMatrixSpeed: Double
    private var storedBackgroundVideoBlur: Double
    private var storedBackgroundVideoBrightness: Double
    private var storedBackgroundVideoGreenTint: Double
    private var storedDeveloperCellVolumeIntensity: Double
    private var storedDeveloperCellSpringIntensity: Double
    private var storedDeveloperCellSpringSpeed: Double
    private var storedDeveloperVIPZebraIntensity: Double
    private var storedDeveloperVIPZebraSpeed: Double

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

    var vividStatusPaletteEnabled: Bool {
        get { storedStatusPaletteSaturation >= 1.5 }
        set {
            statusPaletteSaturation = newValue ? 1.65 : 1
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

    var backgroundVideoBrightness: Double {
        get { storedBackgroundVideoBrightness }
        set {
            storedBackgroundVideoBrightness = Self.normalizedBackgroundVideoBrightness(newValue)
            userDefaults.set(storedBackgroundVideoBrightness, forKey: Keys.backgroundVideoBrightness)
        }
    }

    var backgroundVideoGreenTint: Double {
        get { storedBackgroundVideoGreenTint }
        set {
            storedBackgroundVideoGreenTint = Self.normalizedBackgroundVideoGreenTint(newValue)
            userDefaults.set(storedBackgroundVideoGreenTint, forKey: Keys.backgroundVideoGreenTint)
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

    var developerMetalAuroraEnabled: Bool {
        didSet {
            userDefaults.set(developerMetalAuroraEnabled, forKey: Keys.developerMetalAuroraEnabled)
        }
    }

    var developerSoundPackV2Enabled: Bool {
        didSet {
            userDefaults.set(developerSoundPackV2Enabled, forKey: Keys.developerSoundPackV2Enabled)
        }
    }

    var developerHapticsV2Enabled: Bool {
        didSet {
            userDefaults.set(developerHapticsV2Enabled, forKey: Keys.developerHapticsV2Enabled)
        }
    }

    var developerVIPParticlesEnabled: Bool {
        didSet {
            userDefaults.set(developerVIPParticlesEnabled, forKey: Keys.developerVIPParticlesEnabled)
        }
    }

    var developerCellPhysicsEnabled: Bool {
        didSet {
            userDefaults.set(developerCellPhysicsEnabled, forKey: Keys.developerCellPhysicsEnabled)
        }
    }

    var developerAssistantObjectEnabled: Bool {
        didSet {
            userDefaults.set(developerAssistantObjectEnabled, forKey: Keys.developerAssistantObjectEnabled)
        }
    }

    var developerCellVolumeEnabled: Bool {
        didSet {
            userDefaults.set(developerCellVolumeEnabled, forKey: Keys.developerCellVolumeEnabled)
        }
    }

    var developerCellVolumeIntensity: Double {
        get { storedDeveloperCellVolumeIntensity }
        set {
            storedDeveloperCellVolumeIntensity = Self.normalizedDeveloperCellVolumeIntensity(newValue)
            userDefaults.set(storedDeveloperCellVolumeIntensity, forKey: Keys.developerCellVolumeIntensity)
        }
    }

    var developerCellSpringIntensity: Double {
        get { storedDeveloperCellSpringIntensity }
        set {
            storedDeveloperCellSpringIntensity = Self.normalizedDeveloperCellSpringIntensity(newValue)
            userDefaults.set(storedDeveloperCellSpringIntensity, forKey: Keys.developerCellSpringIntensity)
        }
    }

    var developerCellSpringSpeed: Double {
        get { storedDeveloperCellSpringSpeed }
        set {
            storedDeveloperCellSpringSpeed = Self.normalizedDeveloperCellSpringSpeed(newValue)
            userDefaults.set(storedDeveloperCellSpringSpeed, forKey: Keys.developerCellSpringSpeed)
        }
    }

    var developerVIPZebraIntensity: Double {
        get { storedDeveloperVIPZebraIntensity }
        set {
            storedDeveloperVIPZebraIntensity = Self.normalizedDeveloperVIPZebraIntensity(newValue)
            userDefaults.set(storedDeveloperVIPZebraIntensity, forKey: Keys.developerVIPZebraIntensity)
        }
    }

    var developerVIPZebraSpeed: Double {
        get { storedDeveloperVIPZebraSpeed }
        set {
            storedDeveloperVIPZebraSpeed = Self.normalizedDeveloperVIPZebraSpeed(newValue)
            userDefaults.set(storedDeveloperVIPZebraSpeed, forKey: Keys.developerVIPZebraSpeed)
        }
    }

    var matrixConfiguration: MatrixRainConfiguration {
        MatrixRainConfiguration(speed: matrixSpeed)
    }

    var developerGameFeelPackEnabled: Bool {
        get {
            developerSoundPackV2Enabled
                && developerHapticsV2Enabled
                && developerVIPParticlesEnabled
                && developerCellPhysicsEnabled
        }
        set {
            developerSoundPackV2Enabled = newValue
            developerHapticsV2Enabled = newValue
            developerVIPParticlesEnabled = newValue
            developerCellPhysicsEnabled = newValue
        }
    }

    var developerGlassLabEnabled: Bool {
        get {
            developerLiquidGlassEnabled && developerGlassVIPEnabled
        }
        set {
            developerLiquidGlassEnabled = newValue
            developerGlassVIPEnabled = newValue
        }
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
        backgroundVideoBrightness = 0
        backgroundVideoGreenTint = 0.34
        developerLiquidGlassEnabled = false
        developerGlassVIPEnabled = false
        developerMetalAuroraEnabled = false
        developerSoundPackV2Enabled = false
        developerHapticsV2Enabled = false
        developerVIPParticlesEnabled = false
        developerCellPhysicsEnabled = false
        developerAssistantObjectEnabled = false
        developerCellVolumeEnabled = false
        developerCellVolumeIntensity = 0.78
        developerCellSpringIntensity = 0.72
        developerCellSpringSpeed = 0.82
        developerVIPZebraIntensity = 0.86
        developerVIPZebraSpeed = 0.78
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
        backgroundVideoBrightness: Double = 0,
        backgroundVideoGreenTint: Double = 0.34,
        developerLiquidGlassEnabled: Bool = false,
        developerGlassVIPEnabled: Bool = false,
        developerMetalAuroraEnabled: Bool = false,
        developerSoundPackV2Enabled: Bool = false,
        developerHapticsV2Enabled: Bool = false,
        developerVIPParticlesEnabled: Bool = false,
        developerCellPhysicsEnabled: Bool = false,
        developerAssistantObjectEnabled: Bool = false,
        developerCellVolumeEnabled: Bool = false,
        developerCellVolumeIntensity: Double = 0.78,
        developerCellSpringIntensity: Double = 0.72,
        developerCellSpringSpeed: Double = 0.82,
        developerVIPZebraIntensity: Double = 0.86,
        developerVIPZebraSpeed: Double = 0.78,
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
        self.storedBackgroundVideoBrightness = Self.normalizedBackgroundVideoBrightness(backgroundVideoBrightness)
        self.storedBackgroundVideoGreenTint = Self.normalizedBackgroundVideoGreenTint(backgroundVideoGreenTint)
        self.storedDeveloperCellVolumeIntensity = Self.normalizedDeveloperCellVolumeIntensity(developerCellVolumeIntensity)
        self.storedDeveloperCellSpringIntensity = Self.normalizedDeveloperCellSpringIntensity(developerCellSpringIntensity)
        self.storedDeveloperCellSpringSpeed = Self.normalizedDeveloperCellSpringSpeed(developerCellSpringSpeed)
        self.storedDeveloperVIPZebraIntensity = Self.normalizedDeveloperVIPZebraIntensity(developerVIPZebraIntensity)
        self.storedDeveloperVIPZebraSpeed = Self.normalizedDeveloperVIPZebraSpeed(developerVIPZebraSpeed)
        self.developerLiquidGlassEnabled = developerLiquidGlassEnabled
        self.developerGlassVIPEnabled = developerGlassVIPEnabled
        self.developerMetalAuroraEnabled = developerMetalAuroraEnabled
        self.developerSoundPackV2Enabled = developerSoundPackV2Enabled
        self.developerHapticsV2Enabled = developerHapticsV2Enabled
        self.developerVIPParticlesEnabled = developerVIPParticlesEnabled
        self.developerCellPhysicsEnabled = developerCellPhysicsEnabled
        self.developerAssistantObjectEnabled = developerAssistantObjectEnabled
        self.developerCellVolumeEnabled = developerCellVolumeEnabled
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
        let backgroundVideoBrightness = userDefaults.object(forKey: Keys.backgroundVideoBrightness) as? Double ?? 0
        let backgroundVideoGreenTint = userDefaults.object(forKey: Keys.backgroundVideoGreenTint) as? Double ?? 0.34
        let developerLiquidGlassEnabled = false
        let developerGlassVIPEnabled = false
        let developerMetalAuroraEnabled = false
        let developerSoundPackV2Enabled = false
        let developerHapticsV2Enabled = false
        let developerVIPParticlesEnabled = false
        let developerCellPhysicsEnabled = userDefaults.object(forKey: Keys.developerCellPhysicsEnabled) as? Bool ?? false
        let developerAssistantObjectEnabled = false
        let developerCellVolumeEnabled = userDefaults.object(forKey: Keys.developerCellVolumeEnabled) as? Bool ?? false
        let developerCellVolumeIntensity = userDefaults.object(forKey: Keys.developerCellVolumeIntensity) as? Double ?? 0.78
        let developerCellSpringIntensity = userDefaults.object(forKey: Keys.developerCellSpringIntensity) as? Double ?? 0.72
        let developerCellSpringSpeed = userDefaults.object(forKey: Keys.developerCellSpringSpeed) as? Double ?? 0.82
        let developerVIPZebraIntensity = userDefaults.object(forKey: Keys.developerVIPZebraIntensity) as? Double ?? 0.86
        let developerVIPZebraSpeed = userDefaults.object(forKey: Keys.developerVIPZebraSpeed) as? Double ?? 0.78
        return AppSettingsStore(
            appBackgroundMode: appBackgroundMode,
            roomCellGeometry: geometry,
            roomTaskLongPress: roomTaskLongPress,
            summaryActionMenuAllowsMultiple: summaryActionMenuAllowsMultiple,
            statusPaletteSaturation: statusPaletteSaturation,
            matrixSpeed: matrixSpeed,
            backgroundVideoRelativePath: backgroundVideoRelativePath,
            backgroundVideoBlur: backgroundVideoBlur,
            backgroundVideoBrightness: backgroundVideoBrightness,
            backgroundVideoGreenTint: backgroundVideoGreenTint,
            developerLiquidGlassEnabled: developerLiquidGlassEnabled,
            developerGlassVIPEnabled: developerGlassVIPEnabled,
            developerMetalAuroraEnabled: developerMetalAuroraEnabled,
            developerSoundPackV2Enabled: developerSoundPackV2Enabled,
            developerHapticsV2Enabled: developerHapticsV2Enabled,
            developerVIPParticlesEnabled: developerVIPParticlesEnabled,
            developerCellPhysicsEnabled: developerCellPhysicsEnabled,
            developerAssistantObjectEnabled: developerAssistantObjectEnabled,
            developerCellVolumeEnabled: developerCellVolumeEnabled,
            developerCellVolumeIntensity: developerCellVolumeIntensity,
            developerCellSpringIntensity: developerCellSpringIntensity,
            developerCellSpringSpeed: developerCellSpringSpeed,
            developerVIPZebraIntensity: developerVIPZebraIntensity,
            developerVIPZebraSpeed: developerVIPZebraSpeed,
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

    static func normalizedBackgroundVideoBrightness(_ value: Double) -> Double {
        min(max(value, -0.45), 0.45)
    }

    static func normalizedBackgroundVideoGreenTint(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    static func normalizedDeveloperCellVolumeIntensity(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    static func normalizedDeveloperCellSpringIntensity(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    static func normalizedDeveloperCellSpringSpeed(_ value: Double) -> Double {
        min(max(value, 0.2), 1.6)
    }

    static func normalizedDeveloperVIPZebraIntensity(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    static func normalizedDeveloperVIPZebraSpeed(_ value: Double) -> Double {
        min(max(value, 0.2), 1.8)
    }
}
