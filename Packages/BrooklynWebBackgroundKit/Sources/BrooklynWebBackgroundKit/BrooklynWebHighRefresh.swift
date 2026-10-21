import Foundation

public enum BrooklynWebHighRefreshRequest {
    public static func isEnabled(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Bool {
        #if DEBUG
        environment["BROOKLYN_WEB_PRIVATE_120HZ"] == "1"
        #else
        false
        #endif
    }
}

#if os(iOS) && DEBUG
import QuartzCore
import UIKit
import WebKit

@MainActor
final class BrooklynWebHighRefreshDriver: NSObject {
    private static let targetIntervalMS = 1_000.0 / 120.0
    private static let stallThresholdMS = 25.0
    private static let missedSlotThresholdMS = 12.5
    private static let burstThresholdMS = targetIntervalMS / 2

    private weak var webView: WKWebView?
    private var displayLink: CADisplayLink?
    private var isSampling = false
    private var previousTimestamp: CFTimeInterval?
    private var intervalsMS: [Double] = []
    private var samplingStartedAt: CFTimeInterval?
    private var activePeriodStartedAt: CFTimeInterval?
    private var accumulatedActiveDuration: CFTimeInterval = 0
    private var renderingEligible = false
    private var activityTransitions = 0
    private var suspensionGaps = 0
    private var hostActive: Bool

    init(webView: WKWebView, hostActive: Bool) {
        self.webView = webView
        self.hostActive = hostActive
    }

    func start() {
        guard displayLink == nil else { return }
        let displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink.preferredFrameRateRange = CAFrameRateRange(
            minimum: 120,
            maximum: 120,
            preferred: 120
        )
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        refreshPauseState(at: CACurrentMediaTime())
    }

    func setHostActive(_ active: Bool) {
        hostActive = active
        refreshPauseState(at: CACurrentMediaTime())
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        NotificationCenter.default.removeObserver(self)
        cancelTelemetry()
    }

    func beginTelemetry() {
        intervalsMS.removeAll(keepingCapacity: true)
        previousTimestamp = nil
        let now = CACurrentMediaTime()
        samplingStartedAt = now
        accumulatedActiveDuration = 0
        activityTransitions = 0
        suspensionGaps = 0
        renderingEligible = isRenderingEligible
        activePeriodStartedAt = renderingEligible ? now : nil
        isSampling = true
    }

    func finishTelemetry() -> [String: Any] {
        let finishedAt = CACurrentMediaTime()
        closeActivePeriod(at: finishedAt)
        let totalDurationMS = samplingStartedAt.map { (finishedAt - $0) * 1_000 } ?? 0
        let activeDurationMS = accumulatedActiveDuration * 1_000
        let suspensionDurationMS = max(0, totalDurationMS - activeDurationMS)
        let sorted = intervalsMS.sorted()
        let observedActiveMS = intervalsMS.reduce(0, +)
        let medianMS = Self.percentile(sorted, fraction: 0.5)
        let p99MS = Self.percentile(sorted, fraction: 0.99)
        let maximumMS = sorted.last
        let cadenceHz = medianMS.map { 1_000 / $0 }
        let effectiveCadenceHz = observedActiveMS > 0
            ? Double(intervalsMS.count) * 1_000 / observedActiveMS
            : nil
        let stallCount = intervalsMS.filter {
            $0 > Self.stallThresholdMS
        }.count
        let missedSlotCount = intervalsMS.filter {
            $0 > Self.missedSlotThresholdMS
        }.count
        let burstCount = intervalsMS.filter {
            $0 < Self.burstThresholdMS
        }.count
        isSampling = false
        previousTimestamp = nil
        return [
            "nativeDisplayLinkActiveDurationMS": Self.jsonNumber(activeDurationMS),
            "nativeDisplayLinkActiveIntervalCount": intervalsMS.count,
            "nativeDisplayLinkActivityTransitions": activityTransitions,
            "nativeDisplayLinkBurstCount": burstCount,
            "nativeDisplayLinkCadenceHz": Self.jsonNumber(cadenceHz),
            "nativeDisplayLinkEffectiveCadenceHz": Self.jsonNumber(effectiveCadenceHz),
            "nativeDisplayLinkMaximumMS": Self.jsonNumber(maximumMS),
            "nativeDisplayLinkMedianMS": Self.jsonNumber(medianMS),
            "nativeDisplayLinkMissedSlotCount": missedSlotCount,
            "nativeDisplayLinkMissedSlotThresholdMS": Self.rounded(Self.missedSlotThresholdMS),
            "nativeDisplayLinkObservedActiveMS": Self.rounded(observedActiveMS),
            "nativeDisplayLinkP99MS": Self.jsonNumber(p99MS),
            "nativeDisplayLinkRunLoopMode": "common",
            "nativeDisplayLinkSampleCount": intervalsMS.count,
            "nativeDisplayLinkStallCount": stallCount,
            "nativeDisplayLinkStallThresholdMS": Self.rounded(Self.stallThresholdMS),
            "nativeDisplayLinkSuspensionDurationMS": Self.jsonNumber(suspensionDurationMS),
            "nativeDisplayLinkSuspensionGaps": suspensionGaps
        ]
    }

