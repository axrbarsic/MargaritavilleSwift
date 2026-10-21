#if os(iOS)
import Foundation
import Metal

struct BrooklynPerformanceFrameToken: Sendable {
    let mode: BrooklynPerformanceTelemetry.Mode
    let isMeasured: Bool
    let measurementSecond: Double
    let startedAt: CFTimeInterval
}

final class BrooklynPerformanceTelemetry: @unchecked Sendable {
    enum Mode: Int, CaseIterable, Sendable {
        case donorExact
        case enhanced

        var style: BrooklynSurfaceStyle {
            switch self {
            case .donorExact: .donorExact
            case .enhanced: .enhanced
            }
        }

        var reportName: String {
            switch self {
            case .donorExact: "donor"
            case .enhanced: "enhanced"
            }
        }
    }

    private struct ModeSamples {
        var drawIntervalsMS: [Double] = []
        var cpuEncodeMS: [Double] = []
        var gpuMS: [Double] = []
        var presentIntervalsMS: [Double] = []
        var presentDelayMS: [Double] = []
        var slowDrawSeconds: [Double] = []
        var slowPresentSeconds: [Double] = []
        var lastDrawTime: CFTimeInterval?
        var lastPresentedTime: CFTimeInterval?
        var submittedFrames = 0
        var skippedFrames = 0
        var commandErrors = 0

        mutating func reserveCapacity(_ capacity: Int) {
            drawIntervalsMS.reserveCapacity(capacity)
            cpuEncodeMS.reserveCapacity(capacity)
            gpuMS.reserveCapacity(capacity)
            presentIntervalsMS.reserveCapacity(capacity)
            presentDelayMS.reserveCapacity(capacity)
            slowDrawSeconds.reserveCapacity(64)
            slowPresentSeconds.reserveCapacity(64)
        }
    }

    private static let sampleCapacity = 5_000
    private static let donorWarmupEnd: Double = 2
    private static let donorMeasurementEnd: Double = 32
    private static let enhancedWarmupEnd: Double = 34
    private static let enhancedMeasurementEnd: Double = 64
    private static let reportTime: Double = 65

    private let lock = NSLock()
    private var samples = Mode.allCases.map { _ in ModeSamples() }
    private var startedAt: CFTimeInterval?
    private var didReport = false
    private let maximumFPS: Int

    private init(maximumFPS: Int) {
        self.maximumFPS = maximumFPS
        for index in samples.indices {
            samples[index].reserveCapacity(Self.sampleCapacity)
        }
    }

    static func makeIfRequested(maximumFPS: Int) -> BrooklynPerformanceTelemetry? {
        #if DEBUG
        guard ProcessInfo.processInfo.environment["BROOKLYN_PERFORMANCE_SWEEP"] == "1" else {
            return nil
        }
        return BrooklynPerformanceTelemetry(maximumFPS: maximumFPS)
        #else
        return nil
        #endif
    }

    func beginFrame(at now: CFTimeInterval) -> BrooklynPerformanceFrameToken {
        var reportLines: [String] = []
        let token: BrooklynPerformanceFrameToken = locked {
            if startedAt == nil {
                startedAt = now
            }
            let elapsed = now - (startedAt ?? now)
            let phase = Self.phase(at: elapsed)
            let index = phase.mode.rawValue
            if phase.isMeasured {
                if let previous = samples[index].lastDrawTime {
                    let intervalMS = (now - previous) * 1_000
                    Self.append(intervalMS, to: &samples[index].drawIntervalsMS)
                    if intervalMS > 12.5 {
                        samples[index].slowDrawSeconds.append(phase.measurementSecond)
                    }
                }
                samples[index].lastDrawTime = now
            } else {
                samples[index].lastDrawTime = nil
            }
            if elapsed >= Self.reportTime, !didReport {
                didReport = true
                reportLines = makeReportLines()
            }
            return BrooklynPerformanceFrameToken(
                mode: phase.mode,
                isMeasured: phase.isMeasured,
                measurementSecond: phase.measurementSecond,
                startedAt: now
            )
        }
        for line in reportLines {
            print(line)
        }
        return token
    }

    func recordSkipped(_ token: BrooklynPerformanceFrameToken) {
        guard token.isMeasured else { return }
        locked {
            samples[token.mode.rawValue].skippedFrames += 1
        }
    }

    func recordCPU(_ token: BrooklynPerformanceFrameToken, endedAt: CFTimeInterval) {
        guard token.isMeasured else { return }
        locked {
            let index = token.mode.rawValue
            samples[index].submittedFrames += 1
            Self.append((endedAt - token.startedAt) * 1_000, to: &samples[index].cpuEncodeMS)
        }
    }

