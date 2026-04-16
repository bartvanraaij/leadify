import XCTest
@testable import Leadify

final class PerformanceNavigationTests: XCTestCase {
    // MARK: - Right tap (forward)

    func test_rightTap_activeEntryExtendsBelow_scrollsWithinEntry() {
        let result = PerformanceNavigator.handleTap(
            direction: .forward,
            activeIndex: 0,
            entryCount: 3,
            activeEntryFrame: CGRect(x: 0, y: 0, width: 700, height: 800),
            scrollOffset: 0,
            viewportHeight: 600
        )
        XCTAssertEqual(result.newActiveIndex, 0)
        XCTAssertNotNil(result.scrollTarget)
        XCTAssertEqual(result.scrollTarget!, 360, accuracy: 1)
    }

    func test_rightTap_activeEntryFullyVisible_advancesToNext() {
        let result = PerformanceNavigator.handleTap(
            direction: .forward,
            activeIndex: 0,
            entryCount: 3,
            activeEntryFrame: CGRect(x: 0, y: 0, width: 700, height: 400),
            scrollOffset: 0,
            viewportHeight: 600
        )
        XCTAssertEqual(result.newActiveIndex, 1)
        XCTAssertNil(result.scrollTarget)
    }

    func test_rightTap_lastEntry_bottomVisible_doesNothing() {
        let result = PerformanceNavigator.handleTap(
            direction: .forward,
            activeIndex: 2,
            entryCount: 3,
            activeEntryFrame: CGRect(x: 0, y: 0, width: 700, height: 400),
            scrollOffset: 0,
            viewportHeight: 600
        )
        XCTAssertEqual(result.newActiveIndex, 2)
        XCTAssertNil(result.scrollTarget)
    }

    func test_rightTap_lastEntry_extendsBelow_scrollsWithin() {
        let result = PerformanceNavigator.handleTap(
            direction: .forward,
            activeIndex: 2,
            entryCount: 3,
            activeEntryFrame: CGRect(x: 0, y: 0, width: 700, height: 800),
            scrollOffset: 0,
            viewportHeight: 600
        )
        XCTAssertEqual(result.newActiveIndex, 2)
        XCTAssertNotNil(result.scrollTarget)
        XCTAssertEqual(result.scrollTarget!, 360, accuracy: 1)
    }

    // MARK: - Left tap (backward)

    func test_leftTap_activeEntryExtendsAbove_scrollsWithinEntry() {
        let result = PerformanceNavigator.handleTap(
            direction: .backward,
            activeIndex: 1,
            entryCount: 3,
            activeEntryFrame: CGRect(x: 0, y: -200, width: 700, height: 800),
            scrollOffset: 500,
            viewportHeight: 600
        )
        XCTAssertEqual(result.newActiveIndex, 1)
        XCTAssertNotNil(result.scrollTarget)
        XCTAssertEqual(result.scrollTarget!, 140, accuracy: 1)
    }

    func test_leftTap_activeEntryTopVisible_goesToPrevious() {
        let result = PerformanceNavigator.handleTap(
            direction: .backward,
            activeIndex: 1,
            entryCount: 3,
            activeEntryFrame: CGRect(x: 0, y: 20, width: 700, height: 400),
            scrollOffset: 100,
            viewportHeight: 600
        )
        XCTAssertEqual(result.newActiveIndex, 0)
        XCTAssertNil(result.scrollTarget)
    }

    func test_leftTap_firstEntry_topVisible_doesNothing() {
        let result = PerformanceNavigator.handleTap(
            direction: .backward,
            activeIndex: 0,
            entryCount: 3,
            activeEntryFrame: CGRect(x: 0, y: 0, width: 700, height: 400),
            scrollOffset: 0,
            viewportHeight: 600
        )
        XCTAssertEqual(result.newActiveIndex, 0)
        XCTAssertNil(result.scrollTarget)
    }
}
