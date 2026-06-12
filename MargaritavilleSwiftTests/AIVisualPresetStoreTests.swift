import Foundation
import Testing
@testable import MargaritavilleSwift

@MainActor
@Test
func aiVisualPresetStoreSavesAndReloadsPreset() throws {
    let store = try AIVisualPresetStore(inMemory: true)
    let draft = AIVisualPresetDraft(
        title: "Кодовый дождь",
        summary: "Swift-код падает как зелёная матрица.",
        kind: .matrixCodeRain,
        payload: .matrixDefault
    )

    store.save(draft: draft, modelTier: .pro, prompt: "swift code rain")

    #expect(store.presets.count == 1)
    #expect(store.presets.first?.title == "Кодовый дождь")
    #expect(store.presets.first?.kind == .matrixCodeRain)
    #expect(store.presets.first?.modelTier == .pro)
    #expect(store.presets.first?.payload == .matrixDefault)
}

@MainActor
@Test
func aiVisualPresetStoreReportsStorageModeExplicitly() throws {
    let memoryStore = try AIVisualPresetStore(inMemory: true)
    #expect(memoryStore.storageMode == .memoryOnly)
    #expect(memoryStore.storageMode.isAppleSynced == false)

    let fallbackStore = try AIVisualPresetStore(localFallbackReason: "Provisioning profile is missing iCloud.")
    #expect(fallbackStore.storageMode.isAppleSynced == false)
    #expect(fallbackStore.storageMode.statusTitle == "Apple sync недоступен")
}

@MainActor
@Test
func presetBackupPayloadContainsPresetsAndBackgroundConfiguration() throws {
    let preset = AIVisualPreset(
        id: UUID(),
        title: "Matrix",
        summary: "Generated code rain.",
        kind: .matrixCodeRain,
        payload: .matrixDefault,
        modelTier: .pro,
        prompt: "green swift rain",
        isFavorite: true,
        createdAt: Date(timeIntervalSince1970: 10),
        updatedAt: Date(timeIntervalSince1970: 11)
    )
    let appSettings = AppSettingsStore(
        appBackgroundMode: .video,
        matrixSpeed: 2.25,
        backgroundVideoRelativePath: "Background/video-wallpaper.mov",
        backgroundVideoBlur: 0.64,
        backgroundVideoBrightness: -0.12,
        backgroundVideoGreenTint: 0.91,
        backgroundVideoGridIntensity: 0.38,
        userDefaults: try temporaryUserDefaults()
    )

    let payload = MargaritavillePresetBackupPayload.make(
        presets: [preset],
        appSettings: appSettings,
        exportedAt: Date(timeIntervalSince1970: 100)
    )
    let data = try JSONEncoder().encode(payload)
    let decoded = try JSONDecoder().decode(MargaritavillePresetBackupPayload.self, from: data)

    #expect(decoded.schemaVersion == 1)
    #expect(decoded.presets == [preset])
    #expect(decoded.background.mode == .video)
    #expect(decoded.background.videoFilename == "video-wallpaper.mov")
    #expect(decoded.background.videoBlur == 0.64)
    #expect(decoded.background.videoGreenTint == 0.91)
    #expect(decoded.background.videoGridIntensity == 0.38)
}

@Test
func deepSeekPresetDecodeClampsPayloadAndKeepsRequestedKind() throws {
    let content = """
    {
      "title": "VIP",
      "summary": "Пульсирующий VIP эффект.",
      "kind": "matrixCodeRain",
      "payload": {
        "palette": "status_adaptive",
        "speed": 99,
        "glow": -1,
        "blur": 4,
        "density": 2,
        "glyphSource": "none",
        "motion": "organic_status_pulse",
        "seed": 42
      }
    }
    """

    let draft = try DeepSeekClient.decodePreset(content, fallbackKind: .vipEffect)

    #expect(draft.kind == .vipEffect)
    #expect(draft.payload.speed == 3.0)
    #expect(draft.payload.glow == 0)
    #expect(draft.payload.blur == 1)
    #expect(draft.payload.density == 1)
}

private func temporaryUserDefaults() throws -> UserDefaults {
    let suiteName = "MargaritavilleSwiftTests.\(UUID().uuidString)"
    guard let userDefaults = UserDefaults(suiteName: suiteName) else {
        throw CocoaError(.fileNoSuchFile)
    }
    userDefaults.removePersistentDomain(forName: suiteName)
    return userDefaults
}
