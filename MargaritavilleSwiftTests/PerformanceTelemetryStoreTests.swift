import Testing
@testable import MargaritavilleSwift

@MainActor
@Test
func performanceTelemetryAggregatesFramesBySecond() {
    let telemetry = PerformanceTelemetryStore(targetFPS: 120)

    for frame in 0...120 {
        telemetry.recordFrameForTesting(
            duration: 1.0 / 120.0,
            timestamp: Double(frame) / 120.0
        )
    }

    #expect((120...121).contains(telemetry.currentFPS))
    #expect(telemetry.recentSlowFrames == 0)
    #expect(telemetry.totalSlowFrames == 0)
}

@MainActor
@Test
func performanceTelemetryCountsSlowFrames() {
    let telemetry = PerformanceTelemetryStore(targetFPS: 120)

    for frame in 0...120 {
        telemetry.recordFrameForTesting(
            duration: frame < 3 ? 1.0 / 30.0 : 1.0 / 120.0,
            timestamp: Double(frame) / 120.0
        )
    }

    #expect(telemetry.recentSlowFrames == 3)
    #expect(telemetry.totalSlowFrames == 3)
    #expect(telemetry.recentWorstFrameMS > 30)
}
