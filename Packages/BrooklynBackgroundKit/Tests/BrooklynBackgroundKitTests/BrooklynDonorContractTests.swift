import XCTest
@testable import BrooklynBackgroundKit

final class BrooklynDonorContractTests: XCTestCase {
    func testExactGridCameraAndViewportSpacing() {
        XCTAssertEqual(BrooklynDonorContract.gridSize, 16)
        XCTAssertEqual(BrooklynDonorContract.cameraZoom, 600)
        let viewport = BrooklynDonorContract.viewportSize(for: SIMD2(430, 932))
        XCTAssertEqual(viewport.x, 430.0 / 600.0, accuracy: 0.000001)
        XCTAssertEqual(viewport.y, 932.0 / 600.0, accuracy: 0.000001)
        XCTAssertEqual(BrooklynDonorContract.span(for: viewport), 4, accuracy: 0.000001)
        XCTAssertEqual(
            BrooklynDonorContract.spacing(for: viewport),
            4.0 / 15.0,
            accuracy: 0.000001
        )
    }

    func testStableSeedAndPowerSelectionMatchDonor() {
        XCTAssertEqual(BrooklynDonorContract.stableSeed(for: 0), 0, accuracy: 0.000000000001)
        XCTAssertEqual(
            BrooklynDonorContract.stableSeed(for: 1),
            0.618033988749895,
            accuracy: 0.000000000001
        )
        XCTAssertEqual(
            BrooklynDonorContract.stableSeed(for: 2),
            0.23606797749979,
            accuracy: 0.000000000001
        )
        XCTAssertEqual(BrooklynDonorContract.easePower(for: 0), 2)
        XCTAssertEqual(
            BrooklynDonorContract.easePower(for: BrooklynDonorContract.stableSeed(for: 1)),
            3
        )
        XCTAssertEqual(
            BrooklynDonorContract.easePower(for: BrooklynDonorContract.stableSeed(for: 3)),
            4
        )
        XCTAssertEqual(
            BrooklynDonorContract.powerEaseInOut(0.25, powerName: 2),
            0.0625,
            accuracy: 0.0000001
        )
        XCTAssertEqual(
            BrooklynDonorContract.powerEaseInOut(0.25, powerName: 4),
            0.015625,
            accuracy: 0.0000001
        )
    }

    func testTurnScheduleIncludesDelayDurationAndRepeatDelay() {
        let delay = BrooklynDonorContract.turnDelay(for: 0)
        let duration = BrooklynDonorContract.turnDuration(for: 0)
        let cycle = delay + duration + BrooklynDonorContract.repeatDelay(for: 0)

        XCTAssertEqual(BrooklynDonorContract.turnAngle(for: 0, at: delay), 0, accuracy: 0.000001)
        XCTAssertEqual(
            BrooklynDonorContract.turnAngle(for: 0, at: delay + duration / 2),
            .pi / 4,
            accuracy: 0.000001
        )
        XCTAssertEqual(
            BrooklynDonorContract.turnAngle(for: 0, at: delay + duration),
            .pi / 2,
            accuracy: 0.000001
        )
        XCTAssertEqual(
            BrooklynDonorContract.turnAngle(for: 0, at: cycle),
            .pi / 2,
            accuracy: 0.000001
        )
    }

    func testOneTimeBreathReturnsPermanentlyToBaseScale() {
        let spacing = 4.0 / 15.0
        let delay = BrooklynDonorContract.turnDelay(for: 0)
        let base = spacing * 0.9
        XCTAssertEqual(
            BrooklynDonorContract.particleScale(for: 0, spacing: spacing, at: delay + 2),
            base - 0.05,
            accuracy: 0.000001
        )
        XCTAssertEqual(
            BrooklynDonorContract.particleScale(for: 0, spacing: spacing, at: delay + 4),
            base,
            accuracy: 0.000001
        )
        XCTAssertEqual(
            BrooklynDonorContract.particleScale(for: 0, spacing: spacing, at: delay + 40),
            base,
            accuracy: 0.000001
        )
    }

    func testStaticHighlightMatchesThreeGoldenValues() {
        let phoneViewport = BrooklynDonorContract.viewportSize(for: SIMD2(430, 932))
        XCTAssertEqual(
            BrooklynDonorContract.highlightedInstance(
                viewportSize: phoneViewport,
                spacing: BrooklynDonorContract.spacing(for: phoneViewport)
            ),
            102
        )

        let landscapeViewport = BrooklynDonorContract.viewportSize(for: SIMD2(1_024, 768))
        XCTAssertEqual(
            BrooklynDonorContract.highlightedInstance(
                viewportSize: landscapeViewport,
                spacing: BrooklynDonorContract.spacing(for: landscapeViewport)
            ),
            117
        )
    }
}