    func cancelTelemetry() {
        isSampling = false
        previousTimestamp = nil
        intervalsMS.removeAll(keepingCapacity: true)
        samplingStartedAt = nil
        activePeriodStartedAt = nil
        accumulatedActiveDuration = 0
        renderingEligible = false
        activityTransitions = 0
        suspensionGaps = 0
    }

    @objc private func tick(_ displayLink: CADisplayLink) {
        if isSampling {
            updateEligibility(at: displayLink.timestamp)
            if renderingEligible, let previousTimestamp {
                intervalsMS.append((displayLink.timestamp - previousTimestamp) * 1_000)
            }
            previousTimestamp = renderingEligible ? displayLink.timestamp : nil
        }

        guard renderingEligible, let webView else { return }
        let updateSelector = NSSelectorFromString("_updateVisibleContentRects")
        guard webView.responds(to: updateSelector) else { return }
        _ = webView.perform(updateSelector)
    }

    @objc private func willResignActive(_ notification: Notification) {
        refreshPauseState(at: CACurrentMediaTime(), applicationActive: false)
    }

    @objc private func didBecomeActive(_ notification: Notification) {
        refreshPauseState(at: CACurrentMediaTime(), applicationActive: true)
    }

    private var isRenderingEligible: Bool {
        guard hostActive,
              UIApplication.shared.applicationState == .active,
              let webView,
              webView.window != nil,
              !webView.isHidden,
              webView.alpha > 0.001
        else { return false }
        return true
    }

    private func refreshPauseState(
        at timestamp: CFTimeInterval,
        applicationActive: Bool? = nil
    ) {
        let isApplicationActive = applicationActive
            ?? (UIApplication.shared.applicationState == .active)
        let shouldRun = hostActive && isApplicationActive
        if !shouldRun {
            setRenderingEligible(false, at: timestamp)
        }
        displayLink?.isPaused = !shouldRun
        if shouldRun {
            setRenderingEligible(isRenderingEligible, at: timestamp)
        }
    }

    private func updateEligibility(at timestamp: CFTimeInterval) {
        setRenderingEligible(isRenderingEligible, at: timestamp)
    }

    private func setRenderingEligible(
        _ eligible: Bool,
        at timestamp: CFTimeInterval
    ) {
        guard eligible != renderingEligible else { return }
        previousTimestamp = nil
        if isSampling {
            activityTransitions += 1
            if eligible {
                activePeriodStartedAt = timestamp
            } else {
                closeActivePeriod(at: timestamp)
                suspensionGaps += 1
            }
        }
        renderingEligible = eligible
    }

    private func closeActivePeriod(at timestamp: CFTimeInterval) {
        guard let activePeriodStartedAt else { return }
        accumulatedActiveDuration += max(0, timestamp - activePeriodStartedAt)
        self.activePeriodStartedAt = nil
    }

    private static func percentile(
        _ sorted: [Double],
        fraction: Double
    ) -> Double? {
        guard !sorted.isEmpty else { return nil }
        let index = min(
            sorted.count - 1,
            max(0, Int(ceil(Double(sorted.count) * fraction)) - 1)
        )
        return sorted[index]
    }

    private static func jsonNumber(_ value: Double?) -> Any {
        value.map { rounded($0) as Any } ?? NSNull()
    }

    private static func rounded(_ value: Double) -> Double {
        (value * 1_000).rounded() / 1_000
    }
}
#endif
