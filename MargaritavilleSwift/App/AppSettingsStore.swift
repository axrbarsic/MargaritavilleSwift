import Foundation
import Observation

@Observable
final class AppSettingsStore {

    @ObservationIgnored private let userDefaults: UserDefaults
    private var storedStatusPaletteSaturation: Double
    private var storedMatrixSpeed: Double
    private var storedBackgroundVideoBlur: Double
    private var storedBackgroundVideoBrightness: Double
    private var storedBackgroundVideoGreenTint: Double
    private var storedBackgroundVideoGridIntensity: Double
    private var storedTVStaticSpeed: Double
    private var storedTVStaticParticleSize: Double
    private var storedTVStaticBrightness: Double
    private var storedTVStaticGreenTint: Double
    private var storedDeveloperCellSpringIntensity: Double
    private var storedDeveloperCellSpringSpeed: Double
    private var storedDeveloperVIPFlickerSpeed: Double
    private var storedDeveloperVIPJellySpeed: Double
    var deepSeekModelTier: DeepSeekModelTier {
        didSet {
            userDefaults.set(deepSeekModelTier.rawValue, forKey: Keys.deepSeekModelTier)
        }
    }

    var selectedHotelID: String? {
        didSet {
            if let selectedHotelID {
                userDefaults.set(selectedHotelID, forKey: Keys.selectedHotelID)
            } else {
                userDefaults.removeObject(forKey: Keys.selectedHotelID)
            }
        }
    }

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

    var housekeeperDetailsGestureMode: HousekeeperDetailsGestureMode {
        didSet {
            userDefaults.set(housekeeperDetailsGestureMode.rawValue, forKey: Keys.housekeeperDetailsGestureMode)
        }
    }

    var personalCartMarkers: PersonalCartMarkers {
        didSet {
            Self.savePersonalCartMarkers(personalCartMarkers, userDefaults: userDefaults)
        }
    }

    var housekeepers: [Housekeeper] {
        didSet {
            Self.saveHousekeepers(housekeepers, userDefaults: userDefaults)
        }
    }

