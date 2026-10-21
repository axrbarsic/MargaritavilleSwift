import CoreGraphics
import Testing
@testable import LiveCellRendererKit

@Test
func stableHashIsDeterministicAndSensitiveToIdentity() {
    #expect(LiveCellStableHash.fnv1a64("room-1201") == 0xcfe3_4b70_ada3_849d)
    #expect(LiveCellStableHash.fnv1a64("room-1201") == LiveCellStableHash.fnv1a64("room-1201"))
    #expect(LiveCellStableHash.fnv1a64("room-1201") != LiveCellStableHash.fnv1a64("room-1202"))
}

@Test
func disabledPolicyIsAnHonestSDRFallback() {
    #expect(!LiveCellRenderPolicy.disabled.isEnabled)
    #expect(!LiveCellRenderPolicy.disabled.allowsExtendedDynamicRange)
    #expect(LiveCellRenderPolicy.disabled.maximumCrestHeadroom == 1)

    let simulatorPolicy = LiveCellRenderPolicy(
        isEnabled: true,
        targetFramesPerSecond: 240,
        allowsExtendedDynamicRange: false,
        maximumCrestHeadroom: 1.8
    )
    #expect(simulatorPolicy.targetFramesPerSecond == 120)
    #expect(simulatorPolicy.maximumCrestHeadroom == 1)
    #expect(simulatorPolicy.normalCrestHeadroom == 1)
    #expect(simulatorPolicy.vipCrestHeadroom == 1)

    let vipEDRPolicy = LiveCellRenderPolicy(
        isEnabled: true,
        allowsExtendedDynamicRange: true,
        maximumCrestHeadroom: 1.55
    )
    #expect(vipEDRPolicy.normalCrestHeadroom == 1)
    #expect(vipEDRPolicy.vipCrestHeadroom == 1.55)
}

@Test
func batchesFilterVisibilityAndGroupProfilesWithoutIdentityChurn() {
    let viewport = CGRect(x: 0, y: 0, width: 300, height: 500)
    let geometry = LiveCellGeometry(cornerRadius: 16, depth: 14)
    let color = LiveCellLinearRGB(red: 1, green: 0.2, blue: 0.1)
    let instances = [
        LiveCellInstance(
            stableID: 22,
            seed: 2,
            visibleRect: CGRect(x: 10, y: 10, width: 80, height: 80),
            linearStatusRGB: color,
            profile: .vipBlob,
            geometry: geometry
        ),
        LiveCellInstance(
            stableID: 11,
            seed: 1,
            visibleRect: CGRect(x: 100, y: 20, width: 80, height: 80),
            linearStatusRGB: color,
            profile: .normal,
            geometry: geometry
        ),
        LiveCellInstance(
            stableID: 33,
            seed: 3,
            visibleRect: CGRect(x: 10, y: 800, width: 80, height: 80),
            linearStatusRGB: color,
            profile: .normal,
            geometry: geometry
        )
    ]

    let batches = LiveCellBatches(instances: instances, viewport: viewport)
    #expect(batches.normal.map(\.stableID) == [11])
    #expect(batches.vip.map(\.stableID) == [22])
}
