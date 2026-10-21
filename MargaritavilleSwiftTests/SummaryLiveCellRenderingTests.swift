import CoreGraphics
import Foundation
import Testing
@testable import MargaritavilleSwift

@Suite
struct SummaryLiveCellRenderingTests {
    @Test
    func live3DSettingDefaultsOffPersistsAndResets() {
        let suiteName = "SummaryLiveCellRenderingTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettingsStore.load(userDefaults: defaults)
        #expect(!settings.developerLive3DCellsEnabled)
        settings.developerLive3DCellsEnabled = true
        #expect(AppSettingsStore.load(userDefaults: defaults).developerLive3DCellsEnabled)

        settings.resetToDefaults()
        #expect(!AppSettingsStore.load(userDefaults: defaults).developerLive3DCellsEnabled)
    }

    @Test
    func live3DCellsDefaultOffKeepsTheExistingSwiftUIDecorationPath() {
        #expect(SummaryLiveCellOverlayContract.bodyMode(
            isEnabled: false,
            rendererAvailable: true
        ) == .swiftUIDecoration)
        #expect(SummaryLiveCellOverlayContract.bodyMode(
            isEnabled: true,
            rendererAvailable: false
        ) == .swiftUIDecoration)
        #expect(SummaryLiveCellOverlayContract.bodyMode(
            isEnabled: true,
            rendererAvailable: true
        ) == .metalBody)
        #expect(!SummaryLiveCellOverlayContract.metalAllowsHitTesting)
        #expect(SummaryLiveCellOverlayContract.metalIsAccessibilityHidden)
        #expect(SummaryLiveCellOverlayContract.preservesSwiftUIOverlay)
    }

    @Test
    func liveCellEDRPolicyIsVIPOnlyAndRespectsTheExistingHDRToggle() {
        let ordinaryOnly = SummaryLiveCellViewport.renderPolicy(
            vipHDREnabled: false,
            platformSupportsExtendedDynamicRange: true
        )
        let vipHDR = SummaryLiveCellViewport.renderPolicy(
            vipHDREnabled: true,
            platformSupportsExtendedDynamicRange: true
        )
        let simulator = SummaryLiveCellViewport.renderPolicy(
            vipHDREnabled: true,
            platformSupportsExtendedDynamicRange: false
        )

        #expect(!ordinaryOnly.allowsExtendedDynamicRange)
        #expect(ordinaryOnly.normalCrestHeadroom == 1)
        #expect(ordinaryOnly.vipCrestHeadroom == 1)
        #expect(vipHDR.allowsExtendedDynamicRange)
        #expect(vipHDR.normalCrestHeadroom == 1)
        #expect(vipHDR.vipCrestHeadroom == 1.55)
        #expect(!simulator.allowsExtendedDynamicRange)
        #expect(simulator.vipCrestHeadroom == 1)
    }

    @Test
    func liveCellStatusColorComesOnlyFromTheCanonicalPaletteAndKeepsIdentity() {
        let normal = SummaryLiveCellDescriptor(
            roomID: "1201",
            isVIP: false,
            status: .open,
            statusPaletteSaturation: 1,
            cornerRadius: 16,
            depth: 15
        )
        let changedStatus = SummaryLiveCellDescriptor(
            roomID: "1201",
            isVIP: false,
            status: .ready,
            statusPaletteSaturation: 1,
            cornerRadius: 16,
            depth: 15
        )
        let source = OceanKeyTheme.statusRGBComponents(for: .open)

        #expect(abs(normal.linearStatusRGB.red - linearized(Float(source.red))) < 0.000_001)
        #expect(abs(normal.linearStatusRGB.green - linearized(Float(source.green))) < 0.000_001)
        #expect(abs(normal.linearStatusRGB.blue - linearized(Float(source.blue))) < 0.000_001)
        #expect(normal.stableID == changedStatus.stableID)
        #expect(normal.seed == changedStatus.seed)
        #expect(normal.linearStatusRGB != changedStatus.linearStatusRGB)
    }

    @Test
    func liveCellProfileSelectionAndViewportFilteringAreDeterministic() {
        let ordinary = SummaryLiveCellDescriptor(
            roomID: "1201",
            isVIP: false,
            status: .pending,
            statusPaletteSaturation: 1,
            cornerRadius: 16,
            depth: 15
        ).instance(visibleRect: CGRect(x: 10, y: 10, width: 90, height: 98))
        let vip = SummaryLiveCellDescriptor(
            roomID: "1202",
            isVIP: true,
            status: .ready,
            statusPaletteSaturation: 1,
            cornerRadius: 16,
            depth: 15
        ).instance(visibleRect: CGRect(x: 110, y: 20, width: 90, height: 98))
        let offscreen = SummaryLiveCellDescriptor(
            roomID: "1203",
            isVIP: false,
            status: .scheduled,
            statusPaletteSaturation: 1,
            cornerRadius: 16,
            depth: 15
        ).instance(visibleRect: CGRect(x: 10, y: 900, width: 90, height: 98))
        let collection = SummaryLiveCellCollection(
            preferences: [
                ordinary.stableID: ordinary,
                vip.stableID: vip,
                offscreen.stableID: offscreen
            ],
            viewportSize: CGSize(width: 300, height: 500)
        )

        #expect(ordinary.profile == .normal)
        #expect(vip.profile == .vipBlob)
        #expect(collection.instances.map(\.stableID) == [ordinary.stableID, vip.stableID])
    }

    private func linearized(_ component: Float) -> Float {
        component <= 0.04045
            ? component / 12.92
            : pow((component + 0.055) / 1.055, 2.4)
    }
}
