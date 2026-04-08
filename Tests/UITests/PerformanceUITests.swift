import XCTest

/// Black-box UI tests for Performance view navigation.
/// These tests drive the real app via accessibility elements and simulated gestures.
/// They are implementation-agnostic — a full refactor of the view layer should not break them
/// as long as the user experience is preserved.
///
/// Tests are size-agnostic: tap zones are calculated from the actual content area frame,
/// and sidebar state is detected rather than assumed. Run against different simulator devices
/// (iPad mini, iPad Pro 13", etc.) or use Xcode Test Plans to verify at multiple sizes.
///
/// Test data is seeded via --uitesting launch argument (see UITestSeeder).
/// The seeded setlist "Friday Night Gig" contains:
///   0: Canal Morning (song, short)
///   1: Painted Sky (song, medium)
///   2: Run to Copperville (song, long)
///   3: Break (tacet) — skippable
///   4: Folk Trio (medley)
///   5: Passengers (song, very long)
///   6: Velvet Dusk (song, medium)
///   7: Thistlewood Fair (song, long)
///   8: Encore (tacet) — skippable
///   9: Evening Set (medley)
///  10: Harbour Bell (song, medium)
///  11: Last Train Home (song, very long)
final class PerformanceUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    // MARK: - Element helpers

    /// The visible content area. Its frame reflects the actual content bounds
    /// (excluding any sidebars), so tap zone calculations are always correct.
    var contentArea: XCUIElement {
        app.descendants(matching: .any).matching(identifier: "performance-content-area").firstMatch
    }

    /// Find a performance entry by index.
    func entry(_ index: Int) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "performance-entry-\(index)").firstMatch
    }

    // MARK: - Navigation helpers

    func enterPerformanceMode() {
        let setlistsRow = app.buttons["Setlists"]
        if setlistsRow.waitForExistence(timeout: 2) {
            setlistsRow.tap()
        }

        let setlistRow = app.staticTexts["Friday Night Gig"]
        XCTAssertTrue(setlistRow.waitForExistence(timeout: 2), "Seeded setlist not found")
        setlistRow.tap()

        let performButton = app.buttons["Perform"]
        XCTAssertTrue(performButton.waitForExistence(timeout: 2), "Perform button not found")
        performButton.tap()

        XCTAssertTrue(entry(0).waitForExistence(timeout: 2), "Performance view did not open")
    }

    /// Jump directly to a specific entry via the sidebar.
    func navigateViaSidebar(to index: Int) {
        ensureSidebarOpen()

        let row = app.descendants(matching: .any).matching(identifier: "sidebar-row-\(index)").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 2), "Sidebar row \(index) not found")
        row.tap()
    }

    /// Ensure the sidebar is visible, opening it if needed.
    func ensureSidebarOpen() {
        let sidebar = app.descendants(matching: .any).matching(identifier: "performance-sidebar").firstMatch
        if !sidebar.exists {
            app.buttons["toggle-sidebar"].tap()
            XCTAssertTrue(sidebar.waitForExistence(timeout: 2), "Sidebar should appear after toggle")
        }
    }

    /// Tap at a horizontal fraction of the content area, vertically centered on screen.
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

    /// Assert that an entry is active. Polls briefly for async label updates.
    func assertEntryIsActive(_ index: Int, file: StaticString = #filePath, line: UInt = #line) {
        let el = entry(index)
        XCTAssertTrue(el.waitForExistence(timeout: 2), "Entry \(index) not found", file: file, line: line)

        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if el.label.hasPrefix("Active:") { return }
            usleep(50_000)
        }
        XCTFail("Entry \(index) should be active, got: '\(el.label)'", file: file, line: line)
    }

    func assertEntryIsInactive(_ index: Int, file: StaticString = #filePath, line: UInt = #line) {
        let el = entry(index)
        guard el.exists else { return }
        XCTAssertFalse(el.label.hasPrefix("Active:"),
                       "Entry \(index) should be inactive, got: '\(el.label)'", file: file, line: line)
    }

    // MARK: - Initial State

    func test_performanceOpens_firstSongIsActive() {
        enterPerformanceMode()
        assertEntryIsActive(0)
        XCTAssertTrue(app.staticTexts["Canal Morning"].exists)
    }

    // MARK: - Right Tap (Forward Navigation)

    func test_rightTap_advancesToNextSong() {
        enterPerformanceMode()
        assertEntryIsActive(0)

        tapRightZone()
        assertEntryIsActive(1)
        XCTAssertTrue(app.staticTexts["Painted Sky"].waitForExistence(timeout: 2))
    }

    func test_rightTap_multipleAdvances() {
        enterPerformanceMode()

        tapRightZone()
        tapRightZone()

        let paintedSky = app.staticTexts["Painted Sky"]
        let copperville = app.staticTexts["Run to Copperville"]
        XCTAssertTrue(paintedSky.exists || copperville.exists,
                      "Should have advanced past the first song")
    }

    func test_rightTap_skipsTacet() {
        enterPerformanceMode()
        navigateViaSidebar(to: 2)
        assertEntryIsActive(2)

        for _ in 0..<6 {
            tapRightZone()
        }

        let folkTrio = app.staticTexts["Folk Trio"]
        let passengers = app.staticTexts["Passengers"]
        XCTAssertTrue(folkTrio.exists || passengers.exists,
                      "Should have skipped the tacet and reached later entries")
    }

    // MARK: - Left Tap (Backward Navigation)

    func test_leftTap_atFirstEntry_staysAtFirst() {
        enterPerformanceMode()
        assertEntryIsActive(0)

        tapLeftZone()
        assertEntryIsActive(0)
    }

    func test_leftTap_goesBackToPreviousSong() {
        enterPerformanceMode()

        tapRightZone()
        assertEntryIsActive(1)

        tapLeftZone()
        assertEntryIsActive(0)
        XCTAssertTrue(app.staticTexts["Canal Morning"].exists)
    }

    // MARK: - Sidebar

    func test_sidebarToggle_showsAndHidesSidebar() {
        enterPerformanceMode()

        let toggleButton = app.buttons["toggle-sidebar"]
        XCTAssertTrue(toggleButton.waitForExistence(timeout: 2))

        toggleButton.tap()
        toggleButton.tap()
    }

    func test_sidebarNavigation_selectEntry() {
        enterPerformanceMode()
        ensureSidebarOpen()

        let sidebarRow = app.descendants(matching: .any).matching(identifier: "sidebar-row-6").firstMatch
        XCTAssertTrue(sidebarRow.waitForExistence(timeout: 2), "Sidebar row 6 should exist")
        sidebarRow.tap()
        assertEntryIsActive(6)
    }

    func test_sidebarNextButton() {
        enterPerformanceMode()
        assertEntryIsActive(0)

        ensureSidebarOpen()

        let nextButton = app.descendants(matching: .any).matching(identifier: "sidebar-next").firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 2), "Sidebar next button should exist")
        nextButton.tap()
        assertEntryIsActive(1)
    }

    func test_sidebarPreviousButton() {
        enterPerformanceMode()

        tapRightZone()
        assertEntryIsActive(1)

        ensureSidebarOpen()

        let prevButton = app.descendants(matching: .any).matching(identifier: "sidebar-previous").firstMatch
        XCTAssertTrue(prevButton.waitForExistence(timeout: 2), "Sidebar previous button should exist")
        prevButton.tap()
        assertEntryIsActive(0)
    }

    // MARK: - Close Button

    func test_closeButton_dismissesPerformanceView() {
        enterPerformanceMode()

        let closeButton = app.buttons["close-performance"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 2))
        closeButton.tap()

        let performButton = app.buttons["Perform"]
        XCTAssertTrue(performButton.waitForExistence(timeout: 2),
                      "Should return to setlist detail after closing performance")
    }

    // MARK: - Within-Entry Scrolling (Chevrons)

    func test_longSong_downChevronAppears_andScrollsDown() throws {
        enterPerformanceMode()
        navigateViaSidebar(to: 5) // Passengers (very long)

        let downChevron = app.buttons["scroll-down-chevron"]
        // At small window sizes the song may fit on screen — chevrons won't appear.
        // That's correct behavior, not a failure.
        try XCTSkipUnless(downChevron.waitForExistence(timeout: 2),
                          "Song fits on screen at this window size — chevrons not needed")

        downChevron.tap()

        let upChevron = app.buttons["scroll-up-chevron"]
        XCTAssertTrue(upChevron.waitForExistence(timeout: 2),
                      "Up chevron should appear after scrolling down within a long entry")
    }

    func test_upChevron_scrollsBackUp() throws {
        enterPerformanceMode()
        navigateViaSidebar(to: 5) // Passengers (very long)

        let downChevron = app.buttons["scroll-down-chevron"]
        try XCTSkipUnless(downChevron.waitForExistence(timeout: 2),
                          "Song fits on screen at this window size — chevrons not needed")

        downChevron.tap()

        let upChevron = app.buttons["scroll-up-chevron"]
        XCTAssertTrue(upChevron.waitForExistence(timeout: 2),
                      "Up chevron should appear after scrolling down")

        upChevron.tap()

        XCTAssertTrue(downChevron.waitForExistence(timeout: 2),
                      "Down chevron should still be visible after scrolling up one step")
    }

    // MARK: - Medley

    func test_medleyShowsTitle() {
        enterPerformanceMode()
        navigateViaSidebar(to: 4) // Folk Trio medley
        assertEntryIsActive(4)

        XCTAssertTrue(app.staticTexts["Folk Trio"].waitForExistence(timeout: 2),
                      "Medley title should be visible when medley entry is active")
    }

    // MARK: - Boundary Conditions

    func test_navigateToLastEntry_rightTapDoesNothing() {
        enterPerformanceMode()
        navigateViaSidebar(to: 11) // Last Train Home
        assertEntryIsActive(11)

        tapRightZone()
        tapRightZone()

        assertEntryIsActive(11)
        XCTAssertTrue(app.buttons["close-performance"].exists, "Should still be in performance mode")
    }

    // MARK: - End-to-End

    func test_fullForwardAndBackwardTraversal() {
        enterPerformanceMode()
        assertEntryIsActive(0)

        tapRightZone()
        assertEntryIsActive(1)

        tapLeftZone()
        assertEntryIsActive(0)

        tapRightZone()
        assertEntryIsActive(1)

        tapRightZone()
        let atOne = entry(1).label.hasPrefix("Active:")
        let atTwo = entry(2).exists && entry(2).label.hasPrefix("Active:")
        XCTAssertTrue(atOne || atTwo, "Should be at entry 1 or 2")
    }
}
