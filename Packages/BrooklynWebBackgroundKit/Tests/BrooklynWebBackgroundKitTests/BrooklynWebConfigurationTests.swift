import Testing
@testable import BrooklynWebBackgroundKit

@Test func configurationDefaultsMatchDonorAndClampInvalidValues() {
    #expect(BrooklynWebConfiguration.default.cellScale == 1)
    #expect(BrooklynWebConfiguration.default.hue == BrooklynWebConfiguration.donorHue)
    #expect(BrooklynWebConfiguration.default.brightness == 1)
    #expect(BrooklynWebConfiguration.default.contrast == 0)

    let high = BrooklynWebConfiguration(
        cellScale: 99,
        hue: 99,
        brightness: 99,
        contrast: 99
    )
    #expect(high.cellScale == BrooklynWebConfiguration.cellScaleRange.upperBound)
    #expect(high.hue == BrooklynWebConfiguration.hueRange.upperBound)
    #expect(high.brightness == BrooklynWebConfiguration.brightnessRange.upperBound)
    #expect(high.contrast == BrooklynWebConfiguration.contrastRange.upperBound)

    let invalid = BrooklynWebConfiguration(
        cellScale: -.infinity,
        hue: .nan,
        brightness: .infinity,
        contrast: -.infinity
    )
    #expect(invalid == .default)
}
