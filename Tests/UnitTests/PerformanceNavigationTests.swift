import XCTest
@testable import Leadify

// MARK: - ScreenNavigator

final class ScreenNavigatorTests: XCTestCase {
    func test_forward_scrollsByOneViewport() {
        let result = ScreenNavigator.handleTap(
            direction: .forward,
            scrollOffset: 100,
            viewportHeight: 600
        )
        XCTAssertEqual(result, 700)
    }

    func test_backward_scrollsByOneViewport() {
        let result = ScreenNavigator.handleTap(
            direction: .backward,
            scrollOffset: 800,
            viewportHeight: 600
        )
        XCTAssertEqual(result, 200)
    }

    func test_backward_clampsToZero() {
        let result = ScreenNavigator.handleTap(
            direction: .backward,
            scrollOffset: 200,
            viewportHeight: 600
        )
        XCTAssertEqual(result, 0)
    }
}

// MARK: - SongNavigator

final class SongNavigatorTests: XCTestCase {
    func test_rightTap_activeEntryExtendsBelow_scrollsWithinEntry() {
        let result = SongNavigator.handleTap(
            direction: .forward,
            activeIndex: 0,
            entryCount: 3,
            activeEntryFrame: CGRect(x: 0, y: 0, width: 700, height: 800),
            scrollOffset: 0,
            viewportHeight: 600
        )
        XCTAssertEqual(result.newActiveIndex, 0)
        XCTAssertNotNil(result.scrollTarget)
        let expectedLastSnap = 800 - PerformanceTheme.dividerHeight - 600
        XCTAssertEqual(result.scrollTarget!, expectedLastSnap, accuracy: 1)
    }

