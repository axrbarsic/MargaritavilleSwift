import Foundation
import QuartzCore
import Testing
@testable import MargaritavilleSwift

@Test
func cameraEffectsKeepStableStorageValuesAndShaderOrder() {
    #expect(CameraBackgroundEffect.allCases.map(\.rawValue) == [
        "normal", "matte", "grid", "nightVision", "thermal", "neonEdges", "comic", "pixels"
    ])
    #expect(CameraBackgroundEffect.allCases.map(\.shaderIndex) == Array(0..<8))
    #expect(CameraBackgroundEffect.allCases.filter(\.needsBlur) == [.matte])
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
