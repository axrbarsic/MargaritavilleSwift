import Foundation
import Testing
@testable import OceanKeySwift

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
func appSettingsPersistsDeveloperExperimentalFlags() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.developerCellPhysicsEnabled = true
    settings.developerCellSpringIntensity = 0.64
    settings.developerCellSpringSpeed = 1.14
    settings.developerVIPZebraIntensity = 0.77
    settings.developerVIPZebraSpeed = 1.22
    settings.developerVIPZebraSharpness = 0.44

    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.developerCellPhysicsEnabled)
    #expect(loaded.developerCellSpringIntensity == 0.64)
    #expect(loaded.developerCellSpringSpeed == 1.14)
    #expect(loaded.developerVIPZebraIntensity == 0.77)
    #expect(loaded.developerVIPZebraSpeed == 1.22)
    #expect(loaded.developerVIPZebraSharpness == 0.44)
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
    settings.roomCellGeometry = .compact
    settings.roomTaskLongPress = false
    settings.summaryActionMenuAllowsMultiple = true
    settings.statusPaletteSaturation = 1.52
    settings.matrixSpeed = 2.2
    settings.backgroundVideoRelativePath = "Background/video-wallpaper.mov"
    settings.backgroundVideoBlur = 0.7
    settings.backgroundVideoBrightness = 0.33
    settings.backgroundVideoGreenTint = 0.81
    settings.backgroundVideoGridIntensity = 0.42
    settings.developerCellPhysicsEnabled = true
    settings.developerCellSpringIntensity = 0.35
    settings.developerCellSpringSpeed = 1.25
    settings.developerVIPZebraIntensity = 0.45
    settings.developerVIPZebraSpeed = 1.35
    settings.developerVIPZebraSharpness = 0.29

    settings.resetToDefaults()
    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.appBackgroundMode == .matrixRain)
    #expect(loaded.roomCellGeometry == .roomy)
    #expect(loaded.roomTaskLongPress)
    #expect(!loaded.summaryActionMenuAllowsMultiple)
    #expect(loaded.statusPaletteSaturation == 1)
    #expect(loaded.matrixSpeed == MatrixRainConfiguration.default.speed)
    #expect(loaded.backgroundVideoRelativePath == nil)
    #expect(loaded.backgroundVideoBlur == 0.28)
    #expect(loaded.backgroundVideoBrightness == 0.08)
    #expect(loaded.backgroundVideoGreenTint == 0.34)
    #expect(loaded.backgroundVideoGridIntensity == 0)
    #expect(!loaded.developerCellPhysicsEnabled)
    #expect(loaded.developerCellSpringIntensity == 0.72)
    #expect(loaded.developerCellSpringSpeed == 0.82)
    #expect(loaded.developerVIPZebraIntensity == 0.86)
    #expect(loaded.developerVIPZebraSpeed == 0.78)
    #expect(loaded.developerVIPZebraSharpness == 0.62)
}
