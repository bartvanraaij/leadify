import XCTest
@testable import LeadifyCore

final class PerformanceScrollCalculatorTests: XCTestCase {

    // MARK: - inEntrySnaps

    func test_snaps_shortEntry_returnsSingleSnap() {
        // Entry fits entirely within viewport — only one snap at the top
        let frame = CGRect(x: 0, y: 100, width: 700, height: 400)
        let snaps = PerformanceScrollCalculator.inEntrySnaps(for: frame, viewportHeight: 600)
        XCTAssertEqual(snaps, [100])
    }

    func test_snaps_entryExactlyViewportHeight_returnsSingleSnap() {
        // Entry height equals viewport — lastSnap = 600 - 600 = 0, not > 0 + 1, so single snap
        let frame = CGRect(x: 0, y: 0, width: 700, height: 600)
        let snaps = PerformanceScrollCalculator.inEntrySnaps(for: frame, viewportHeight: 600)
        XCTAssertEqual(snaps, [0])
    }

    func test_snaps_tallEntry_generatesMultipleSnaps() {
        // viewport 600, step = 600
        // frame: y=0, height=1500 → lastSnap = 1500 - 600 = 900
        // snaps: 0, 600, 900
        let frame = CGRect(x: 0, y: 0, width: 700, height: 1500)
        let snaps = PerformanceScrollCalculator.inEntrySnaps(for: frame, viewportHeight: 600)
        XCTAssertEqual(snaps.count, 3)
        XCTAssertEqual(snaps[0], 0, accuracy: 1)
        XCTAssertEqual(snaps[1], 600, accuracy: 1)
        XCTAssertEqual(snaps[2], 900, accuracy: 1)
    }

    func test_snaps_entryNotAtOrigin_snapsStartAtFrameMinY() {
        // frame starts at y=500, height=1200, viewport=600
        // lastSnap = 1700 - 600 = 1100
        // step = 600
        // snaps: 500, 1100
        let frame = CGRect(x: 0, y: 500, width: 700, height: 1200)
        let snaps = PerformanceScrollCalculator.inEntrySnaps(for: frame, viewportHeight: 600)
        XCTAssertEqual(snaps.count, 2)
        XCTAssertEqual(snaps[0], 500, accuracy: 1)
        XCTAssertEqual(snaps[1], 1100, accuracy: 1)
    }

    func test_snaps_veryTallEntry_generatesManySnaps() {
        // frame: y=0, height=3000, viewport=600
        // step = 600, lastSnap = 3000 - 600 = 2400
        // snaps: 0, 600, 1200, 1800, 2400
        let frame = CGRect(x: 0, y: 0, width: 700, height: 3000)
        let snaps = PerformanceScrollCalculator.inEntrySnaps(for: frame, viewportHeight: 600)
        XCTAssertEqual(snaps.count, 5)
        XCTAssertEqual(snaps.first!, 0, accuracy: 1)
        XCTAssertEqual(snaps.last!, 2400, accuracy: 1)
    }

    // MARK: - canScrollDown

    func test_canScrollDown_nilFrame_returnsFalse() {
        XCTAssertFalse(PerformanceScrollCalculator.canScrollDown(
            activeEntryFrame: nil, scrollOffset: 0, viewportHeight: 600
        ))
    }

    func test_canScrollDown_entryFullyVisible_returnsFalse() {
        let frame = CGRect(x: 0, y: 0, width: 700, height: 400)
        XCTAssertFalse(PerformanceScrollCalculator.canScrollDown(
            activeEntryFrame: frame, scrollOffset: 0, viewportHeight: 600
        ))
    }

    func test_canScrollDown_entryExtendsBelow_returnsTrue() {
        let frame = CGRect(x: 0, y: 0, width: 700, height: 1500)
        XCTAssertTrue(PerformanceScrollCalculator.canScrollDown(
            activeEntryFrame: frame, scrollOffset: 0, viewportHeight: 600
        ))
    }

    func test_canScrollDown_scrollNotYetAtEntry_returnsFalse() {
        // Entry starts at y=1000 but scroll is at 0 — haven't reached the entry yet
        let frame = CGRect(x: 0, y: 1000, width: 700, height: 1500)
        XCTAssertFalse(PerformanceScrollCalculator.canScrollDown(
            activeEntryFrame: frame, scrollOffset: 0, viewportHeight: 600
        ))
    }

