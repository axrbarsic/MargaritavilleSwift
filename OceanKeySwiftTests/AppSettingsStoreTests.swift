import Foundation
import Testing
@testable import OceanKeySwift

@Test
func appSettingsPersistsMatrixColorRichness() {
    let suiteName = "AppSettingsStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.matrixColorRichness = 2.05

    let loaded = AppSettingsStore.load(userDefaults: defaults)

    #expect(loaded.matrixColorRichness == 2.05)
    #expect(loaded.matrixConfiguration == MatrixRainConfiguration(colorRichness: 2.05))
}

@Test
func appSettingsClampsMatrixColorRichness() {
    let settings = AppSettingsStore(matrixColorRichness: 9)

    #expect(settings.matrixColorRichness == 2.40)
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
