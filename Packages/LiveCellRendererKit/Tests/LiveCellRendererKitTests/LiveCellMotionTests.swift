import Foundation
import Testing
@testable import LiveCellRendererKit

@Test
func normalMotionIsDeterministicStaggeredAndReturnsFrontFacing() {
    let seed: UInt64 = 0x1020_3040_5060_7080
    let phase = LiveCellMotion.normalizedSeed(seed)
    let cycleStart = -phase * LiveCellMotion.normalCycleDuration

    let rest = LiveCellMotion.normalPose(
        at: cycleStart + LiveCellMotion.normalTurnDuration + 0.25,
        seed: seed
    )
    let middle = LiveCellMotion.normalPose(
        at: cycleStart + LiveCellMotion.normalTurnDuration / 2,
        seed: seed
    )
    let returned = LiveCellMotion.normalPose(
        at: cycleStart + LiveCellMotion.normalTurnDuration,
        seed: seed
    )

    #expect(rest.isFrontFacing)
    #expect(abs(middle.turnAngleRadians - .pi / 2) < 0.000_001)
    #expect(returned.isFrontFacing)
    #expect(middle == LiveCellMotion.normalPose(
        at: cycleStart + LiveCellMotion.normalTurnDuration / 2,
        seed: seed
    ))
}

@Test
func normalRestNeverIntroducesContinuousXYTilt() {
    let pose = LiveCellMotion.normalPose(at: 7.25, seed: 42)
    #expect(abs(pose.zHover) <= 0.018)
    #expect(abs(pose.scale - 1) <= 0.007)
    #expect(abs(pose.zRollRadians) <= 0.007)
}
