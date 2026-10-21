#if DEBUG
import Foundation
import UIKit

struct DebugScrollProbePolicy: Equatable, Sendable {
    static let environmentKey = "MARGARITAVILLE_SCROLL_PROBE"

    let isRequested: Bool

    init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        isRequested = environment[Self.environmentKey] == "1"
    }
}

struct DebugScrollProbeSystemState: Equatable, Sendable {
    let minimumFrameDurationDisabledOnPhone: Bool
    let lowPowerModeEnabled: Bool
    let thermalState: String
    let activeMaximumFramesPerSecond: Int

    @MainActor
    static func current(
        processInfo: ProcessInfo = .processInfo,
        infoDictionary: [String: Any] = Bundle.main.infoDictionary ?? [:],
        activeMaximumFramesPerSecond: Int = UIScreen.main.maximumFramesPerSecond
    ) -> DebugScrollProbeSystemState {
        DebugScrollProbeSystemState(
            minimumFrameDurationDisabledOnPhone:
                infoDictionary["CADisableMinimumFrameDurationOnPhone"] as? Bool == true,
            lowPowerModeEnabled: processInfo.isLowPowerModeEnabled,
            thermalState: thermalStateLabel(processInfo.thermalState),
            activeMaximumFramesPerSecond: activeMaximumFramesPerSecond
        )
    }

    static func thermalStateLabel(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal:
            "nominal"
        case .fair:
            "fair"
        case .serious:
            "serious"
        case .critical:
            "critical"
        @unknown default:
            "unknown"
        }
    }
}

struct DebugScrollProbeResult: Codable, Equatable, Sendable {
    let schemaVersion: Int
    let runID: String
    let generatedAt: Date
    let displayMaximumFramesPerSecond: Int
    let preferredFramesPerSecond: Int
    let minimumFrameDurationDisabledOnPhone: Bool
    let lowPowerModeEnabled: Bool
    let thermalState: String
    let activeMaximumFramesPerSecond: Int
    let targetTimestampIntervalSampleCount: Int
    let targetTimestampIntervalMilliseconds: Double
    let activeSegmentCount: Int
    let sampleCount: Int
    let sampledDurationSeconds: Double
    let frameBudgetMilliseconds: Double
    let medianIntervalMilliseconds: Double
    let p95IntervalMilliseconds: Double
    let p99IntervalMilliseconds: Double
    let maxIntervalMilliseconds: Double
    let effectiveFramesPerSecond: Double
    let intervalsOverBudgetCount: Int
    let intervalsOverOnePointFiveTimesBudgetCount: Int
    let intervalsOverTwoTimesBudgetCount: Int
    let droppedSampleCount: Int
}

struct DebugScrollProbeAccumulator: Sendable {
    static let preferredFramesPerSecond = 120
    static let frameBudget: TimeInterval = 1.0 / 120.0

    private let capacity: Int
    private let displayMaximumFramesPerSecond: Int
    private let runID: String
    private var intervals: [TimeInterval]
    private var targetTimestampIntervals: [TimeInterval]
    private var systemState: DebugScrollProbeSystemState
    private var lastCallbackTimestamp: TimeInterval?
    private var segmentStartingSampleCount = 0
    private var completedSegmentCount = 0
    private var droppedSampleCount = 0
    private(set) var isActive = false

    init(
        capacity: Int = 16_384,
        displayMaximumFramesPerSecond: Int = 120,
        runID: String = UUID().uuidString,
        systemState: DebugScrollProbeSystemState
    ) {
        self.capacity = max(capacity, 1)
        self.displayMaximumFramesPerSecond = max(displayMaximumFramesPerSecond, 1)
        self.runID = runID
        self.systemState = systemState
        intervals = []
        intervals.reserveCapacity(self.capacity)
        targetTimestampIntervals = []
        targetTimestampIntervals.reserveCapacity(self.capacity)
    }

    mutating func updateSystemState(_ systemState: DebugScrollProbeSystemState) {
        self.systemState = systemState
    }

    mutating func beginActiveSegment() {
        guard !isActive else { return }
        isActive = true
        lastCallbackTimestamp = nil
        segmentStartingSampleCount = intervals.count
    }

    mutating func recordCallback(
        at timestamp: TimeInterval,
        targetTimestampInterval: TimeInterval? = nil
    ) {
        guard isActive, timestamp.isFinite else { return }
        guard let previousTimestamp = lastCallbackTimestamp else {
            lastCallbackTimestamp = timestamp
            return
        }
        guard timestamp > previousTimestamp else { return }
        lastCallbackTimestamp = timestamp

        let interval = timestamp - previousTimestamp
        guard interval.isFinite, interval > 0 else { return }
        guard intervals.count < capacity else {
            droppedSampleCount += 1
            return
        }
        intervals.append(interval)
        if let targetTimestampInterval,
           targetTimestampInterval.isFinite,
           targetTimestampInterval > 0,
           targetTimestampIntervals.count < capacity
        {
            targetTimestampIntervals.append(targetTimestampInterval)
        }
    }

    mutating func endActiveSegment(
        generatedAt: Date = Date()
    ) -> DebugScrollProbeResult? {
        guard isActive else { return nil }
        isActive = false
        lastCallbackTimestamp = nil
        guard intervals.count > segmentStartingSampleCount else { return nil }
        completedSegmentCount += 1
        return makeResult(generatedAt: generatedAt)
    }

