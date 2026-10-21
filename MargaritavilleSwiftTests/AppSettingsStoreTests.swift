import Foundation
import Testing
@testable import MargaritavilleSwift

@Test
func roomCellGeometryUsesMargaritavilleStandardAndExpandedContract() {
    #expect(RoomCellGeometry.roomy.title == "Стандартные")
    #expect(RoomCellGeometry.roomy.description == "Статус удержанием")
    #expect(RoomCellGeometry.roomy.margaritavilleGridSpacing == 8)
    #expect(RoomCellGeometry.roomy.margaritavilleTileHeight == 98)
    #expect(!RoomCellGeometry.roomy.margaritavilleHoldZoomEnabled)

    #expect(RoomCellGeometry.compact.title == "Расширенные")
    #expect(RoomCellGeometry.compact.description == "Зум удержанием")
    #expect(RoomCellGeometry.compact.margaritavilleGridSpacing == 8)
    #expect(RoomCellGeometry.compact.margaritavilleTileHeight == 98)
    #expect(RoomCellGeometry.compact.margaritavilleHoldZoomEnabled)
}

@Test
func margaritavilleGridColumnCountDefaultsToFourAndPersistsThree() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    #expect(AppSettingsStore.load(userDefaults: defaults).margaritavilleGridColumnCount == .four)

    let settings = AppSettingsStore.load(userDefaults: defaults)
    settings.margaritavilleGridColumnCount = .three

    #expect(AppSettingsStore.load(userDefaults: defaults).margaritavilleGridColumnCount == .three)
}

@Test
func appSettingsPersistsMatrixSpeed() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.matrixSpeed = 2.05

    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.matrixSpeed == 2.05)
    #expect(loaded.matrixConfiguration == MatrixRainConfiguration(speed: 2.05))
}

@Test
func appSettingsPersistsBackgroundMode() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.appBackgroundMode = .off

    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.appBackgroundMode == .off)
}

@Test
func appSettingsPersistsTVStaticBackgroundMode() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.appBackgroundMode = .tvStaticNoise

    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.appBackgroundMode == .tvStaticNoise)
}

@Test
func appSettingsPersistsBrooklynBackgroundMode() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.appBackgroundMode = .brooklyn

    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.appBackgroundMode == .brooklyn)
    #expect(defaults.string(forKey: "appBackgroundMode") == "brooklyn")
}

@Test
func appSettingsPersistsBrooklynWebBackgroundMode() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.appBackgroundMode = .brooklynWeb

    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.appBackgroundMode == .brooklynWeb)
    #expect(defaults.string(forKey: "appBackgroundMode") == "brooklynWeb")
}

@Test
func appSettingsDefaultsToDonorExactAndPersistsBrooklynSurfaceStyle() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    #expect(AppSettingsStore.load(userDefaults: defaults).brooklynSurfaceStyle == .donorExact)

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.brooklynSurfaceStyle = .enhanced

    #expect(AppSettingsStore.load(userDefaults: defaults).brooklynSurfaceStyle == .enhanced)
    #expect(defaults.string(forKey: "brooklynSurfaceStyle") == "enhanced")
}

@Test
func appSettingsPersistsClampsAndResetsBrooklynWebAppearance() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let defaultsLoaded = AppSettingsStore.load(userDefaults: defaults)
    #expect(defaultsLoaded.brooklynWebCellScale == 1)
    #expect(abs(defaultsLoaded.brooklynWebHue - 0.950_292_397_660_818_7) < 0.000_000_1)
    #expect(defaultsLoaded.brooklynWebBrightness == 1)
    #expect(defaultsLoaded.brooklynWebContrast == 0)

    defaultsLoaded.brooklynWebCellScale = 0.72
    defaultsLoaded.brooklynWebHue = 0.24
    defaultsLoaded.brooklynWebBrightness = 1.31
    defaultsLoaded.brooklynWebContrast = -0.27

    let persisted = AppSettingsStore.load(userDefaults: defaults)
    #expect(persisted.brooklynWebCellScale == 0.72)
    #expect(persisted.brooklynWebHue == 0.24)
    #expect(persisted.brooklynWebBrightness == 1.31)
    #expect(persisted.brooklynWebContrast == -0.27)

    persisted.brooklynWebCellScale = 10
    persisted.brooklynWebHue = -10
    persisted.brooklynWebBrightness = 10
    persisted.brooklynWebContrast = -10
    #expect(persisted.brooklynWebCellScale == 1.25)
    #expect(persisted.brooklynWebHue == 0)
    #expect(persisted.brooklynWebBrightness == 1.55)
    #expect(persisted.brooklynWebContrast == -0.5)

    persisted.resetBrooklynWebConfiguration()
    let reset = AppSettingsStore.load(userDefaults: defaults)
    #expect(reset.brooklynWebCellScale == 1)
    #expect(abs(reset.brooklynWebHue - 0.950_292_397_660_818_7) < 0.000_000_1)
    #expect(reset.brooklynWebBrightness == 1)
    #expect(reset.brooklynWebContrast == 0)
}

