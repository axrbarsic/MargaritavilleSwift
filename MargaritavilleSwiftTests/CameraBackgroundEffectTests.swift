import AVFoundation
import Foundation
import QuartzCore
import Testing
@testable import MargaritavilleSwift

@Test
func cameraEffectsKeepStableStorageValuesAndShaderOrder() {
    #expect(CameraBackgroundEffect.allCases.map(\.rawValue) == [
        "normal", "matte", "grid", "nightVision", "thermal", "neonEdges", "comic", "pixels",
        "ascii", "dither", "halftone", "gameBoy", "crt", "sketch", "kaleidoscope", "glitch",
        "cartoon", "lego",
        "neonShadow", "neonGlow", "tron", "blueprint", "chalk", "electric", "emboss",
        "goldRelief", "silverRelief", "copperRelief", "stoneRelief", "paperRelief", "woodRelief", "liveRelief"
    ])
    #expect(CameraBackgroundEffect.allCases.map(\.shaderIndex) == Array(0..<32))
    #expect(CameraBackgroundEffect.allCases.filter { $0.prefilter == .blur } == [.matte])
    #expect(CameraBackgroundEffect.allCases.filter { $0.prefilter == .median } == [.cartoon])
    for effect in CameraBackgroundEffect.allCases {
        #expect(!effect.title.isEmpty)
        #expect(!effect.subtitle.isEmpty)
    }
}

@Test
func cameraEffectUniformsMatchMetalStructLayout() {
    // float2, float2, float, uint и шесть float настроек = 48 байт.
    #expect(MemoryLayout<CameraEffectUniforms>.stride == 48)
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
func cameraEffectTuningClampsValuesAndConvertsLightToRadians() {
    let wild = CameraEffectTuning(amount: 7, brightness: -1, reliefDepth: .nan, lightAngle: 400, edgeSensitivity: 0, detailScale: 9)
    let clamped = wild.clamped
    #expect(clamped.amount == 1)
    #expect(clamped.brightness == CameraEffectTuning.brightnessRange.lowerBound)
    #expect(clamped.reliefDepth == CameraEffectTuning.reliefDepthRange.lowerBound)
    #expect(clamped.lightAngle == 360)
    #expect(clamped.edgeSensitivity == CameraEffectTuning.edgeSensitivityRange.lowerBound)
    #expect(clamped.detailScale == CameraEffectTuning.detailScaleRange.upperBound)

    let uniforms = CameraEffectUniforms(viewSize: .zero, textureSize: .zero, time: 0, effect: 0, tuning: .default)
    #expect(abs(uniforms.lightAngle - Float(225.0 * .pi / 180)) < 0.0001)
}

@Test
func cameraEffectSlidersMatchTheEffectsTheyChange() {
    #expect(CameraBackgroundEffect.goldRelief.usesRelief)
    #expect(CameraBackgroundEffect.emboss.usesLightAngle)
    #expect(!CameraBackgroundEffect.liveRelief.usesLightAngle)
    #expect(CameraBackgroundEffect.neonEdges.usesEdges)
    #expect(CameraBackgroundEffect.lego.usesDetailScale)
    #expect(!CameraBackgroundEffect.normal.usesRelief && !CameraBackgroundEffect.normal.usesEdges && !CameraBackgroundEffect.normal.usesDetailScale)
}