    var cartConsumableCatalog: [CartConsumableCatalogItem] {
        didSet {
            Self.saveCartConsumableCatalog(cartConsumableCatalog, userDefaults: userDefaults)
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

    var backgroundVideoGridIntensity: Double {
        get { storedBackgroundVideoGridIntensity }
        set {
            storedBackgroundVideoGridIntensity = Self.normalizedBackgroundVideoGridIntensity(newValue)
            userDefaults.set(storedBackgroundVideoGridIntensity, forKey: Keys.backgroundVideoGridIntensity)
        }
    }

    var tvStaticVariant: TVStaticNoiseVariant {
        didSet {
            userDefaults.set(tvStaticVariant.rawValue, forKey: Keys.tvStaticVariant)
        }
    }

    var tvStaticSpeed: Double {
        get { storedTVStaticSpeed }
        set {
            storedTVStaticSpeed = Self.normalizedTVStaticSpeed(newValue)
            userDefaults.set(storedTVStaticSpeed, forKey: Keys.tvStaticSpeed)
        }
    }

    var tvStaticParticleSize: Double {
        get { storedTVStaticParticleSize }
        set {
            storedTVStaticParticleSize = Self.normalizedTVStaticParticleSize(newValue)
            userDefaults.set(storedTVStaticParticleSize, forKey: Keys.tvStaticParticleSize)
        }
    }

    var tvStaticBrightness: Double {
        get { storedTVStaticBrightness }
        set {
            storedTVStaticBrightness = Self.normalizedTVStaticBrightness(newValue)
            userDefaults.set(storedTVStaticBrightness, forKey: Keys.tvStaticBrightness)
        }
    }

    var tvStaticGreenTint: Double {
        get { storedTVStaticGreenTint }
        set {
            storedTVStaticGreenTint = Self.normalizedTVStaticGreenTint(newValue)
            userDefaults.set(storedTVStaticGreenTint, forKey: Keys.tvStaticGreenTint)
        }
    }

    var developerCellPhysicsEnabled: Bool {
        didSet {
            userDefaults.set(developerCellPhysicsEnabled, forKey: Keys.developerCellPhysicsEnabled)
        }
    }

    var developerVIPFlickerEnabled: Bool {
        didSet {
            userDefaults.set(developerVIPFlickerEnabled, forKey: Keys.developerVIPFlickerEnabled)
        }
    }

    var developerVIPJellyEnabled: Bool {
        didSet {
            userDefaults.set(developerVIPJellyEnabled, forKey: Keys.developerVIPJellyEnabled)
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

    var developerVIPFlickerSpeed: Double {
        get { storedDeveloperVIPFlickerSpeed }
        set {
            storedDeveloperVIPFlickerSpeed = Self.normalizedDeveloperVIPFlickerSpeed(newValue)
            userDefaults.set(storedDeveloperVIPFlickerSpeed, forKey: Keys.developerVIPFlickerSpeed)
        }
    }

    var developerVIPJellySpeed: Double {
        get { storedDeveloperVIPJellySpeed }
        set {
            storedDeveloperVIPJellySpeed = Self.normalizedDeveloperVIPJellySpeed(newValue)
            userDefaults.set(storedDeveloperVIPJellySpeed, forKey: Keys.developerVIPJellySpeed)
        }
    }

    var matrixConfiguration: MatrixRainConfiguration {
        MatrixRainConfiguration(speed: matrixSpeed)
    }

    var tvStaticNoiseConfiguration: TVStaticNoiseConfiguration {
        TVStaticNoiseConfiguration(
            variant: tvStaticVariant,
            speed: tvStaticSpeed,
            particleSize: tvStaticParticleSize,
            brightness: tvStaticBrightness,
            greenTint: tvStaticGreenTint
        )
    }

    var backgroundVideoURL: URL? {
        guard let backgroundVideoRelativePath else { return nil }
        return BackgroundVideoFileStore().url(for: backgroundVideoRelativePath)
    }


    init(
        appBackgroundMode: AppBackgroundMode = .matrixRain,
        roomCellGeometry: RoomCellGeometry = .roomy,
        roomTaskLongPress: Bool = true,
        summaryActionMenuAllowsMultiple: Bool = false,
        housekeeperDetailsGestureMode: HousekeeperDetailsGestureMode = .longPress,
        personalCartMarkers: PersonalCartMarkers = .default,
        statusPaletteSaturation: Double = 1,
        matrixSpeed: Double = MatrixRainConfiguration.default.speed,
        backgroundVideoRelativePath: String? = nil,
        backgroundVideoBlur: Double = 0.28,
        backgroundVideoBrightness: Double = 0.08,
        backgroundVideoGreenTint: Double = 0.34,
        backgroundVideoGridIntensity: Double = 0,
        tvStaticVariant: TVStaticNoiseVariant = TVStaticNoiseConfiguration.default.variant,
        tvStaticSpeed: Double = TVStaticNoiseConfiguration.default.speed,
        tvStaticParticleSize: Double = TVStaticNoiseConfiguration.default.particleSize,
        tvStaticBrightness: Double = TVStaticNoiseConfiguration.default.brightness,
        tvStaticGreenTint: Double = TVStaticNoiseConfiguration.default.greenTint,
        developerCellPhysicsEnabled: Bool = false,
        developerCellSpringIntensity: Double = 0.72,
        developerCellSpringSpeed: Double = 0.82,
        deepSeekModelTier: DeepSeekModelTier = .pro,
        developerVIPFlickerEnabled: Bool = false,
        developerVIPFlickerSpeed: Double = 1.6,
        developerVIPJellyEnabled: Bool = true,
        developerVIPJellySpeed: Double = 0.75,
        selectedHotelID: String? = nil,
        housekeepers: [Housekeeper] = MargaritavilleHousekeeperCatalog.defaultHousekeepers,
        cartConsumableCatalog: [CartConsumableCatalogItem] = CartConsumableCatalog.defaultCatalog,
        userDefaults: UserDefaults = .standard
    ) {
        self.appBackgroundMode = appBackgroundMode
        self.roomCellGeometry = roomCellGeometry
        self.roomTaskLongPress = roomTaskLongPress
        self.summaryActionMenuAllowsMultiple = summaryActionMenuAllowsMultiple
        self.housekeeperDetailsGestureMode = housekeeperDetailsGestureMode
        self.personalCartMarkers = personalCartMarkers.normalized()
        self.backgroundVideoRelativePath = backgroundVideoRelativePath
        self.tvStaticVariant = tvStaticVariant
        self.storedStatusPaletteSaturation = Self.normalizedStatusPaletteSaturation(statusPaletteSaturation)
        self.storedMatrixSpeed = Self.normalizedMatrixSpeed(matrixSpeed)
        self.storedBackgroundVideoBlur = Self.normalizedBackgroundVideoBlur(backgroundVideoBlur)
        self.storedBackgroundVideoBrightness = Self.normalizedBackgroundVideoBrightness(backgroundVideoBrightness)
        self.storedBackgroundVideoGreenTint = Self.normalizedBackgroundVideoGreenTint(backgroundVideoGreenTint)
        self.storedBackgroundVideoGridIntensity = Self.normalizedBackgroundVideoGridIntensity(backgroundVideoGridIntensity)
        self.storedTVStaticSpeed = Self.normalizedTVStaticSpeed(tvStaticSpeed)
        self.storedTVStaticParticleSize = Self.normalizedTVStaticParticleSize(tvStaticParticleSize)
        self.storedTVStaticBrightness = Self.normalizedTVStaticBrightness(tvStaticBrightness)
        self.storedTVStaticGreenTint = Self.normalizedTVStaticGreenTint(tvStaticGreenTint)
        self.storedDeveloperCellSpringIntensity = Self.normalizedDeveloperCellSpringIntensity(developerCellSpringIntensity)
        self.storedDeveloperCellSpringSpeed = Self.normalizedDeveloperCellSpringSpeed(developerCellSpringSpeed)
        self.storedDeveloperVIPFlickerSpeed = Self.normalizedDeveloperVIPFlickerSpeed(developerVIPFlickerSpeed)
        self.storedDeveloperVIPJellySpeed = Self.normalizedDeveloperVIPJellySpeed(developerVIPJellySpeed)
        self.developerCellPhysicsEnabled = developerCellPhysicsEnabled
        self.deepSeekModelTier = deepSeekModelTier
        self.developerVIPFlickerEnabled = developerVIPFlickerEnabled
        self.developerVIPJellyEnabled = developerVIPJellyEnabled
        self.selectedHotelID = selectedHotelID
        self.housekeepers = MargaritavilleHousekeeperCatalog.normalizedHousekeepers(housekeepers)
        self.cartConsumableCatalog = CartConsumableCatalog.normalizedCatalog(cartConsumableCatalog)
        self.userDefaults = userDefaults
    }

}
