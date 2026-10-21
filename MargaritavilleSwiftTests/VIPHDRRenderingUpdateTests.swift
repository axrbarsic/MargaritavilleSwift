import Testing
@testable import MargaritavilleSwift

@Suite
struct VIPHDRRenderingUpdateTests {
    @Test
    func initialAndUnchangedConfigurationsClassifyMinimalWork() {
        let configuration = makeConfiguration()

        #expect(
            configuration.changes(comparedTo: nil) == [.display, .mask]
        )
        #expect(configuration.changes(comparedTo: configuration).isEmpty)
    }

    @Test
    func displayOnlyChangeDoesNotRebuildMask() {
        let previous = makeConfiguration()
        let changed = VIPHDRStatusFillConfiguration(
            display: .init(
                intensity: 1.35,
                red: previous.display.red,
                green: previous.display.green,
                blue: previous.display.blue,
                seed: previous.display.seed
            ),
            mask: previous.mask
        )

        #expect(changed.changes(comparedTo: previous) == .display)
    }

    @Test
    func maskOnlyChangeDoesNotRequestRedraw() {
        let previous = makeConfiguration()
        let changed = VIPHDRStatusFillConfiguration(
            display: previous.display,
            mask: .init(
                cornerRadius: previous.mask.cornerRadius,
                isMenuExpanded: true,
                usesExternalMask: previous.mask.usesExternalMask
            )
        )

        #expect(changed.changes(comparedTo: previous) == .mask)
    }

    private func makeConfiguration() -> VIPHDRStatusFillConfiguration {
        VIPHDRStatusFillConfiguration(
            display: .init(
                intensity: 1,
                red: 0.2,
                green: 1.1,
                blue: 0.3,
                seed: 0.42
            ),
            mask: .init(
                cornerRadius: 16,
                isMenuExpanded: false,
                usesExternalMask: true
            )
        )
    }
}
