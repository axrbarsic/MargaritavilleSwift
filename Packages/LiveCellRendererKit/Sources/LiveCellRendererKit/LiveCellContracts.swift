import CoreGraphics
import Foundation

public struct LiveCellLinearRGB: Equatable, Sendable {
    public var red: Float
    public var green: Float
    public var blue: Float

    public init(red: Float, green: Float, blue: Float) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public var clampedToNonnegative: Self {
        Self(
            red: max(red, 0),
            green: max(green, 0),
            blue: max(blue, 0)
        )
    }
}

public enum LiveCellProfile: UInt32, Equatable, Sendable {
    case normal = 0
    case vipBlob = 1
}

public struct LiveCellGeometry: Equatable, Sendable {
    public var topLeftRadius: Float
    public var bottomLeftRadius: Float
    public var bottomRightRadius: Float
    public var topRightRadius: Float
    public var depth: Float

    public init(
        topLeftRadius: Float,
        bottomLeftRadius: Float,
        bottomRightRadius: Float,
        topRightRadius: Float,
        depth: Float
    ) {
        self.topLeftRadius = max(topLeftRadius, 0)
        self.bottomLeftRadius = max(bottomLeftRadius, 0)
        self.bottomRightRadius = max(bottomRightRadius, 0)
        self.topRightRadius = max(topRightRadius, 0)
        self.depth = max(depth, 0)
    }

    public init(cornerRadius: Float, depth: Float) {
        self.init(
            topLeftRadius: cornerRadius,
            bottomLeftRadius: cornerRadius,
            bottomRightRadius: cornerRadius,
            topRightRadius: cornerRadius,
            depth: depth
        )
    }
}

public struct LiveCellInstance: Identifiable, Equatable, Sendable {
    public let stableID: UInt64
    public let seed: UInt64
    public var visibleRect: CGRect
    public var linearStatusRGB: LiveCellLinearRGB
    public var profile: LiveCellProfile
    public var geometry: LiveCellGeometry

    public var id: UInt64 { stableID }

    public init(
        stableID: UInt64,
        seed: UInt64,
        visibleRect: CGRect,
        linearStatusRGB: LiveCellLinearRGB,
        profile: LiveCellProfile,
        geometry: LiveCellGeometry
    ) {
        self.stableID = stableID
        self.seed = seed
        self.visibleRect = visibleRect
        self.linearStatusRGB = linearStatusRGB.clampedToNonnegative
        self.profile = profile
        self.geometry = geometry
    }
}

public struct LiveCellRenderPolicy: Equatable, Sendable {
    public var isEnabled: Bool
    public var targetFramesPerSecond: Int
    public var allowsExtendedDynamicRange: Bool
    public var maximumCrestHeadroom: Float

    public init(
        isEnabled: Bool,
        targetFramesPerSecond: Int = 120,
        allowsExtendedDynamicRange: Bool,
        maximumCrestHeadroom: Float = 1.55
    ) {
        self.isEnabled = isEnabled
        self.targetFramesPerSecond = min(max(targetFramesPerSecond, 30), 120)
        self.allowsExtendedDynamicRange = allowsExtendedDynamicRange
        self.maximumCrestHeadroom = allowsExtendedDynamicRange
            ? min(max(maximumCrestHeadroom, 1), 2)
            : 1
    }

    public static let disabled = LiveCellRenderPolicy(
        isEnabled: false,
        allowsExtendedDynamicRange: false,
        maximumCrestHeadroom: 1
    )

    public var normalCrestHeadroom: Float { 1 }

    public var vipCrestHeadroom: Float {
        allowsExtendedDynamicRange ? maximumCrestHeadroom : 1
    }
}

public enum LiveCellStableHash {
    public static func fnv1a64(_ value: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x0000_0100_0000_01b3
        }
        return hash
    }
}

public struct LiveCellBatches: Equatable, Sendable {
    public var normal: [LiveCellInstance]
    public var vip: [LiveCellInstance]

    public init(instances: [LiveCellInstance], viewport: CGRect) {
        let visible = instances
            .filter { instance in
                instance.visibleRect.width > 0
                    && instance.visibleRect.height > 0
                    && instance.visibleRect.intersects(viewport)
            }
            .sorted { lhs, rhs in lhs.stableID < rhs.stableID }
        normal = visible.filter { $0.profile == .normal }
        vip = visible.filter { $0.profile == .vipBlob }
    }
}