    func test_rightTap_activeEntryFullyVisible_advancesToNext() {
        let result = SongNavigator.handleTap(
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
        let result = SongNavigator.handleTap(
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
        let result = SongNavigator.handleTap(
            direction: .forward,
            activeIndex: 2,
            entryCount: 3,
            activeEntryFrame: CGRect(x: 0, y: 0, width: 700, height: 800),
            scrollOffset: 0,
            viewportHeight: 600
        )
        XCTAssertEqual(result.newActiveIndex, 2)
        XCTAssertNotNil(result.scrollTarget)
        let expectedLastSnap = 800 - PerformanceTheme.dividerHeight - 600
        XCTAssertEqual(result.scrollTarget!, expectedLastSnap, accuracy: 1)
    }

    func test_leftTap_activeEntryExtendsAbove_scrollsWithinEntry() {
        let frame = CGRect(x: 0, y: 0, width: 700, height: 1800)
        let result = SongNavigator.handleTap(
            direction: .backward,
            activeIndex: 1,
            entryCount: 3,
            activeEntryFrame: frame,
            scrollOffset: 600,
            viewportHeight: 600
        )
        XCTAssertEqual(result.newActiveIndex, 1)
        XCTAssertNotNil(result.scrollTarget)
        XCTAssertEqual(result.scrollTarget!, 0, accuracy: 1)
    }

    func test_leftTap_activeEntryTopVisible_goesToPrevious() {
        let result = SongNavigator.handleTap(
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
        let result = SongNavigator.handleTap(
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

// MARK: - SmartNavigator

final class SmartNavigatorTests: XCTestCase {

    // MARK: - computeNextTarget

    func test_nextTarget_skipsFullyVisibleItems() {
        // Active at y=0, items 1 and 2 fit on screen, item 3 extends below
        let frames: [Int: CGRect] = [
            0: CGRect(x: 0, y: 0,    width: 700, height: 100),
            1: CGRect(x: 0, y: 100,  width: 700, height: 100),
            2: CGRect(x: 0, y: 200,  width: 700, height: 100),
            3: CGRect(x: 0, y: 300,  width: 700, height: 500),
        ]
        let result = SmartNavigator.computeNextTarget(
            activeIndex: 0,
            entryFrames: frames,
            entryCount: 4,
            isSkippable: { _ in false },
            viewportHeight: 600
        )
        XCTAssertEqual(result, 3)
    }

    func test_nextTarget_skipsSkippableItems() {
        let frames: [Int: CGRect] = [
            0: CGRect(x: 0, y: 0,    width: 700, height: 100),
            1: CGRect(x: 0, y: 100,  width: 700, height: 50),  // tacet
            2: CGRect(x: 0, y: 150,  width: 700, height: 600),
        ]
        let result = SmartNavigator.computeNextTarget(
            activeIndex: 0,
            entryFrames: frames,
            entryCount: 3,
            isSkippable: { $0 == 1 },
            viewportHeight: 600
        )
        XCTAssertEqual(result, 2)
    }

    func test_nextTarget_allVisible_returnsNil() {
        let frames: [Int: CGRect] = [
            0: CGRect(x: 0, y: 0,   width: 700, height: 100),
            1: CGRect(x: 0, y: 100, width: 700, height: 100),
            2: CGRect(x: 0, y: 200, width: 700, height: 100),
        ]
        let result = SmartNavigator.computeNextTarget(
            activeIndex: 0,
            entryFrames: frames,
            entryCount: 3,
            isSkippable: { _ in false },
            viewportHeight: 600
        )
        XCTAssertNil(result)
    }

    // MARK: - handleForward

    func test_forward_tallEntry_scrollsWithin() {
        var state = SmartNavigationState()
        state.nextTargetIndex = 1
        let result = SmartNavigator.handleForward(
            state: &state,
            activeIndex: 0,
            activeEntryFrame: CGRect(x: 0, y: 0, width: 700, height: 1200),
            scrollOffset: 0,
            viewportHeight: 600,
            overlap: 0
        )
        if case .scrollWithin(let target) = result {
            XCTAssertGreaterThan(target, 0)
        } else {
            XCTFail("Expected scrollWithin, got \(result)")
        }
        XCTAssertTrue(state.backStack.isEmpty)
    }

    func test_forward_jumpsToTarget_pushesBackStack() {
        var state = SmartNavigationState()
        state.nextTargetIndex = 3
        let result = SmartNavigator.handleForward(
            state: &state,
            activeIndex: 0,
            activeEntryFrame: CGRect(x: 0, y: 0, width: 700, height: 200),
            scrollOffset: 0,
            viewportHeight: 600,
            overlap: 0
        )
        XCTAssertEqual(result, .jumpTo(index: 3))
        XCTAssertEqual(state.backStack, [0])
    }

    func test_forward_noTarget_returnsNone() {
        var state = SmartNavigationState()
        state.nextTargetIndex = nil
        let result = SmartNavigator.handleForward(
            state: &state,
            activeIndex: 0,
            activeEntryFrame: CGRect(x: 0, y: 0, width: 700, height: 200),
            scrollOffset: 0,
            viewportHeight: 600,
            overlap: 0
        )
        XCTAssertEqual(result, .none)
    }

    // MARK: - handleBack

    func test_back_tallEntry_scrollsWithin() {
        var state = SmartNavigationState()
        state.backStack = [0]
        let result = SmartNavigator.handleBack(
            state: &state,
            activeIndex: 1,
            activeEntryFrame: CGRect(x: 0, y: 0, width: 700, height: 1200),
            scrollOffset: 600,
            viewportHeight: 600,
            overlap: 0,
            previousNavigableIndex: 0
        )
        if case .scrollWithin(let target) = result {
            XCTAssertLessThan(target, 600)
        } else {
            XCTFail("Expected scrollWithin, got \(result)")
        }
        XCTAssertEqual(state.backStack, [0])
    }

    func test_back_popsFromStack() {
        var state = SmartNavigationState()
        state.backStack = [0, 2]
        let result = SmartNavigator.handleBack(
            state: &state,
            activeIndex: 5,
            activeEntryFrame: CGRect(x: 0, y: 500, width: 700, height: 200),
            scrollOffset: 500,
            viewportHeight: 600,
            overlap: 0,
            previousNavigableIndex: 4
        )
        XCTAssertEqual(result, .jumpTo(index: 2))
        XCTAssertEqual(state.backStack, [0])
    }

    func test_back_emptyStack_fallsToPreviousNavigable() {
        var state = SmartNavigationState()
        let result = SmartNavigator.handleBack(
            state: &state,
            activeIndex: 5,
            activeEntryFrame: CGRect(x: 0, y: 500, width: 700, height: 200),
            scrollOffset: 500,
            viewportHeight: 600,
            overlap: 0,
            previousNavigableIndex: 3
        )
        XCTAssertEqual(result, .jumpTo(index: 3))
    }

    func test_back_emptyStack_noPrevious_returnsNone() {
        var state = SmartNavigationState()
        let result = SmartNavigator.handleBack(
            state: &state,
            activeIndex: 0,
            activeEntryFrame: CGRect(x: 0, y: 0, width: 700, height: 200),
            scrollOffset: 0,
            viewportHeight: 600,
            overlap: 0,
            previousNavigableIndex: nil
        )
        XCTAssertEqual(result, .none)
    }
}
