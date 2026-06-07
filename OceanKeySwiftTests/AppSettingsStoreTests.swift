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
func appSettingsPersistsBackgroundVideoSettings() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.appBackgroundMode = .video
    settings.backgroundVideoRelativePath = "Background/video-wallpaper.mov"
    settings.backgroundVideoBlur = 0.64

    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.appBackgroundMode == .video)
    #expect(loaded.backgroundVideoRelativePath == "Background/video-wallpaper.mov")
    #expect(loaded.backgroundVideoBlur == 0.64)
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
}
