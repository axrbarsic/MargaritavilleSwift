import SwiftUI

struct RoomStatusHDRPulseEvent: Equatable, Sendable {
    let generation: Int
    let status: RoomStatus
    let startedAt: Date

    func isActive(at date: Date) -> Bool {
        RoomStatusHDRPulseTiming.isActive(startedAt: startedAt, now: date)
    }
}

struct RoomHDRPulseEnvelope: Equatable, Sendable {
    let riseDuration: TimeInterval
    let peakTime: TimeInterval
    let fadeDuration: TimeInterval
    let cleanupTime: TimeInterval
    let brightnessMultiplier: CGFloat

    var totalDuration: TimeInterval { peakTime + fadeDuration }
    var cleanupDelay: Duration { .milliseconds(Int(cleanupTime * 1_000)) }

    func heat(startedAt: Date, now: Date) -> CGFloat {
        heat(elapsed: now.timeIntervalSince(startedAt))
    }

    func isActive(startedAt: Date, now: Date) -> Bool {
        let elapsed = now.timeIntervalSince(startedAt)
        return elapsed >= 0 && elapsed < totalDuration
    }

    func remainingCleanupTime(startedAt: Date, now: Date) -> TimeInterval {
        max(0, cleanupTime - max(0, now.timeIntervalSince(startedAt)))
    }

    func heat(elapsed: TimeInterval) -> CGFloat {
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

    private func smootherStep(_ rawValue: Double) -> CGFloat {
        let value = min(max(rawValue, 0), 1)
        return CGFloat(value * value * value * (value * (value * 6 - 15) + 10))
    }
}

enum RoomStatusHDRPulseTiming {
    static let envelope = RoomHDRPulseEnvelope(
        riseDuration: 0.42,
        peakTime: 0.58,
        fadeDuration: 2.0,
        cleanupTime: 2.73,
        brightnessMultiplier: 2
    )
    static let totalDuration = envelope.totalDuration
    static let cleanupDelay = envelope.cleanupDelay
    static let brightnessMultiplier = envelope.brightnessMultiplier
    static let rubberAmplitudeMultiplier: CGFloat = 1.7

    static func heat(startedAt: Date?, now: Date) -> CGFloat {
        guard let startedAt else { return 0 }
        return heat(elapsed: now.timeIntervalSince(startedAt))
    }

    static func isActive(startedAt: Date, now: Date) -> Bool {
        envelope.isActive(startedAt: startedAt, now: now)
    }

    static func remainingCleanupTime(startedAt: Date, now: Date) -> TimeInterval {
        envelope.remainingCleanupTime(startedAt: startedAt, now: now)
    }

    static func heat(elapsed: TimeInterval) -> CGFloat {
        envelope.heat(elapsed: elapsed)
    }
}
