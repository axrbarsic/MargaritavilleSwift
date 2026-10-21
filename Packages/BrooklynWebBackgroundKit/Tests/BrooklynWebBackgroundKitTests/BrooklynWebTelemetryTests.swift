import Foundation
import Testing
@testable import BrooklynWebBackgroundKit

@Test func telemetryDecodesAndPersistsAtomically() throws {
    let body: [String: Any] = [
        "activeDurationMS": 30_004.5,
        "activeSegmentCount": 1,
        "durationMS": 30_004.5,
        "endedVisibilityState": "visible",
        "frameCount": 1_801,
        "legacyRAFActiveIntervalCount": 1_800,
        "legacyRAFEffectiveCadenceHz": 59.99,
        "legacyRAFObservedActiveMS": 30_004.5,
        "manualAdvanceActiveIntervalCount": 3_570,
        "manualAdvanceEffectiveCadenceHz": 118.98,
        "manualAdvanceP99MS": 12.1,
        "manualAdvanceStallCount": 0,
        "manualSchedulerDroppedSlots": 29,
        "maximumMS": 41.7,
        "medianCadenceHz": 59.99,
        "medianMS": 16.67,
        "nativeDisplayLinkActiveIntervalCount": 3_590,
        "nativeDisplayLinkEffectiveCadenceHz": 119.65,
        "nativeDisplayLinkObservedActiveMS": 30_004.1,
        "nativeDisplayLinkP99MS": 8.7,
        "nativeDisplayLinkRunLoopMode": "common",
        "p99MS": 17.2,
        "presentationMeasured": false,
        "requestedDurationMS": 30_000,
        "sampleCount": 1_800,
        "sceneGridDrawCalls": 1,
        "sceneInstanceCount": 928,
        "stallThresholdMS": 25.0,
        "stalls": 2,
        "startedVisibilityState": "visible",
        "suspendedDurationMS": 0.0,
        "suspensionCount": 0,
        "suspensionReasons": [String](),
        "transformMotionActiveIntervalCount": 3_565,
        "transformMotionEffectiveCadenceHz": 118.81,
        "transformMotionP99MS": 12.2,
        "version": 3,
        "visibilityState": "visible",
        "wallDurationMS": 30_004.5
    ]
    let report = try BrooklynWebTelemetryStore.decode(messageBody: body)
    #expect(report.frameCount == 1_801)
    #expect(report.medianMS == 16.67)
    #expect(report.manualAdvanceEffectiveCadenceHz == 118.98)
    #expect(report.nativeDisplayLinkRunLoopMode == "common")
    #expect(report.presentationMeasured == false)
    #expect(report.sceneInstanceCount == 928)
    #expect(report.suspensionReasons == [])

    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let suiteName = "BrooklynWebBackgroundKitTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer {
        try? FileManager.default.removeItem(at: directory)
        defaults.removePersistentDomain(forName: suiteName)
    }

    let destination = try BrooklynWebTelemetryStore.persist(
        report,
        directory: directory,
        userDefaults: defaults
    )
    #expect(destination.lastPathComponent == "latest-telemetry.json")
    #expect(try BrooklynWebTelemetryStore.load(from: directory) == report)
    #expect(defaults.data(forKey: BrooklynWebTelemetryStore.userDefaultsKey) != nil)
}

@Test func telemetryRequestIsExplicitAndBounded() {
    #expect(BrooklynWebTelemetryRequest.durationMS(environment: [:]) == nil)
    #expect(BrooklynWebTelemetryRequest.durationMS(environment: [
        "BROOKLYN_WEB_PERFORMANCE_SWEEP": "1"
    ]) == 30_000)
    #expect(BrooklynWebTelemetryRequest.durationMS(environment: [
        "BROOKLYN_WEB_PERFORMANCE_SWEEP": "1",
        "BROOKLYN_WEB_TELEMETRY_SECONDS": "120"
    ]) == 60_000)
}

@Test func privateHighRefreshRequestIsExplicitAndDebugOnly() {
    #if DEBUG
    #expect(!BrooklynWebHighRefreshRequest.isEnabled(environment: [:]))
    #expect(BrooklynWebHighRefreshRequest.isEnabled(environment: [
        "BROOKLYN_WEB_PRIVATE_120HZ": "1"
    ]))
    #else
    #expect(!BrooklynWebHighRefreshRequest.isEnabled(environment: [
        "BROOKLYN_WEB_PRIVATE_120HZ": "1"
    ]))
    #endif
}