    func recordGPU(_ token: BrooklynPerformanceFrameToken, commandBuffer: MTLCommandBuffer) {
        guard token.isMeasured else { return }
        locked {
            let index = token.mode.rawValue
            if commandBuffer.status == .completed,
               commandBuffer.gpuStartTime > 0,
               commandBuffer.gpuEndTime >= commandBuffer.gpuStartTime {
                Self.append(
                    (commandBuffer.gpuEndTime - commandBuffer.gpuStartTime) * 1_000,
                    to: &samples[index].gpuMS
                )
            } else {
                samples[index].commandErrors += 1
            }
        }
    }

    /// The iOS 26.5 SDK no longer exposes drawable presentation callbacks.
    /// This fallback keeps the opt-in debug sweep useful without claiming
    /// that command completion is the exact display presentation time.
    func recordCommandCompletionFallback(
        _ token: BrooklynPerformanceFrameToken,
        completedAt: CFTimeInterval,
        committedAt: CFTimeInterval
    ) {
        guard token.isMeasured, completedAt > 0 else { return }
        locked {
            let index = token.mode.rawValue
            if let previous = samples[index].lastPresentedTime, completedAt >= previous {
                let intervalMS = (completedAt - previous) * 1_000
                Self.append(intervalMS, to: &samples[index].presentIntervalsMS)
                if intervalMS > 12.5 {
                    samples[index].slowPresentSeconds.append(token.measurementSecond)
                }
            }
            samples[index].lastPresentedTime = completedAt
            if completedAt >= committedAt {
                Self.append(
                    (completedAt - committedAt) * 1_000,
                    to: &samples[index].presentDelayMS
                )
            }
        }
    }

    private static func phase(
        at elapsed: Double
    ) -> (mode: Mode, isMeasured: Bool, measurementSecond: Double) {
        if elapsed < donorWarmupEnd {
            return (.donorExact, false, 0)
        }
        if elapsed < donorMeasurementEnd {
            return (.donorExact, true, elapsed - donorWarmupEnd)
        }
        if elapsed < enhancedWarmupEnd {
            return (.enhanced, false, 0)
        }
        if elapsed < enhancedMeasurementEnd {
            return (.enhanced, true, elapsed - enhancedWarmupEnd)
        }
        return (.enhanced, false, 30)
    }

    private func makeReportLines() -> [String] {
        let thermal = Self.thermalName(ProcessInfo.processInfo.thermalState)
        let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        return Mode.allCases.map { mode in
            let sample = samples[mode.rawValue]
            let gpuOverBudget = sample.gpuMS.filter { $0 > 8.33 }.count
            return String(
                format: "BROOKLYN_PERF mode=%@ seconds=30 maxFPS=%d thermal=%@ lowPower=%@ timingSource=commandCompletionFallback frames=%d skipped=%d errors=%d drawMedianMS=%.3f drawP99MS=%.3f slowDraw=%d slowDrawMax10s=%d presentP99MS=%.3f slowPresent=%d slowPresentMax10s=%d gpuP99MS=%.3f gpuOver8_33=%d cpuP99MS=%.3f presentDelayP99MS=%.3f",
                mode.reportName,
                maximumFPS,
                thermal,
                lowPower ? "true" : "false",
                sample.submittedFrames,
                sample.skippedFrames,
                sample.commandErrors,
                Self.percentile(sample.drawIntervalsMS, fraction: 0.50),
                Self.percentile(sample.drawIntervalsMS, fraction: 0.99),
                sample.slowDrawSeconds.count,
                Self.maximumEvents(inAnyWindow: 10, eventSeconds: sample.slowDrawSeconds),
                Self.percentile(sample.presentIntervalsMS, fraction: 0.99),
                sample.slowPresentSeconds.count,
                Self.maximumEvents(inAnyWindow: 10, eventSeconds: sample.slowPresentSeconds),
                Self.percentile(sample.gpuMS, fraction: 0.99),
                gpuOverBudget,
                Self.percentile(sample.cpuEncodeMS, fraction: 0.99),
                Self.percentile(sample.presentDelayMS, fraction: 0.99)
            )
        }
    }

    private static func percentile(_ values: [Double], fraction: Double) -> Double {
        guard !values.isEmpty else { return .nan }
        let sorted = values.sorted()
        let index = min(sorted.count - 1, max(0, Int(ceil(Double(sorted.count) * fraction)) - 1))
        return sorted[index]
    }

    private static func maximumEvents(inAnyWindow window: Double, eventSeconds: [Double]) -> Int {
        guard !eventSeconds.isEmpty else { return 0 }
        let sorted = eventSeconds.sorted()
        var left = 0
        var maximum = 0
        for right in sorted.indices {
            while sorted[right] - sorted[left] > window {
                left += 1
            }
            maximum = max(maximum, right - left + 1)
        }
        return maximum
    }

    private static func append(_ value: Double, to values: inout [Double]) {
        guard value.isFinite, values.count < sampleCapacity else { return }
        values.append(value)
    }

    private static func thermalName(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: "nominal"
        case .fair: "fair"
        case .serious: "serious"
        case .critical: "critical"
        @unknown default: "unknown"
        }
    }

    @discardableResult
    private func locked<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
#endif