@Test
func appSettingsPersistsBackgroundVideoSettings() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.appBackgroundMode = .video
    settings.backgroundVideoRelativePath = "Background/video-wallpaper.mov"
    settings.backgroundVideoBlur = 0.64
    settings.backgroundVideoBrightness = 0.22
    settings.backgroundVideoGreenTint = 0.71
    settings.backgroundVideoGridIntensity = 0.58

    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.appBackgroundMode == .video)
    #expect(loaded.backgroundVideoRelativePath == "Background/video-wallpaper.mov")
    #expect(loaded.backgroundVideoBlur == 0.64)
    #expect(loaded.backgroundVideoBrightness == 0.22)
    #expect(loaded.backgroundVideoGreenTint == 0.71)
    #expect(loaded.backgroundVideoGridIntensity == 0.58)
}

@Test
func appSettingsPersistsTVStaticBackgroundSettings() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.appBackgroundMode = .tvStaticNoise
    settings.tvStaticVariant = .horizontalTear
    settings.tvStaticBrightness = 0.31
    settings.tvStaticGreenTint = 0.76

    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.appBackgroundMode == .tvStaticNoise)
    #expect(loaded.tvStaticVariant == .horizontalTear)
    #expect(loaded.tvStaticBrightness == 0.31)
    #expect(loaded.tvStaticGreenTint == 0.76)
    #expect(loaded.tvStaticNoiseConfiguration == TVStaticNoiseConfiguration(
        variant: .horizontalTear,
        speed: TVStaticNoiseConfiguration.default.speed,
        particleSize: TVStaticNoiseConfiguration.default.particleSize,
        brightness: 0.31,
        greenTint: 0.76
    ))
}

@Test
func appSettingsPersistsDeveloperExperimentalFlags() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    #expect(!settings.developerLive3DCellsEnabled)
    settings.developerCellPhysicsEnabled = true
    settings.developerLive3DCellsEnabled = true
    settings.developerCellSpringIntensity = 0.64
    settings.developerCellSpringSpeed = 1.14
    settings.developerVIPFlickerEnabled = true
    settings.developerVIPFlickerSpeed = 2.35
    settings.developerVIPJellyEnabled = true
    settings.developerVIPJellySpeed = 1.45
    settings.developerVIPHDREnabled = true
    settings.developerStatusHDRPulseEnabled = true

    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.developerCellPhysicsEnabled)
    #expect(loaded.developerLive3DCellsEnabled)
    #expect(loaded.developerCellSpringIntensity == 0.64)
    #expect(loaded.developerCellSpringSpeed == 1.14)
    #expect(loaded.developerVIPFlickerEnabled)
    #expect(loaded.developerVIPFlickerSpeed == 2.35)
    #expect(loaded.developerVIPJellyEnabled)
    #expect(loaded.developerVIPJellySpeed == 1.45)
    #expect(loaded.developerVIPHDREnabled)
    #expect(loaded.developerStatusHDRPulseEnabled)
}

@Test
func appSettingsClampsMatrixSpeed() {
    let settings = AppSettingsStore(matrixSpeed: 9)
    let low = AppSettingsStore(matrixSpeed: 0)

    #expect(settings.matrixSpeed == 3.0)
    #expect(low.matrixSpeed == 0.08)
}

