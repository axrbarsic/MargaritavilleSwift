import SwiftUI

struct RoomStatusHDRPulseEvent: Equatable, Sendable {
    let generation: Int
    let status: RoomStatus
    let startedAt: Date

    func isActive(at date: Date) -> Bool {
        RoomStatusHDRPulseTiming.isActive(startedAt: startedAt, now: date)
    }
}

enum RoomStatusHDRPulseTiming {
    static let riseDuration: TimeInterval = 0.42
    static let peakTime: TimeInterval = 0.58
    static let fadeDuration: TimeInterval = 2.0
    static let totalDuration = peakTime + fadeDuration
    static let cleanupTime: TimeInterval = 2.73
    static let cleanupDelay: Duration = .milliseconds(Int(cleanupTime * 1_000))
    static let brightnessMultiplier: CGFloat = 2
    static let rubberAmplitudeMultiplier: CGFloat = 1.7

    static func heat(startedAt: Date?, now: Date) -> CGFloat {
        guard let startedAt else { return 0 }
        return heat(elapsed: now.timeIntervalSince(startedAt))
    }

    static func isActive(startedAt: Date, now: Date) -> Bool {
        let elapsed = now.timeIntervalSince(startedAt)
        return elapsed >= 0 && elapsed < totalDuration
    }

    static func remainingCleanupTime(startedAt: Date, now: Date) -> TimeInterval {
        max(0, cleanupTime - max(0, now.timeIntervalSince(startedAt)))
    }

    static func heat(elapsed: TimeInterval) -> CGFloat {
        guard elapsed > 0 else { return 0 }
        if elapsed < riseDuration {
            return smootherStep(elapsed / riseDuration)
        }
        if elapsed <= peakTime {
            return 1
        }
        guard elapsed < totalDuration else { return 0 }

        let coolingProgress = (elapsed - peakTime) / fadeDuration
        let smoothRemainingHeat = 1 - smootherStep(coolingProgress)
        return CGFloat(pow(max(smoothRemainingHeat, 0), 0.7))
    }

    private static func smootherStep(_ rawValue: Double) -> CGFloat {
        let value = min(max(rawValue, 0), 1)
        return CGFloat(value * value * value * (value * (value * 6 - 15) + 10))
    }
}
