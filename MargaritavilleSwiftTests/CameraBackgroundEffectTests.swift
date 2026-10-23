import Foundation
import QuartzCore
import Testing
@testable import MargaritavilleSwift

@Test
func cameraEffectsKeepStableStorageValuesAndShaderOrder() {
    #expect(CameraBackgroundEffect.allCases.map(\.rawValue) == [
        "normal", "matte", "grid", "nightVision", "thermal", "neonEdges", "comic", "pixels",
        "ascii", "dither", "halftone", "gameBoy", "crt", "sketch", "kaleidoscope", "glitch",
        "timeScan", "echo", "matrixRain", "anaglyph", "xray", "vaporwave", "mirror", "hologram"
    ])
    #expect(CameraBackgroundEffect.allCases.map(\.shaderIndex) == Array(0..<24))
    // Номера веток шейдера с историей кадров зашиты в cameraHistoryFragment.
    #expect(CameraBackgroundEffect.timeScan.shaderIndex == 16)
    #expect(CameraBackgroundEffect.allCases.filter(\.needsHistory) == [.timeScan, .echo])
    #expect(CameraBackgroundEffect.allCases.filter(\.needsBlur) == [.matte])
    for effect in CameraBackgroundEffect.allCases {
        #expect(!effect.title.isEmpty)
        #expect(!effect.subtitle.isEmpty)
    }
}

@Test
func cameraEffectUniformsMatchMetalStructLayout() {
    // float2, float2, float, uint, float, float, uint, float = 40 байт.
    #expect(MemoryLayout<CameraEffectUniforms>.stride == 40)
}

@Test
func cameraRenderTargetStoresSelectedEffect() {
    let target = CameraRenderTarget(layer: CAMetalLayer())
    #expect(target.effect == .normal)
    target.effect = .thermal
    #expect(target.effect == .thermal)
}

@Test
func timeScanSweepsDownThenHoldsFrozenFrame() {
    #expect(CameraTimeScanTiming.line(elapsed: 0) == 0)
    #expect(abs(CameraTimeScanTiming.line(elapsed: 2.5) - 0.5) < 0.0001)
    #expect(CameraTimeScanTiming.line(elapsed: 5) == 1)
    #expect(CameraTimeScanTiming.line(elapsed: 7) == 1)
    #expect(CameraTimeScanTiming.line(elapsed: 7.5) == 0)
}
