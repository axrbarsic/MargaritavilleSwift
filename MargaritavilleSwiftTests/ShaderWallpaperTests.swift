import Foundation
import Testing
@testable import MargaritavilleSwift

@Test
func everyShaderWallpaperHasItsOwnBackgroundModeAndShader() {
    let mapped = AppBackgroundMode.allCases.compactMap(\.shaderWallpaper)
    #expect(mapped == ShaderWallpaperKind.allCases)
    #expect(Set(ShaderWallpaperKind.allCases.map(\.shaderFunctionName)).count == ShaderWallpaperKind.allCases.count)
    #expect(AppBackgroundMode.brooklyn.shaderWallpaper == nil)
    for mode in AppBackgroundMode.allCases where mode.shaderWallpaper != nil {
        #expect(!mode.title.isEmpty)
        #expect(!mode.description.isEmpty)
    }
}

@Test
func appSettingsPersistsShaderWallpaperModes() {
    let suiteName = "ShaderWallpaperTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    for mode in AppBackgroundMode.allCases where mode.shaderWallpaper != nil {
        let settings = AppSettingsStore(userDefaults: defaults)
        settings.appBackgroundMode = mode
        #expect(AppSettingsStore.load(userDefaults: defaults).appBackgroundMode == mode)
    }
}

@Test
func shaderWallpaperFrameBudgetSleepsWhenIdleAndSavesPower() {
    let active = ShaderWallpaperFramePolicy(isSceneActive: true, isLowPowerModeEnabled: false, reduceMotion: false)
    #expect(active.minimumInterval == 1.0 / 30.0)
    #expect(!active.isPaused)

    let lowPower = ShaderWallpaperFramePolicy(isSceneActive: true, isLowPowerModeEnabled: true, reduceMotion: false)
    #expect(lowPower.minimumInterval == 1.0 / 15.0)

    #expect(ShaderWallpaperFramePolicy(isSceneActive: false, isLowPowerModeEnabled: false, reduceMotion: false).isPaused)
    #expect(ShaderWallpaperFramePolicy(isSceneActive: true, isLowPowerModeEnabled: false, reduceMotion: true).isPaused)
}