    func test_canScrollDown_scrolledToEntry_returnsTrue() {
        let frame = CGRect(x: 0, y: 1000, width: 700, height: 1500)
        XCTAssertTrue(PerformanceScrollCalculator.canScrollDown(
            activeEntryFrame: frame, scrollOffset: 1000, viewportHeight: 600
        ))
    }

    // MARK: - canScrollUp

    func test_canScrollUp_nilFrame_returnsFalse() {
        XCTAssertFalse(PerformanceScrollCalculator.canScrollUp(
            activeEntryFrame: nil, scrollOffset: 0, viewportHeight: 600
        ))
    }

    func test_canScrollUp_atTop_returnsFalse() {
        let frame = CGRect(x: 0, y: 0, width: 700, height: 1500)
        XCTAssertFalse(PerformanceScrollCalculator.canScrollUp(
            activeEntryFrame: frame, scrollOffset: 0, viewportHeight: 600
        ))
    }

    func test_canScrollUp_scrolledDown_returnsTrue() {
        let frame = CGRect(x: 0, y: 0, width: 700, height: 1500)
        XCTAssertTrue(PerformanceScrollCalculator.canScrollUp(
            activeEntryFrame: frame, scrollOffset: 600, viewportHeight: 600
        ))
    }

    func test_canScrollUp_scrolledPastEntry_returnsFalse() {
        // scrollOffset is well past the entry's last snap
        let frame = CGRect(x: 0, y: 0, width: 700, height: 1500)
        // lastSnap = 1500 - 600 = 900
        XCTAssertFalse(PerformanceScrollCalculator.canScrollUp(
            activeEntryFrame: frame, scrollOffset: 1500, viewportHeight: 600
        ))
    }

    // MARK: - nextSnapDown

    func test_nextSnapDown_atTop_returnsFirstStepDown() {
        let frame = CGRect(x: 0, y: 0, width: 700, height: 1500)
        let target = PerformanceScrollCalculator.nextSnapDown(
            activeEntryFrame: frame, scrollOffset: 0, viewportHeight: 600
        )
        XCTAssertNotNil(target)
        XCTAssertEqual(target!, 600, accuracy: 1)
    }

    func test_nextSnapDown_atMiddle_returnsNextSnap() {
        let frame = CGRect(x: 0, y: 0, width: 700, height: 1500)
        let target = PerformanceScrollCalculator.nextSnapDown(
            activeEntryFrame: frame, scrollOffset: 600, viewportHeight: 600
        )
        XCTAssertNotNil(target)
        // lastSnap = 900
        XCTAssertEqual(target!, 900, accuracy: 1)
    }

    func test_nextSnapDown_atLastSnap_returnsNil() {
        let frame = CGRect(x: 0, y: 0, width: 700, height: 1500)
        let target = PerformanceScrollCalculator.nextSnapDown(
            activeEntryFrame: frame, scrollOffset: 900, viewportHeight: 600
        )
        XCTAssertNil(target)
    }

    func test_nextSnapDown_shortEntry_returnsNil() {
        let frame = CGRect(x: 0, y: 0, width: 700, height: 400)
        let target = PerformanceScrollCalculator.nextSnapDown(
            activeEntryFrame: frame, scrollOffset: 0, viewportHeight: 600
        )
        XCTAssertNil(target)
    }

    // MARK: - nextSnapUp

    func test_nextSnapUp_atBottom_returnsPreviousSnap() {
        let frame = CGRect(x: 0, y: 0, width: 700, height: 1500)
        // snaps: [0, 600, 900], at 900 → previous is 600
        let target = PerformanceScrollCalculator.nextSnapUp(
            activeEntryFrame: frame, scrollOffset: 900, viewportHeight: 600
        )
        XCTAssertNotNil(target)
        XCTAssertEqual(target!, 600, accuracy: 1)
    }

    func test_nextSnapUp_atMiddle_returnsTop() {
        let frame = CGRect(x: 0, y: 0, width: 700, height: 1500)
        let target = PerformanceScrollCalculator.nextSnapUp(
            activeEntryFrame: frame, scrollOffset: 600, viewportHeight: 600
        )
        XCTAssertNotNil(target)
        XCTAssertEqual(target!, 0, accuracy: 1)
    }

    func test_nextSnapUp_atTop_returnsNil() {
        let frame = CGRect(x: 0, y: 0, width: 700, height: 1500)
        let target = PerformanceScrollCalculator.nextSnapUp(
            activeEntryFrame: frame, scrollOffset: 0, viewportHeight: 600
        )
        XCTAssertNil(target)
    }
}
