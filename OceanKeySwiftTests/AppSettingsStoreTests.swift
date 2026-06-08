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
func appSettingsPersistsDeveloperExperimentalFlags() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.developerLiquidGlassEnabled = true
    settings.developerGlassVIPEnabled = true
    settings.developerMetalAuroraEnabled = true
    settings.developerSoundPackV2Enabled = true
    settings.developerHapticsV2Enabled = true
    settings.developerVIPParticlesEnabled = true
    settings.developerCellPhysicsEnabled = true
    settings.developerAssistantObjectEnabled = true

    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.developerLiquidGlassEnabled)
    #expect(loaded.developerGlassVIPEnabled)
    #expect(loaded.developerMetalAuroraEnabled)
    #expect(loaded.developerSoundPackV2Enabled)
    #expect(loaded.developerHapticsV2Enabled)
    #expect(loaded.developerVIPParticlesEnabled)
    #expect(loaded.developerCellPhysicsEnabled)
    #expect(loaded.developerAssistantObjectEnabled)
}

@Test
func appSettingsGroupedDeveloperTogglesControlUnderlyingFlags() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.developerGlassLabEnabled = true
    settings.developerGameFeelPackEnabled = true

    #expect(settings.developerLiquidGlassEnabled)
    #expect(settings.developerGlassVIPEnabled)
    #expect(settings.developerSoundPackV2Enabled)
    #expect(settings.developerHapticsV2Enabled)
    #expect(settings.developerVIPParticlesEnabled)
    #expect(settings.developerCellPhysicsEnabled)

    settings.developerGlassLabEnabled = false
    settings.developerGameFeelPackEnabled = false

    let loaded = AppSettingsStore.load(userDefaults: defaults)
    #expect(!loaded.developerLiquidGlassEnabled)
    #expect(!loaded.developerGlassVIPEnabled)
    #expect(!loaded.developerSoundPackV2Enabled)
    #expect(!loaded.developerHapticsV2Enabled)
    #expect(!loaded.developerVIPParticlesEnabled)
    #expect(!loaded.developerCellPhysicsEnabled)
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
    settings.developerLiquidGlassEnabled = true
    settings.developerGlassVIPEnabled = true
    settings.developerMetalAuroraEnabled = true
    settings.developerSoundPackV2Enabled = true
    settings.developerHapticsV2Enabled = true
    settings.developerVIPParticlesEnabled = true
    settings.developerCellPhysicsEnabled = true
    settings.developerAssistantObjectEnabled = true

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
    #expect(!loaded.developerLiquidGlassEnabled)
    #expect(!loaded.developerGlassVIPEnabled)
    #expect(!loaded.developerMetalAuroraEnabled)
    #expect(!loaded.developerSoundPackV2Enabled)
    #expect(!loaded.developerHapticsV2Enabled)
    #expect(!loaded.developerVIPParticlesEnabled)
    #expect(!loaded.developerCellPhysicsEnabled)
    #expect(!loaded.developerAssistantObjectEnabled)
}
