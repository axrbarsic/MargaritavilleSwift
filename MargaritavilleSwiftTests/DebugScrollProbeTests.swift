import Foundation
import Testing
@testable import MargaritavilleSwift

@Suite
struct DebugScrollProbeTests {
#if DEBUG
    @Test
    func policyRequiresExactOptInValue() {
        #expect(
            DebugScrollProbePolicy(
                environment: ["MARGARITAVILLE_SCROLL_PROBE": "1"]
            ).isRequested
        )
        #expect(
            !DebugScrollProbePolicy(
                environment: ["MARGARITAVILLE_SCROLL_PROBE": "true"]
            ).isRequested
        )
        #expect(!DebugScrollProbePolicy(environment: [:]).isRequested)
    }

    @Test
    func accumulatorUsesOnlyActiveCallbackDeltasAcrossSegments() throws {
        var accumulator = DebugScrollProbeAccumulator(
            capacity: 16,
            displayMaximumFramesPerSecond: 120,
            runID: "test-run",
            systemState: testScrollProbeSystemState
        )

        accumulator.recordCallback(at: 0)
        accumulator.beginActiveSegment()
        accumulator.recordCallback(at: 1)
        accumulator.recordCallback(at: 1.008, targetTimestampInterval: 1.0 / 120.0)
        accumulator.recordCallback(at: 1.007)
        accumulator.recordCallback(at: 1.025, targetTimestampInterval: 1.0 / 120.0)
        let firstResultValue = accumulator.endActiveSegment(
            generatedAt: Date(timeIntervalSince1970: 100)
        )
        let firstResult = try #require(firstResultValue)

        #expect(firstResult.sampleCount == 2)
        #expect(firstResult.activeSegmentCount == 1)

        accumulator.recordCallback(at: 5)
        accumulator.beginActiveSegment()
        accumulator.recordCallback(at: 10)
        accumulator.recordCallback(at: 10.010, targetTimestampInterval: 1.0 / 60.0)
        accumulator.updateSystemState(
            DebugScrollProbeSystemState(
                minimumFrameDurationDisabledOnPhone: true,
                lowPowerModeEnabled: true,
                thermalState: "fair",
                activeMaximumFramesPerSecond: 60
            )
        )
        let resultValue = accumulator.endActiveSegment(
            generatedAt: Date(timeIntervalSince1970: 200)
        )
        let result = try #require(resultValue)

        #expect(result.runID == "test-run")
        #expect(result.schemaVersion == 2)
        #expect(result.minimumFrameDurationDisabledOnPhone)
        #expect(result.lowPowerModeEnabled)
        #expect(result.thermalState == "fair")
        #expect(result.activeMaximumFramesPerSecond == 60)
        #expect(result.targetTimestampIntervalSampleCount == 3)
        #expect(abs(result.targetTimestampIntervalMilliseconds - (1_000 / 120)) < 0.000_001)
        #expect(result.sampleCount == 3)
        #expect(result.activeSegmentCount == 2)
        #expect(abs(result.sampledDurationSeconds - 0.035) < 0.000_001)
        #expect(abs(result.medianIntervalMilliseconds - 10) < 0.000_001)
        #expect(abs(result.p95IntervalMilliseconds - 17) < 0.000_001)
        #expect(abs(result.p99IntervalMilliseconds - 17) < 0.000_001)
        #expect(abs(result.maxIntervalMilliseconds - 17) < 0.000_001)
        #expect(abs(result.effectiveFramesPerSecond - (3 / 0.035)) < 0.000_001)
        #expect(result.intervalsOverBudgetCount == 2)
        #expect(result.intervalsOverOnePointFiveTimesBudgetCount == 1)
        #expect(result.intervalsOverTwoTimesBudgetCount == 1)
        #expect(result.droppedSampleCount == 0)
    }

    @Test
    func accumulatorReportsMedianAndTailPercentiles() throws {
        var accumulator = DebugScrollProbeAccumulator(
            capacity: 16,
            runID: "percentiles",
            systemState: testScrollProbeSystemState
        )
        let intervals: [TimeInterval] = [0.008, 0.008, 0.009, 0.010, 0.020]
        var timestamp: TimeInterval = 50

        accumulator.beginActiveSegment()
        accumulator.recordCallback(at: timestamp)
        for interval in intervals {
            timestamp += interval
            accumulator.recordCallback(at: timestamp)
        }
        let resultValue = accumulator.endActiveSegment()
        let result = try #require(resultValue)

        #expect(result.sampleCount == 5)
        #expect(abs(result.medianIntervalMilliseconds - 9) < 0.000_001)
        #expect(abs(result.p95IntervalMilliseconds - 20) < 0.000_001)
        #expect(abs(result.p99IntervalMilliseconds - 20) < 0.000_001)
        #expect(abs(result.maxIntervalMilliseconds - 20) < 0.000_001)
    }

    @Test
    func accumulatorCapsItsPreallocatedSampleBuffer() throws {
        var accumulator = DebugScrollProbeAccumulator(
            capacity: 2,
            runID: "capacity",
            systemState: testScrollProbeSystemState
        )

        accumulator.beginActiveSegment()
        accumulator.recordCallback(at: 0)
        accumulator.recordCallback(at: 0.010)
        accumulator.recordCallback(at: 0.020)
        accumulator.recordCallback(at: 0.030)
        let resultValue = accumulator.endActiveSegment()
        let result = try #require(resultValue)

        #expect(result.sampleCount == 2)
        #expect(result.droppedSampleCount == 1)
    }

    @Test
    func thermalStateLabelsAreStableJSONValues() {
        #expect(DebugScrollProbeSystemState.thermalStateLabel(.nominal) == "nominal")
        #expect(DebugScrollProbeSystemState.thermalStateLabel(.fair) == "fair")
        #expect(DebugScrollProbeSystemState.thermalStateLabel(.serious) == "serious")
        #expect(DebugScrollProbeSystemState.thermalStateLabel(.critical) == "critical")
    }
#endif
}

#if DEBUG
private let testScrollProbeSystemState = DebugScrollProbeSystemState(
    minimumFrameDurationDisabledOnPhone: true,
    lowPowerModeEnabled: false,
    thermalState: "nominal",
    activeMaximumFramesPerSecond: 120
)
#endif
