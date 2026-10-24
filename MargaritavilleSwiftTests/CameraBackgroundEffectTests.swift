import AVFoundation
import Foundation
import QuartzCore
import Testing
@testable import MargaritavilleSwift

@Test
func everyCameraEffectSitsInExactlyOneCategoryWithUniqueShaderBranch() {
    let categorized = CameraEffectCategory.allCases.flatMap(\.effects)
    #expect(categorized.count == CameraBackgroundEffect.allCases.count)
    #expect(Set(categorized) == Set(CameraBackgroundEffect.allCases))
    #expect(Set(CameraBackgroundEffect.allCases.map(\.shaderIndex)).count == CameraBackgroundEffect.allCases.count)
    #expect(CameraBackgroundEffect.normal.shaderIndex == 0)
    #expect(CameraBackgroundEffect.metal.category == .relief)
    #expect(CameraBackgroundEffect.neon.category == .neon)
    for effect in CameraBackgroundEffect.allCases {
        #expect(!effect.title.isEmpty)
        #expect(!effect.subtitle.isEmpty)
    }
}

@Test
func cameraEffectsKeepStoredValuesOfUnmergedEffects() {
    for raw in ["normal", "pixels", "thermal", "lego", "cartoon", "emboss", "stoneRelief", "paperRelief", "woodRelief", "neonShadow"] {
        #expect(CameraBackgroundEffect(rawValue: raw) != nil)
    }
    #expect(CameraBackgroundEffect.allCases.filter { $0.prefilter == .blur } == [.matte])
    #expect(CameraBackgroundEffect.allCases.filter { $0.prefilter == .median } == [.cartoon, .periodicMetals])
    #expect(CameraBackgroundEffect.periodicMetals.category == .relief && CameraBackgroundEffect.periodicMetals.usesRelief)
}

@Test
func mergedCameraEffectsMigrateToMetalAndNeonWithMatchingSettings() {
    let cases: [(String, CameraBackgroundEffect)] = [
        ("goldRelief", .metal), ("silverRelief", .metal), ("copperRelief", .metal),
        ("liveRelief", .metal), ("neonEdges", .neon), ("neonGlow", .neon), ("unknownEffect", .normal)
    ]
    for (stored, expected) in cases {
        let suite = "CameraEffectMigration-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(stored, forKey: CameraBackgroundEffect.storageKey)
        CameraEffectMigration.migrate(defaults)
        #expect(defaults.string(forKey: CameraBackgroundEffect.storageKey) == expected.rawValue)
        if stored == "silverRelief" {
            #expect(defaults.double(forKey: CameraEffectTuning.Keys.metalSaturation) == 0)
        }
        if stored == "liveRelief" {
            #expect(defaults.bool(forKey: CameraEffectTuning.Keys.liveLight))
        }
        if stored == "neonEdges" {
            #expect(defaults.double(forKey: CameraEffectTuning.Keys.glowAmount) == 0)
        }
    }
}

@Test
func cameraEffectUniformsMatchMetalStructLayout() {
    // float2, float2, float, uint и десять float настроек = 64 байта.
    #expect(MemoryLayout<CameraEffectUniforms>.stride == 64)
}

@Test
func cameraRenderTargetStoresSelectedEffect() {
    let target = CameraRenderTarget(layer: CAMetalLayer())
    #expect(target.effect == .normal)
    target.effect = .thermal
    #expect(target.effect == .thermal)
}

@Test
func cameraPositionKeepsStableValuesAndMirrorsOnlyFront() {
    #expect(CameraBackgroundPosition.allCases.map(\.rawValue) == ["back", "front"])
    #expect(CameraBackgroundPosition.back.devicePosition == .back)
    #expect(CameraBackgroundPosition.front.devicePosition == .front)
    #expect(CameraBackgroundPosition.allCases.filter(\.isMirrored) == [.front])
}

@Test
func cameraEffectTuningClampsValuesAndConvertsToShaderUnits() {
    let wild = CameraEffectTuning(
        amount: 7, brightness: -1, reliefDepth: .nan, lightAngle: 400,
        edgeSensitivity: 0, detailScale: 9, metalHue: -20, metalSaturation: 3, liveLight: true, glowAmount: 5
    )
    let clamped = wild.clamped
    #expect(clamped.amount == 1)
    #expect(clamped.brightness == CameraEffectTuning.brightnessRange.lowerBound)
    #expect(clamped.reliefDepth == CameraEffectTuning.reliefDepthRange.lowerBound)
    #expect(clamped.lightAngle == 360)
    #expect(clamped.edgeSensitivity == CameraEffectTuning.edgeSensitivityRange.lowerBound)
    #expect(clamped.detailScale == CameraEffectTuning.detailScaleRange.upperBound)
    #expect(clamped.metalHue == 0)
    #expect(clamped.metalSaturation == 1)
    #expect(clamped.glowAmount == 1)

    let uniforms = CameraEffectUniforms(viewSize: .zero, textureSize: .zero, time: 0, effect: 0, tuning: .default)
    #expect(abs(uniforms.lightAngle - Float(225.0 * .pi / 180)) < 0.0001)
    #expect(abs(uniforms.metalHue - Float(42.0 / 360)) < 0.0001)
    #expect(uniforms.liveLight == 0)
}

@Test
func cameraEffectSlidersMatchTheEffectsTheyChange() {
    #expect(CameraBackgroundEffect.metal.usesRelief && CameraBackgroundEffect.metal.usesMetalColor)
    #expect(CameraBackgroundEffect.emboss.usesRelief && !CameraBackgroundEffect.emboss.usesMetalColor)
    #expect(CameraBackgroundEffect.neon.usesEdges && CameraBackgroundEffect.neon.usesGlow)
    #expect(CameraBackgroundEffect.lego.usesDetailScale)
    #expect(!CameraBackgroundEffect.normal.usesRelief && !CameraBackgroundEffect.normal.usesEdges && !CameraBackgroundEffect.normal.usesDetailScale)
}

@Test
func metalNamesFollowHueAndSaturation() {
    #expect(CameraEffectTuning.metalName(hue: 42, saturation: 0) == "Серебро")
    #expect(CameraEffectTuning.metalName(hue: 42, saturation: 0.75) == "Золото")
    #expect(CameraEffectTuning.metalName(hue: 15, saturation: 0.7) == "Медь")
    #expect(CameraEffectTuning.metalName(hue: 210, saturation: 0.6) == "Синяя сталь")
    #expect(CameraEffectTuning.metalName(hue: 340, saturation: 0.6) == "Розовое золото")
}