@Test
func appSettingsPersistsSummaryActionMenuMode() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.summaryActionMenuAllowsMultiple = true

    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.summaryActionMenuAllowsMultiple)
}

@Test
func appSettingsPersistsPersonalCartMarkers() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.personalCartMarkers = PersonalCartMarkers(
        aYellowFloor: 3,
        aGrayFloor: 4,
        bYellowFloor: 5,
        bGrayFloor: 2
    )

    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.personalCartMarkers.aYellowFloor == 3)
    #expect(loaded.personalCartMarkers.aGrayFloor == 4)
    #expect(loaded.personalCartMarkers.bYellowFloor == 5)
    #expect(loaded.personalCartMarkers.bGrayFloor == 2)
}

@Test
func appSettingsPersistsSelectedHotel() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.selectedHotelID = HotelProfile.margaritaville.id

    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.selectedHotelID == HotelProfile.margaritaville.id)
}

@Test
func appSettingsPersistsEditableHousekeepers() throws {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.addHousekeeper(named: "Alexandra")
    let created = try #require(settings.housekeepers.first { $0.displayName == "Alexandra" })
    settings.renameHousekeeper(id: created.id, displayName: "Alex")
    settings.setHousekeeperPalette(id: created.id, palette: .ruby)

    let loaded = AppSettingsStore.load(userDefaults: defaults)
    let housekeeper = try #require(loaded.housekeeper(id: created.id))

    #expect(housekeeper.displayName == "Alex")
    #expect(housekeeper.palette == .ruby)
    #expect(loaded.housekeepers.contains { $0.displayName == "Ketty" })
    #expect(loaded.housekeepers.contains { $0.displayName == "Omelene PM" })
}

@Test
func appSettingsPersistsHousekeeperDetailsGestureMode() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.housekeeperDetailsGestureMode = .swipeLeft

    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.housekeeperDetailsGestureMode == .swipeLeft)
}

@Test
func appSettingsPersistsEditableCartConsumableCatalog() throws {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    let created = try #require(settings.addCartConsumableCatalogItem(named: "Coffee packs"))
    settings.renameCartConsumableCatalogItem(id: created.id, title: "Coffee kit")
    settings.removeCartConsumableCatalogItem(id: "washcloth")

    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.cartConsumableCatalog.contains { $0.id == created.id && $0.title == "Coffee kit" })
    #expect(!loaded.cartConsumableCatalog.contains { $0.id == "washcloth" })
    #expect(loaded.cartConsumableCatalog.contains { $0.id == "bath_towel" })
}

@Test
func appSettingsPersistsStatusPaletteSaturation() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.statusPaletteSaturation = 1.42

    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.statusPaletteSaturation == 1.42)
}

@Test
func appSettingsVividPaletteToggleControlsFixedPreset() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.vividStatusPaletteEnabled = true

    let vivid = AppSettingsStore.load(userDefaults: defaults)
    #expect(vivid.vividStatusPaletteEnabled)
    #expect(vivid.statusPaletteSaturation == 1.65)

    vivid.vividStatusPaletteEnabled = false

    let normal = AppSettingsStore.load(userDefaults: defaults)
    #expect(!normal.vividStatusPaletteEnabled)
    #expect(normal.statusPaletteSaturation == 1)
}

@Test
func appSettingsClampsStatusPaletteSaturation() {
    let high = AppSettingsStore(statusPaletteSaturation: 99)
    let low = AppSettingsStore(statusPaletteSaturation: -1)

    #expect(high.statusPaletteSaturation == 1.65)
    #expect(low.statusPaletteSaturation == 0.70)
}

