import Testing
@testable import OceanKeySwift

@Test
func runtimeDiagnosticsReadsProMotionOptIn() {
    #expect(RuntimeDiagnostics.proMotionOptIn(infoDictionary: ["CADisableMinimumFrameDurationOnPhone": true]))
    #expect(!RuntimeDiagnostics.proMotionOptIn(infoDictionary: [:]))
}

@Test
func runtimeDiagnosticsFormatsFrameRateStatus() {
    let label = RuntimeDiagnostics.proMotionStatusLabel(
        maximumFramesPerSecond: 120,
        infoDictionary: ["CADisableMinimumFrameDurationOnPhone": true]
    )

    #expect(label == "вкл, до 120 Гц")
}
