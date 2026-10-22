import XCTest
import simd
@testable import BrooklynBackgroundKit

final class BrooklynGridLayoutTests: XCTestCase {
    private let phoneViewport = BrooklynDonorContract.viewportSize(for: SIMD2(430, 932))

    func testDonorCellsMatchFormerShaderInstanceFormula() {
        let cells = BrooklynGridLayout.donorCells
        XCTAssertEqual(cells.count, 256)
        for (index, cell) in cells.enumerated() {
            XCTAssertEqual(cell.gridX, Float(index / 16) - 7.5)
            XCTAssertEqual(cell.gridZ, Float(index % 16) - 7.5)
            XCTAssertEqual(cell.seed, Float(BrooklynDonorContract.stableSeed(for: index)), accuracy: 0.000001)
        }
    }

    func testDefaultAndZoomedInScalesKeepExactDonorGrid() {
        let spacing = BrooklynDonorContract.spacing(for: phoneViewport)
        for scale: Float in [1, 1.25] {
            XCTAssertEqual(
                BrooklynGridLayout.cells(cellScale: scale, baseViewport: phoneViewport, spacing: spacing),
                BrooklynGridLayout.donorCells
            )
        }
    }

    func testSmallerCellsExtendGridOnlyWithVisibleUniqueEdgeCells() {
        let spacing = BrooklynDonorContract.spacing(for: phoneViewport)
        let scale: Float = 0.45
        let cells = BrooklynGridLayout.cells(cellScale: scale, baseViewport: phoneViewport, spacing: spacing)
        XCTAssertGreaterThan(cells.count, 256)
        XCTAssertEqual(Array(cells.prefix(256)), BrooklynGridLayout.donorCells)
        XCTAssertEqual(Set(cells.map { SIMD2($0.gridX, $0.gridZ) }).count, cells.count)

        let halfWidth = phoneViewport.x / (2 * scale) + spacing * BrooklynGridLayout.coverageGuardCells
        let halfHeight = phoneViewport.y / (2 * scale) + spacing * BrooklynGridLayout.coverageGuardCells
        for cell in cells.dropFirst(256) {
            let world = BrooklynGridLayout.toWorld(SIMD3(cell.gridX * spacing, 0, cell.gridZ * spacing))
            XCTAssertLessThanOrEqual(abs(world.x), halfWidth)
            XCTAssertLessThanOrEqual(abs(world.y), halfHeight)
            XCTAssertEqual(cell.seed, BrooklynGridLayout.coordinateSeed(cell.gridX, cell.gridZ))
        }
    }

    func testHighlightAtDefaultScaleMatchesFormerGoldenInstances() {
        // Прежние эталоны: экземпляр 102 (ряд 6, колонка 6) и 117 (ряд 7, колонка 5).
        let phone = BrooklynGridLayout.highlightedCell(
            cellScale: 1,
            baseViewport: phoneViewport,
            spacing: BrooklynDonorContract.spacing(for: phoneViewport)
        )
        XCTAssertEqual(phone, SIMD2(-1.5, -1.5))

        let landscapeViewport = BrooklynDonorContract.viewportSize(for: SIMD2(1_024, 768))
        let landscape = BrooklynGridLayout.highlightedCell(
            cellScale: 1,
            baseViewport: landscapeViewport,
            spacing: BrooklynDonorContract.spacing(for: landscapeViewport)
        )
        XCTAssertEqual(landscape, SIMD2(-0.5, -2.5))
    }

    func testLocalAndWorldRotationsAreInverse() {
        let point = SIMD3<Float>(0.7, -0.3, 1.9)
        let roundTrip = BrooklynGridLayout.toLocal(BrooklynGridLayout.toWorld(point))
        XCTAssertEqual(roundTrip.x, point.x, accuracy: 0.00001)
        XCTAssertEqual(roundTrip.y, point.y, accuracy: 0.00001)
        XCTAssertEqual(roundTrip.z, point.z, accuracy: 0.00001)
    }
}

final class BrooklynAppearanceTests: XCTestCase {
    func testDefaultsAndClampingMatchFormerWebRanges() {
        XCTAssertEqual(BrooklynAppearance.default.cellScale, 1)
        XCTAssertEqual(BrooklynAppearance.default.hue, 0.9502923976608187)
        XCTAssertEqual(BrooklynAppearance.default.brightness, 1)
        XCTAssertEqual(BrooklynAppearance.default.contrast, 0)

        let clamped = BrooklynAppearance(cellScale: 10, hue: -1, brightness: .nan, contrast: -3)
        XCTAssertEqual(clamped.cellScale, 1.25)
        XCTAssertEqual(clamped.hue, 0)
        XCTAssertEqual(clamped.brightness, 1)
        XCTAssertEqual(clamped.contrast, -0.5)
    }

    func testDonorHueKeepsExactColorsAndShiftRotatesHueOnly() {
        let base = BrooklynDonorContract.baseColorSRGB
        XCTAssertEqual(BrooklynAppearance.default.shiftedColor(base), base)

        let donorHSL = BrooklynHSL(srgb: base)
        XCTAssertEqual(donorHSL.hue, BrooklynAppearance.donorHue, accuracy: 0.0001)

        let shifted = BrooklynAppearance(hue: 0.45).shiftedColor(base)
        let shiftedHSL = BrooklynHSL(srgb: shifted)
        XCTAssertEqual(shiftedHSL.hue, 0.45, accuracy: 0.001)
        XCTAssertEqual(shiftedHSL.saturation, donorHSL.saturation, accuracy: 0.001)
        XCTAssertEqual(shiftedHSL.lightness, donorHSL.lightness, accuracy: 0.001)
    }
}
