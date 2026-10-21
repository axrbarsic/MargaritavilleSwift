import Foundation

public enum LiveCellTurnAxis: UInt32, Equatable, Sendable {
    case screenX = 0
    case screenY = 1
}

public struct LiveCellNormalPose: Equatable, Sendable {
    public var turnAxis: LiveCellTurnAxis
    public var turnAngleRadians: Double
    public var zHover: Double
    public var scale: Double
    public var zRollRadians: Double

    public var isFrontFacing: Bool {
        abs(turnAngleRadians) < 0.000_001
    }
}

public enum LiveCellMotion {
    public static let normalCycleDuration = 13.75
    public static let normalTurnDuration = 1.5

    public static func normalPose(
        at time: TimeInterval,
        seed: UInt64
    ) -> LiveCellNormalPose {
        let phase = normalizedSeed(seed)
        let localTime = positiveRemainder(
            time + phase * normalCycleDuration,
            modulus: normalCycleDuration
        )
        let turnProgress = min(max(localTime / normalTurnDuration, 0), 1)
        let turnEnvelope = localTime < normalTurnDuration
            ? sin(.pi * turnProgress)
            : 0
        let slowPhase = time * 0.19 + phase * .pi * 2
        return LiveCellNormalPose(
            turnAxis: (seed & 1) == 0 ? .screenX : .screenY,
            turnAngleRadians: (.pi / 2) * turnEnvelope,
            zHover: sin(slowPhase) * 0.018,
            scale: 1 + sin(slowPhase * 0.73 + 0.7) * 0.007,
            zRollRadians: sin(slowPhase * 0.41 + 1.3) * 0.007
        )
    }

    public static func normalizedSeed(_ seed: UInt64) -> Double {
        let mantissa = seed & ((1 << 53) - 1)
        return Double(mantissa) / Double((1 << 53) - 1)
    }

    private static func positiveRemainder(
        _ value: Double,
        modulus: Double
    ) -> Double {
        let remainder = value.truncatingRemainder(dividingBy: modulus)
        return remainder >= 0 ? remainder : remainder + modulus
    }
}
