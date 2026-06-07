import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class PerformanceTelemetryStore {
    @ObservationIgnored private var displayLinkDriver: DisplayLinkDriver?
    @ObservationIgnored private var windowStartedAt: TimeInterval?
    @ObservationIgnored private var windowFrameCount = 0
    @ObservationIgnored private var windowSlowFrameCount = 0
    @ObservationIgnored private var windowWorstFrameDuration: TimeInterval = 0

    let targetFPS: Int
    private(set) var currentFPS: Int = 0
    private(set) var recentSlowFrames: Int = 0
    private(set) var recentWorstFrameMS: Double = 0
    private(set) var totalSlowFrames: Int = 0
    private(set) var isRunning = false

    init(targetFPS: Int = UIScreen.main.maximumFramesPerSecond) {
        self.targetFPS = max(targetFPS, 60)
    }

    func start() {
        guard displayLinkDriver == nil else { return }
        resetWindow()
        isRunning = true
        let driver = DisplayLinkDriver(targetFPS: targetFPS) { [weak self] displayLink in
            self?.recordFrame(
                duration: displayLink.targetTimestamp - displayLink.timestamp,
                timestamp: displayLink.timestamp
            )
        }
        displayLinkDriver = driver
        driver.start()
    }

    func stop() {
        displayLinkDriver?.stop()
        displayLinkDriver = nil
        isRunning = false
        resetWindow()
    }

    func resetCounters() {
        currentFPS = 0
        recentSlowFrames = 0
        recentWorstFrameMS = 0
        totalSlowFrames = 0
        resetWindow()
    }

    func recordFrameForTesting(duration: TimeInterval, timestamp: TimeInterval) {
        recordFrame(duration: duration, timestamp: timestamp)
    }

    private func recordFrame(duration: TimeInterval, timestamp: TimeInterval) {
        if windowStartedAt == nil {
            windowStartedAt = timestamp
        }

        windowFrameCount += 1
        windowWorstFrameDuration = max(windowWorstFrameDuration, duration)

        if duration > slowFrameThreshold {
            windowSlowFrameCount += 1
            totalSlowFrames += 1
        }

        guard let windowStartedAt else { return }
        let elapsed = timestamp - windowStartedAt
        guard elapsed >= 1 else { return }

        currentFPS = Int((Double(windowFrameCount) / elapsed).rounded())
        recentSlowFrames = windowSlowFrameCount
        recentWorstFrameMS = windowWorstFrameDuration * 1_000
        resetWindow(startingAt: timestamp)
    }

    private var slowFrameThreshold: TimeInterval {
        (1 / Double(targetFPS)) * 1.35
    }

    private func resetWindow(startingAt timestamp: TimeInterval? = nil) {
        windowStartedAt = timestamp
        windowFrameCount = 0
        windowSlowFrameCount = 0
        windowWorstFrameDuration = 0
    }
}

@MainActor
private final class DisplayLinkDriver: NSObject {
    private let targetFPS: Int
    private let onFrame: (CADisplayLink) -> Void
    private var displayLink: CADisplayLink?

    init(targetFPS: Int, onFrame: @escaping (CADisplayLink) -> Void) {
        self.targetFPS = targetFPS
        self.onFrame = onFrame
    }

    func start() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(frameDidTick(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(
            minimum: 30,
            maximum: Float(targetFPS),
            preferred: Float(targetFPS)
        )
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func frameDidTick(_ displayLink: CADisplayLink) {
        onFrame(displayLink)
    }
}
