import Foundation
import LiveCellRendererKit
import SwiftUI

enum SummaryLiveCellBodyMode: Equatable {
    case swiftUIDecoration
    case metalBody
}

enum SummaryLiveCellOverlayContract {
    static let metalAllowsHitTesting = false
    static let metalIsAccessibilityHidden = true
    static let preservesSwiftUIOverlay = true

    static func bodyMode(
        isEnabled: Bool,
        rendererAvailable: Bool
    ) -> SummaryLiveCellBodyMode {
        isEnabled && rendererAvailable ? .metalBody : .swiftUIDecoration
    }
}

struct SummaryLiveCellDescriptor: Equatable {
    let stableID: UInt64
    let seed: UInt64
    let linearStatusRGB: LiveCellLinearRGB
    let profile: LiveCellProfile
    let geometry: LiveCellGeometry

    init(
        roomID: String,
        isVIP: Bool,
        status: RoomStatus,
        statusPaletteSaturation: Double,
        usesPurpleScheduled: Bool = false,
        cornerRadius: CGFloat,
        bottomCornerRadius: CGFloat? = nil,
        depth: CGFloat
    ) {
        stableID = LiveCellStableHash.fnv1a64("room:\(roomID)")
        seed = LiveCellStableHash.fnv1a64("motion:\(roomID)")
        linearStatusRGB = Self.linearStatusRGB(
            status: status,
            saturation: statusPaletteSaturation,
            usesPurpleScheduled: usesPurpleScheduled
        )
        profile = isVIP ? .vipBlob : .normal
        let lowerRadius = bottomCornerRadius ?? cornerRadius
        geometry = LiveCellGeometry(
            topLeftRadius: Float(cornerRadius),
            bottomLeftRadius: Float(lowerRadius),
            bottomRightRadius: Float(lowerRadius),
            topRightRadius: Float(cornerRadius),
            depth: Float(depth)
        )
    }

    func instance(visibleRect: CGRect) -> LiveCellInstance {
        LiveCellInstance(
            stableID: stableID,
            seed: seed,
            visibleRect: visibleRect,
            linearStatusRGB: linearStatusRGB,
            profile: profile,
            geometry: geometry
        )
    }

    private static func linearStatusRGB(
        status: RoomStatus,
        saturation: Double,
        usesPurpleScheduled: Bool
    ) -> LiveCellLinearRGB {
        let components = OceanKeyTheme.statusRGBComponents(
            for: status,
            saturation: saturation,
            usesPurpleScheduled: usesPurpleScheduled
        )
        return LiveCellLinearRGB(
            red: linearize(Float(components.red)),
            green: linearize(Float(components.green)),
            blue: linearize(Float(components.blue))
        )
    }

    private static func linearize(_ component: Float) -> Float {
        let clamped = min(max(component, 0), 1)
        if clamped <= 0.04045 {
            return clamped / 12.92
        }
        return pow((clamped + 0.055) / 1.055, 2.4)
    }
}

struct SummaryLiveCellCollection: Equatable {
    var instances: [LiveCellInstance] = []

    init() {}

    init(
        preferences: [UInt64: LiveCellInstance],
        viewportSize: CGSize
    ) {
        let viewport = CGRect(origin: .zero, size: viewportSize)
        let batches = LiveCellBatches(
            instances: Array(preferences.values),
            viewport: viewport
        )
        instances = batches.normal + batches.vip
    }
}

enum SummaryLiveCellCoordinateSpace {
    static let name = "summary-live-cell-viewport"
}

struct SummaryLiveCellPreferenceKey: PreferenceKey {
    static let defaultValue: [UInt64: LiveCellInstance] = [:]

    static func reduce(
        value: inout [UInt64: LiveCellInstance],
        nextValue: () -> [UInt64: LiveCellInstance]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct SummaryLiveCellSurfaceModifier: ViewModifier {
    let isEnabled: Bool
    let descriptor: SummaryLiveCellDescriptor

    func body(content: Content) -> some View {
        content.background {
            if isEnabled {
                GeometryReader { proxy in
                    let rect = proxy.frame(
                        in: .named(SummaryLiveCellCoordinateSpace.name)
                    )
                    Color.clear.preference(
                        key: SummaryLiveCellPreferenceKey.self,
                        value: [descriptor.stableID: descriptor.instance(visibleRect: rect)]
                    )
                }
            }
        }
    }
}

extension View {
    func summaryLiveCellSurface(
        isEnabled: Bool,
        descriptor: SummaryLiveCellDescriptor
    ) -> some View {
        modifier(
            SummaryLiveCellSurfaceModifier(
                isEnabled: isEnabled,
                descriptor: descriptor
            )
        )
    }
}

struct SummaryLiveCellViewport: View {
    let collection: SummaryLiveCellCollection
    let vipHDREnabled: Bool
    let onRendererAvailabilityChange: @MainActor (Bool) -> Void

    var body: some View {
        LiveCellMetalViewport(
            instances: collection.instances,
            policy: Self.renderPolicy(
                vipHDREnabled: vipHDREnabled,
                platformSupportsExtendedDynamicRange: Self.platformSupportsExtendedDynamicRange
            ),
            onRendererAvailabilityChange: onRendererAvailabilityChange
        )
        .allowsHitTesting(SummaryLiveCellOverlayContract.metalAllowsHitTesting)
        .accessibilityHidden(SummaryLiveCellOverlayContract.metalIsAccessibilityHidden)
    }

    static func renderPolicy(
        vipHDREnabled: Bool,
        platformSupportsExtendedDynamicRange: Bool
    ) -> LiveCellRenderPolicy {
        let allowsExtendedDynamicRange = vipHDREnabled
            && platformSupportsExtendedDynamicRange
        return LiveCellRenderPolicy(
            isEnabled: true,
            targetFramesPerSecond: 120,
            allowsExtendedDynamicRange: allowsExtendedDynamicRange,
            maximumCrestHeadroom: allowsExtendedDynamicRange ? 1.55 : 1
        )
    }

    private static var platformSupportsExtendedDynamicRange: Bool {
#if targetEnvironment(simulator)
        false
#else
        true
#endif
    }
}