@Test
func appSettingsResetRestoresDefaultsAndPersistsThem() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.appBackgroundMode = .off
    settings.brooklynSurfaceStyle = .enhanced
    settings.brooklynWebCellScale = 0.58
    settings.brooklynWebHue = 0.12
    settings.brooklynWebBrightness = 1.42
    settings.brooklynWebContrast = 0.38
    settings.roomCellGeometry = .compact
    settings.margaritavilleGridColumnCount = .three
    settings.roomTaskLongPress = false
    settings.summaryActionMenuAllowsMultiple = true
    settings.personalCartMarkers = PersonalCartMarkers(aYellowFloor: 3, aGrayFloor: 4, bYellowFloor: 5, bGrayFloor: 2)
    settings.statusPaletteSaturation = 1.52
    settings.matrixSpeed = 2.2
    settings.backgroundVideoRelativePath = "Background/video-wallpaper.mov"
    settings.backgroundVideoBlur = 0.7
    settings.backgroundVideoBrightness = 0.33
    settings.backgroundVideoGreenTint = 0.81
    settings.backgroundVideoGridIntensity = 0.42
    settings.tvStaticVariant = .greenTerminal
    settings.tvStaticBrightness = 0.44
    settings.tvStaticGreenTint = 0.93
    settings.developerCellPhysicsEnabled = true
    settings.developerLive3DCellsEnabled = true
    settings.developerCellSpringIntensity = 0.35
    settings.developerCellSpringSpeed = 1.25
    settings.developerVIPFlickerEnabled = true
    settings.developerVIPFlickerSpeed = 3.2
    settings.developerVIPJellyEnabled = true
    settings.developerVIPJellySpeed = 2.1

    settings.resetToDefaults()
    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.appBackgroundMode == .matrixRain)
    #expect(loaded.brooklynSurfaceStyle == .donorExact)
    #expect(loaded.brooklynWebCellScale == 1)
    #expect(abs(loaded.brooklynWebHue - 0.950_292_397_660_818_7) < 0.000_000_1)
    #expect(loaded.brooklynWebBrightness == 1)
    #expect(loaded.brooklynWebContrast == 0)
    #expect(loaded.roomCellGeometry == .roomy)
    #expect(loaded.margaritavilleGridColumnCount == .four)
    #expect(loaded.roomTaskLongPress)
    #expect(!loaded.summaryActionMenuAllowsMultiple)
    #expect(loaded.personalCartMarkers == .default)
    #expect(loaded.statusPaletteSaturation == 1)
    #expect(loaded.matrixSpeed == MatrixRainConfiguration.default.speed)
    #expect(loaded.backgroundVideoRelativePath == nil)
    #expect(loaded.backgroundVideoBlur == 0.28)
    #expect(loaded.backgroundVideoBrightness == 0.08)
    #expect(loaded.backgroundVideoGreenTint == 0.34)
    #expect(loaded.backgroundVideoGridIntensity == 0)
    #expect(loaded.tvStaticVariant == TVStaticNoiseConfiguration.default.variant)
    #expect(loaded.tvStaticSpeed == TVStaticNoiseConfiguration.default.speed)
    #expect(loaded.tvStaticParticleSize == TVStaticNoiseConfiguration.default.particleSize)
    #expect(loaded.tvStaticBrightness == TVStaticNoiseConfiguration.default.brightness)
    #expect(loaded.tvStaticGreenTint == TVStaticNoiseConfiguration.default.greenTint)
    #expect(!loaded.developerCellPhysicsEnabled)
    #expect(!loaded.developerLive3DCellsEnabled)
    #expect(loaded.developerCellSpringIntensity == 0.72)
    #expect(loaded.developerCellSpringSpeed == 0.82)
    #expect(!loaded.developerVIPFlickerEnabled)
    #expect(loaded.developerVIPFlickerSpeed == 1.6)
    #expect(loaded.developerVIPJellyEnabled)
    #expect(loaded.developerVIPJellySpeed == 0.75)
    #expect(loaded.housekeepers == MargaritavilleHousekeeperCatalog.defaultHousekeepers)
}

@Test
func appSettingsMigratesVIPJellyOnForExistingDevicesOnce() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    defaults.set(false, forKey: "developerVIPBreathingEnabled")

    let migrated = AppSettingsStore.load(userDefaults: defaults)
    #expect(migrated.developerVIPJellyEnabled)

    migrated.developerVIPJellyEnabled = false

    let reloaded = AppSettingsStore.load(userDefaults: defaults)
    #expect(!reloaded.developerVIPJellyEnabled)
}
