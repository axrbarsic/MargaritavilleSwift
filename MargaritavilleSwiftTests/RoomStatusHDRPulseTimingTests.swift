import Foundation
import Testing
@testable import MargaritavilleSwift

@Test
func statusHDRPulseHeatsSmoothlyAndKeepsALongCoolingTail() {
    #expect(RoomStatusHDRPulseTiming.heat(elapsed: 0) == 0)

    let earlyRise = RoomStatusHDRPulseTiming.heat(elapsed: 0.14)
    let lateRise = RoomStatusHDRPulseTiming.heat(elapsed: 0.32)
    #expect(earlyRise > 0)
    #expect(lateRise > earlyRise)
    #expect(lateRise < 1)

    #expect(RoomStatusHDRPulseTiming.heat(elapsed: 0.42) == 1)
    #expect(RoomStatusHDRPulseTiming.heat(elapsed: 0.58) == 1)
    #expect(RoomStatusHDRPulseTiming.heat(elapsed: 1.58) > 0.5)
    #expect(RoomStatusHDRPulseTiming.heat(elapsed: 2.48) > 0)
    #expect(RoomStatusHDRPulseTiming.heat(elapsed: 2.58) == 0)
}

@Test
func statusHDRPulseCoolingNeverRebounds() {
    let samples = stride(from: 0.58, through: 2.58, by: 0.05)
        .map(RoomStatusHDRPulseTiming.heat(elapsed:))

    for pair in zip(samples, samples.dropFirst()) {
        #expect(pair.1 <= pair.0)
    }
}

@Test
func statusHDRPulseEventCannotReplayAfterItsOriginalTimelineExpires() {
    let startedAt = Date(timeIntervalSinceReferenceDate: 1_000)
    let event = RoomStatusHDRPulseEvent(
        generation: 7,
        status: .ready,
        startedAt: startedAt
    )

    #expect(event.isActive(at: startedAt))
    #expect(event.isActive(at: startedAt.addingTimeInterval(2.57)))
    #expect(!event.isActive(at: startedAt.addingTimeInterval(2.58)))
    #expect(!event.isActive(at: startedAt.addingTimeInterval(30)))
}

@Test
func statusHDRPulseReappearanceKeepsOnlyTheOriginalCleanupRemainder() {
    let startedAt = Date(timeIntervalSinceReferenceDate: 2_000)
    let reappearedAt = startedAt.addingTimeInterval(2.5)

    #expect(abs(RoomStatusHDRPulseTiming.remainingCleanupTime(
        startedAt: startedAt,
        now: reappearedAt
    ) - 0.23) < 0.001)
}
