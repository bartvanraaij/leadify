import XCTest

/// A single long-running test that simulates a real user session.
/// The app launches once and the user navigates through a full performance
/// without restarting — state accumulates naturally.
final class PerformanceIntegrationTest: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    // MARK: - Helpers

    var contentArea: XCUIElement {
        app.descendants(matching: .any).matching(identifier: "performance-content-area").firstMatch
    }

    func entry(_ index: Int) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "performance-entry-\(index)").firstMatch
    }

    private func tapContentArea(atHorizontalFraction dx: CGFloat) {
        let contentFrame = contentArea.frame
        let tapX = contentFrame.minX + contentFrame.width * dx
        let tapY = app.frame.midY
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: tapX, dy: tapY))
            .tap()
    }

    func tapRightZone() { tapContentArea(atHorizontalFraction: 0.85) }
    func tapLeftZone() { tapContentArea(atHorizontalFraction: 0.15) }
    func tapCenterZone() { tapContentArea(atHorizontalFraction: 0.5) }

    func revealToolbar() {
        let toolbar = app.descendants(matching: .any).matching(identifier: "performance-toolbar").firstMatch
        if !toolbar.exists {
            tapCenterZone()
            XCTAssertTrue(toolbar.waitForExistence(timeout: 2), "Toolbar should appear after center tap")
        }
    }

    func assertActive(_ index: Int, file: StaticString = #filePath, line: UInt = #line) {
        let el = entry(index)
        XCTAssertTrue(el.waitForExistence(timeout: 2), "Entry \(index) not found", file: file, line: line)
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if el.label.hasPrefix("Active:") { return }
            usleep(50_000)
        }
        XCTFail("Entry \(index) should be active, got: '\(el.label)'", file: file, line: line)
    }

    func ensureSidebarOpen() {
        let sidebar = app.descendants(matching: .any).matching(identifier: "performance-sidebar").firstMatch
        if !sidebar.exists {
            revealToolbar()
            app.buttons["toggle-sidebar"].tap()
            XCTAssertTrue(sidebar.waitForExistence(timeout: 2), "Sidebar should appear after toggle")
        }
    }

    // MARK: - The test

    func test_fullUserSession() {
        // === Open the setlist and enter performance ===
        let setlistRow = app.staticTexts["Friday Night Gig"]
        XCTAssertTrue(setlistRow.waitForExistence(timeout: 2))
        setlistRow.tap()

        let performButton = app.buttons["Perform"]
        XCTAssertTrue(performButton.waitForExistence(timeout: 2))
        performButton.tap()

        XCTAssertTrue(entry(0).waitForExistence(timeout: 2), "Performance view should open")
        assertActive(0)

        // === Navigate forward through first few songs ===
        tapRightZone()
        assertActive(1) // Painted Sky

        tapRightZone()
        let movedPast1 = entry(1).label.hasPrefix("Active:") || entry(2).label.hasPrefix("Active:")
        XCTAssertTrue(movedPast1)

        // === Go back to the start ===
        tapLeftZone()
        tapLeftZone()
        tapLeftZone()
        assertActive(0) // Back to Canal Morning

        // === Use sidebar to jump to a medley ===
        ensureSidebarOpen()

        let sidebarRow4 = app.descendants(matching: .any).matching(identifier: "sidebar-row-4").firstMatch
        XCTAssertTrue(sidebarRow4.waitForExistence(timeout: 2), "Sidebar row 4 should exist")
        sidebarRow4.tap()
        assertActive(4) // Folk Trio medley
        XCTAssertTrue(app.staticTexts["Folk Trio"].waitForExistence(timeout: 2))

        // === Navigate forward from the medley ===
        tapRightZone()
        assertActive(5) // Passengers (very long)

        // === Test chevron scrolling on a long song (if entry is taller than viewport) ===
        let downChevron = app.buttons["scroll-down-chevron"]
        if downChevron.waitForExistence(timeout: 2) {
            downChevron.tap()

            let upChevron = app.buttons["scroll-up-chevron"]
            XCTAssertTrue(upChevron.waitForExistence(timeout: 2), "Up chevron should appear after scrolling down")
            upChevron.tap()
            XCTAssertTrue(downChevron.waitForExistence(timeout: 2), "Down chevron should still exist")
        }
        // If chevrons don't appear, the song fits at this window size — that's fine

        // === Use sidebar next/prev buttons ===
        ensureSidebarOpen()

        let nextButton = app.descendants(matching: .any).matching(identifier: "sidebar-next").firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 2), "Sidebar next button should exist")
        nextButton.tap()
        assertActive(6) // Velvet Dusk

        let prevButton = app.descendants(matching: .any).matching(identifier: "sidebar-previous").firstMatch
        XCTAssertTrue(prevButton.waitForExistence(timeout: 2), "Sidebar previous button should exist")
        prevButton.tap()
        assertActive(5) // Back to Passengers

        // === Jump to the end ===
        let sidebarRow11 = app.descendants(matching: .any).matching(identifier: "sidebar-row-11").firstMatch
        XCTAssertTrue(sidebarRow11.waitForExistence(timeout: 2), "Sidebar row 11 should exist")
        sidebarRow11.tap()
        assertActive(11) // Last Train Home

        // === Right tap at the end does nothing ===
        tapRightZone()
        tapRightZone()
        assertActive(11)

        // === Jump back to the beginning ===
        let sidebarRow0 = app.descendants(matching: .any).matching(identifier: "sidebar-row-0").firstMatch
        XCTAssertTrue(sidebarRow0.waitForExistence(timeout: 2), "Sidebar row 0 should exist")
        sidebarRow0.tap()
        assertActive(0)

        // === Left tap at the beginning does nothing ===
        tapLeftZone()
        assertActive(0)

        // === Close performance and reopen it ===
        revealToolbar()
        app.buttons["close-performance"].tap()
        XCTAssertTrue(performButton.waitForExistence(timeout: 2), "Should be back at setlist detail")

        performButton.tap()
        XCTAssertTrue(entry(0).waitForExistence(timeout: 2), "Performance should reopen")
        assertActive(0) // Fresh start, back at entry 0

        // === Quick forward/back after reopen to confirm state is clean ===
        tapRightZone()
        assertActive(1)
        tapLeftZone()
        assertActive(0)

        // === Toggle sidebar off and on ===
        revealToolbar()
        let toggleButton = app.buttons["toggle-sidebar"]
        toggleButton.tap()
        revealToolbar()
        toggleButton.tap()

        // === Still functional after sidebar toggle ===
        tapRightZone()
        assertActive(1)

        // === Close performance — session complete ===
        revealToolbar()
        app.buttons["close-performance"].tap()
        XCTAssertTrue(performButton.waitForExistence(timeout: 2), "Should end at setlist detail")
    }
}