    private func makeResult(generatedAt: Date) -> DebugScrollProbeResult {
        let sortedIntervals = intervals.sorted()
        let sortedTargetTimestampIntervals = targetTimestampIntervals.sorted()
        let duration = intervals.reduce(0, +)
        let budget = Self.frameBudget

        return DebugScrollProbeResult(
            schemaVersion: 2,
            runID: runID,
            generatedAt: generatedAt,
            displayMaximumFramesPerSecond: displayMaximumFramesPerSecond,
            preferredFramesPerSecond: Self.preferredFramesPerSecond,
            minimumFrameDurationDisabledOnPhone:
                systemState.minimumFrameDurationDisabledOnPhone,
            lowPowerModeEnabled: systemState.lowPowerModeEnabled,
            thermalState: systemState.thermalState,
            activeMaximumFramesPerSecond: systemState.activeMaximumFramesPerSecond,
            targetTimestampIntervalSampleCount: targetTimestampIntervals.count,
            targetTimestampIntervalMilliseconds:
                median(sortedTargetTimestampIntervals) * 1_000,
            activeSegmentCount: completedSegmentCount,
            sampleCount: intervals.count,
            sampledDurationSeconds: duration,
            frameBudgetMilliseconds: budget * 1_000,
            medianIntervalMilliseconds: median(sortedIntervals) * 1_000,
            p95IntervalMilliseconds: percentile(0.95, sortedIntervals) * 1_000,
            p99IntervalMilliseconds: percentile(0.99, sortedIntervals) * 1_000,
            maxIntervalMilliseconds: (sortedIntervals.last ?? 0) * 1_000,
            effectiveFramesPerSecond: duration > 0 ? Double(intervals.count) / duration : 0,
            intervalsOverBudgetCount: intervals.count { $0 > budget },
            intervalsOverOnePointFiveTimesBudgetCount: intervals.count {
                $0 > budget * 1.5
            },
            intervalsOverTwoTimesBudgetCount: intervals.count {
                $0 > budget * 2
            },
            droppedSampleCount: droppedSampleCount
        )
    }

    private func median(_ sortedValues: [TimeInterval]) -> TimeInterval {
        guard !sortedValues.isEmpty else { return 0 }
        let midpoint = sortedValues.count / 2
        if sortedValues.count.isMultiple(of: 2) {
            return (sortedValues[midpoint - 1] + sortedValues[midpoint]) / 2
        }
        return sortedValues[midpoint]
    }

    private func percentile(
        _ percentile: Double,
        _ sortedValues: [TimeInterval]
    ) -> TimeInterval {
        guard !sortedValues.isEmpty else { return 0 }
        let rank = Int(ceil(percentile * Double(sortedValues.count))) - 1
        return sortedValues[min(max(rank, 0), sortedValues.count - 1)]
    }
}

@MainActor
final class DebugScrollProbeController {
    private var accumulator: DebugScrollProbeAccumulator
    private let resultStore: DebugScrollProbeResultStore
    private var isScrollPhaseNonIdle = false

    static func makeIfRequested(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        displayMaximumFramesPerSecond: Int
    ) -> DebugScrollProbeController? {
        guard DebugScrollProbePolicy(environment: environment).isRequested else {
            return nil
        }
        return DebugScrollProbeController(
            displayMaximumFramesPerSecond: displayMaximumFramesPerSecond
        )
    }

    private init(displayMaximumFramesPerSecond: Int) {
        resultStore = DebugScrollProbeResultStore()
        accumulator = DebugScrollProbeAccumulator(
            displayMaximumFramesPerSecond: displayMaximumFramesPerSecond,
            systemState: .current()
        )
        resultStore.reset()
    }

    func updateScrollPhase(isNonIdle: Bool) {
        guard isScrollPhaseNonIdle != isNonIdle else { return }
        isScrollPhaseNonIdle = isNonIdle

        if isNonIdle {
            accumulator.beginActiveSegment()
        } else {
            accumulator.updateSystemState(.current())
            if let result = accumulator.endActiveSegment() {
                resultStore.write(result)
            }
        }
    }

    func recordDisplayLinkCallback(
        at timestamp: TimeInterval,
        targetTimestampInterval: TimeInterval
    ) {
        accumulator.recordCallback(
            at: timestamp,
            targetTimestampInterval: targetTimestampInterval
        )
    }
}

private struct DebugScrollProbeResultStore {
    static let filename = "debug-scroll-probe-latest.json"

    private let fileManager: FileManager
    let fileURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        fileURL = AppStorageDirectory.applicationSupportSubdirectory(
            fileManager: fileManager
        ).appendingPathComponent(Self.filename, isDirectory: false)
    }

    func reset() {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        try? fileManager.removeItem(at: fileURL)
    }

    func write(_ result: DebugScrollProbeResult) {
        do {
            let fileEncoder = JSONEncoder()
            fileEncoder.dateEncodingStrategy = .iso8601
            fileEncoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            try fileEncoder.encode(result).write(to: fileURL, options: .atomic)

            let lineEncoder = JSONEncoder()
            lineEncoder.dateEncodingStrategy = .iso8601
            lineEncoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            let json = String(
                decoding: try lineEncoder.encode(result),
                as: UTF8.self
            )
            emit("MARGARITAVILLE_SCROLL_PROBE_RESULT path=\(fileURL.path) json=\(json)")
        } catch {
            emit(
                "MARGARITAVILLE_SCROLL_PROBE_ERROR path=\(fileURL.path) error=\(error.localizedDescription)"
            )
        }
    }

    private func emit(_ line: String) {
        guard let data = "\(line)\n".data(using: .utf8) else { return }
        try? FileHandle.standardOutput.write(contentsOf: data)
    }
}
#endif
