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
    // float2 viewSize, float2 textureSize, float time, uint effect = 24 байта.
    #expect(MemoryLayout<CameraEffectUniforms>.stride == 24)
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
