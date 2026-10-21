import XCTest
@testable import BrooklynBackgroundKit

final class BrooklynAnimationTimelineTests: XCTestCase {
    func testTimelineSuspendsWithoutAdvancingAndResumesFromSameTime() {
        var timeline = BrooklynAnimationTimeline()
        timeline.setActive(true, at: 10)
        XCTAssertEqual(timeline.advance(to: 10.1), 0.1, accuracy: 0.0001)

        timeline.setActive(false, at: 10.1)
        XCTAssertEqual(timeline.advance(to: 40), 0.1, accuracy: 0.0001)

        timeline.setActive(true, at: 40)
        XCTAssertEqual(timeline.advance(to: 40.1), 0.2, accuracy: 0.0001)
    }

    func testTimelinePreservesCompleteElapsedTimeAcrossLongFrame() {
        var timeline = BrooklynAnimationTimeline()
        timeline.setActive(true, at: 0)
        XCTAssertEqual(timeline.advance(to: 2), 2, accuracy: 0.0001)
        XCTAssertTrue(timeline.isActive)
    }

    func testConfigurationDefaultsToExactDonorAndOnlyStyleVaries() {
        XCTAssertEqual(BrooklynBackgroundConfiguration.authorPreset.style, .donorExact)
        XCTAssertEqual(BrooklynBackgroundConfiguration.donorExact.style, .donorExact)
        XCTAssertEqual(BrooklynBackgroundConfiguration.enhanced.style, .enhanced)
        XCTAssertEqual(BrooklynSurfaceStyle.allCases, [.donorExact, .enhanced])
    }
}
