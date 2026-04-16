# Performance Toolbar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the always-visible close and sidebar-toggle buttons in performance mode with an on-demand floating toolbar revealed by a center tap, and add in-performance navigation-mode switching.

**Architecture:** A single new SwiftUI view (`PerformanceToolbar`) rendered as an overlay on the performance content pane. Visibility is driven by a `@State` flag toggled by the existing center-tap zone of `PerformanceTapOverlay`. Mode picker uses native SwiftUI `Menu` bound to the existing `@AppStorage` for `PerformanceNavigationMode`. The toolbar is explicit-show / explicit-hide — no auto-dismiss.

**Tech Stack:** SwiftUI (iOS 26), stock components only — `HStack`, `Button`, `Menu`, `Label`, `.regularMaterial`, `.overlay`.

**Spec:** [`docs/superpowers/specs/2026-04-16-performance-toolbar-design.md`](../specs/2026-04-16-performance-toolbar-design.md)

---

## Reference: Simulator & build

- **Target simulator:** iPad (A16) `B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5`
- **Build:**
  ```bash
  xcodebuild build -scheme Leadify \
    -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
  ```
- **Run UI tests:**
  ```bash
  xcodebuild test -scheme Leadify \
    -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' \
    -only-testing:LeadifyUITests
  ```
- **Do not auto-run simulator tests.** Ask the user before running them; they often test on a real iPad in parallel.
- **Pause for user review after each task** — have them run the sim and confirm before moving to the next task.

---

## File structure

**New:**
- `Leadify/Views/Performance/PerformanceToolbar.swift` — the capsule toolbar view.

**Modified:**
- `Leadify/Views/Performance/PerformanceView.swift` — add toolbar state and overlay, rewire center-tap, remove old buttons.
- `Leadify/Views/Performance/PerformanceTapOverlay.swift` — simplify `onCenterTap` signature (no longer needs Y position).
- `Leadify/Views/Settings/SettingsSheet.swift` — add "Auto-dismiss performance toolbar" toggle row.
- `Leadify/Theme/PerformanceTheme.swift` — add toolbar spacing tokens; remove obsolete `toolButton*` tokens (done in final cleanup task).
- `Tests/UITests/PerformanceUITests.swift` — update close / sidebar lookups to go through the toolbar; add new toolbar-specific tests.
- `Tests/UITests/PerformanceIntegrationTest.swift` — update close / sidebar lookups.

---

## Task 1: Add "Auto-dismiss performance toolbar" setting — **REMOVED mid-execution**

> **Status:** Implemented in commit `7a0ea27`, then reverted after user feedback. Auto-dismiss was dropped entirely because any time-based dismissal would fight every future toolbar feature (metronome, tuner, etc.). The spec now specifies explicit-show / explicit-hide only. If executing this plan fresh, **skip this task** and do not create `PerformanceToolbarSettings.swift`.

---

## Task 1 (original): Add "Auto-dismiss performance toolbar" setting

**Files:**
- Modify: `Leadify/Views/Settings/SettingsSheet.swift`

**Scope:** Add a new `@AppStorage` boolean (default `false`) and render it as a `Toggle` row in a new `Section` below the existing navigation-mode section. This task introduces *only* the setting; nothing consumes it yet.

- [ ] **Step 1: Add the storage key and toggle binding**

Edit `Leadify/Views/Settings/SettingsSheet.swift` — add a new `@AppStorage` below the existing one (around line 5):

```swift
@AppStorage("performance.toolbar.autoDismiss") private var autoDismissToolbar: Bool = false
```

- [ ] **Step 2: Add the toggle section**

After the existing `Section { ... } header: { Text("Performance navigation mode") }` block (ends around line 42), add:

```swift
Section {
    Toggle("Auto-dismiss performance toolbar", isOn: $autoDismissToolbar)
} footer: {
    Text("When on, the toolbar hides itself a few seconds after it was shown.")
}
```

- [ ] **Step 3: Build**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Pause for user review**

Ask user to open the settings sheet and confirm the new toggle row appears and flips correctly. The toggle has no effect yet — that's expected.

- [ ] **Step 5: Commit**

```bash
git add Leadify/Views/Settings/SettingsSheet.swift
git commit -m "feat: add auto-dismiss toggle to settings"
```

---

## Task 2: Create `PerformanceToolbar` view

**Files:**
- Create: `Leadify/Views/Performance/PerformanceToolbar.swift`

**Scope:** A standalone SwiftUI view with a left Exit button, center Mode menu, right Sidebar toggle. It takes closures for Exit and Sidebar-toggle actions, and reads/writes the navigation mode via `@AppStorage`. Self-contained so it can be previewed in isolation.

- [ ] **Step 1: Create the file**

Create `Leadify/Views/Performance/PerformanceToolbar.swift`:

```swift
import SwiftUI

/// On-demand floating capsule shown in the performance view.
/// Exposes Exit (left), Mode picker (center), Sidebar toggle (right).
/// Stock SwiftUI components only — no custom styling beyond a material capsule background.
struct PerformanceToolbar: View {
    let onExit: () -> Void
    let onToggleSidebar: () -> Void

    @AppStorage(PerformanceNavigationMode.storageKey)
    private var storedMode: String = PerformanceNavigationMode.defaultMode.rawValue

    private var currentMode: PerformanceNavigationMode {
        PerformanceNavigationMode(rawValue: storedMode) ?? .defaultMode
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onExit) {
                Label("Done", systemImage: "xmark")
            }
            .accessibilityIdentifier("close-performance")

            Menu {
                ForEach(PerformanceNavigationMode.allCases) { mode in
                    Button {
                        storedMode = mode.rawValue
                    } label: {
                        if mode == currentMode {
                            Label(mode.title, systemImage: "checkmark")
                        } else {
                            Text(mode.title)
                        }
                    }
                }
            } label: {
                Label(currentMode.title, systemImage: "slider.horizontal.3")
            }
            .accessibilityIdentifier("performance-mode-menu")

            Button(action: onToggleSidebar) {
                Label("Sidebar", systemImage: "sidebar.right")
            }
            .accessibilityIdentifier("toggle-sidebar")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .accessibilityIdentifier("performance-toolbar")
    }
}

#Preview("Toolbar") {
    PerformanceToolbar(onExit: {}, onToggleSidebar: {})
        .padding()
        .background(Color.gray)
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Pause for user review**

The toolbar is not yet mounted in `PerformanceView` — nothing visible changes in the app. Ask the user to open the Xcode preview of `PerformanceToolbar.swift` to confirm the layout looks right (and to give feedback on icons / labels). The file builds into the app target automatically.

- [ ] **Step 4: Commit**

```bash
git add Leadify/Views/Performance/PerformanceToolbar.swift
git commit -m "feat: add PerformanceToolbar view"
```

---

## Task 3: Simplify `PerformanceTapOverlay.onCenterTap` signature

**Files:**
- Modify: `Leadify/Views/Performance/PerformanceTapOverlay.swift`
- Modify: `Leadify/Views/Performance/PerformanceView.swift`

**Scope:** The center-tap no longer needs to know the Y position of the tap (it will toggle the toolbar, not activate the entry under the finger). Change the closure type from `((CGFloat) -> Void)?` to `(() -> Void)?`, rewire the call site in `PerformanceView` to call a stub `toggleToolbar()`, and delete the now-dead `activateEntryAt(contentY:)` method (it is only called from the overlay).

- [ ] **Step 1: Change the closure type in the overlay**

Edit `Leadify/Views/Performance/PerformanceTapOverlay.swift`:

Replace (line 14):
```swift
    var onCenterTap: ((CGFloat) -> Void)?
```
with:
```swift
    var onCenterTap: (() -> Void)?
```

Replace (line 60):
```swift
        var onCenterTap: ((CGFloat) -> Void)?
```
with:
```swift
        var onCenterTap: (() -> Void)?
```

Replace the else branch inside `handleTap` (around line 77):
```swift
            } else {
                onCenterTap?(location.y)
            }
```
with:
```swift
            } else {
                onCenterTap?()
            }
```

- [ ] **Step 2: Rewire the call site in `PerformanceView`**

Edit `Leadify/Views/Performance/PerformanceView.swift`.

Replace (around line 142):
```swift
                    onCenterTap: { tapY in activateEntryAt(contentY: tapY) }
```
with:
```swift
                    onCenterTap: { toggleToolbar() }
```

Add a temporary stub so the file still compiles. Just above the `// MARK: - Tap dispatch (per navigation mode)` section (around line 339), add:

```swift
    // MARK: - Toolbar

    private func toggleToolbar() {
        // Full implementation arrives in Task 4.
    }
```

- [ ] **Step 3: Remove the now-dead `activateEntryAt` method**

In `PerformanceView.swift`, delete the whole block (around lines 418–430):

```swift
    // MARK: - Tap-to-activate (center zone)

    /// tapY arrives as absolute content Y from UIScrollView.location(in: scrollView).
    private func activateEntryAt(contentY: CGFloat) {
        for (index, frame) in entryFrames {
            if contentY >= frame.minY && contentY <= frame.maxY {
                if index != activeIndex && !items[index].isSkippable {
                    navigateTo(index: index)
                }
                return
            }
        }
    }
```

- [ ] **Step 4: Build**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Pause for user review**

Ask the user to tap the center of the performance view — it should now do *nothing* (no entry activation, no toolbar — toolbar arrives next task). Left/right taps still navigate.

- [ ] **Step 6: Commit**

```bash
git add Leadify/Views/Performance/PerformanceTapOverlay.swift Leadify/Views/Performance/PerformanceView.swift
git commit -m "refactor: simplify center-tap signature and remove tap-to-activate"
```

---

## Task 4: Mount the toolbar in `PerformanceView`

**Files:**
- Modify: `Leadify/Views/Performance/PerformanceView.swift`

**Scope:** Add `@State` for toolbar visibility, wire up the existing center-tap stub to toggle it, render `PerformanceToolbar` as a top overlay with a show/hide transition, and implement auto-dismiss (gated by the setting from Task 1). The original `closeButton` and `sidebarToggleButton` are kept in place for this task so UI tests still pass.

- [ ] **Step 1: Add toolbar state and auto-dismiss storage**

Edit `Leadify/Views/Performance/PerformanceView.swift`.

Add two new `@State` / `@AppStorage` properties alongside the existing ones (around line 26, after `storedNavMode`):

```swift
    @AppStorage(PerformanceToolbarSettings.autoDismissStorageKey) private var autoDismissToolbar: Bool = PerformanceToolbarSettings.autoDismissDefault
    @State private var showToolbar: Bool = false
    @State private var autoDismissTask: Task<Void, Never>?
```

- [ ] **Step 2: Implement the toggle + auto-dismiss logic**

Replace the stub `toggleToolbar()` added in Task 3 with:

```swift
    // MARK: - Toolbar

    private func toggleToolbar() {
        withAnimation(.easeInOut(duration: PerformanceTheme.navigationAnimationDuration)) {
            showToolbar.toggle()
        }
        if showToolbar {
            scheduleAutoDismiss()
        } else {
            autoDismissTask?.cancel()
        }
    }

    private func scheduleAutoDismiss() {
        autoDismissTask?.cancel()
        guard autoDismissToolbar else { return }
        autoDismissTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: PerformanceTheme.navigationAnimationDuration)) {
                    showToolbar = false
                }
            }
        }
    }
```

- [ ] **Step 3: Render the toolbar overlay**

Replace the line (around line 90):
```swift
        .overlay(alignment: .topTrailing) { sidebarToggleButton }
```
with:
```swift
        .overlay(alignment: .topTrailing) { sidebarToggleButton }
        .overlay(alignment: .top) {
            if showToolbar {
                PerformanceToolbar(
                    onExit: { dismiss() },
                    onToggleSidebar: {
                        withAnimation { showSidebar.toggle() }
                        scheduleAutoDismiss()
                    }
                )
                .padding(.top, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
```

Note: `onToggleSidebar` resets the auto-dismiss timer so interacting with the toolbar keeps it on screen. The mode menu selection goes through `@AppStorage` directly inside `PerformanceToolbar`, so it doesn't need a callback here — but we still want to reset the timer when the user picks a mode. For this task, picking a mode does *not* reset the timer (acceptable — the menu itself is modal and blocks the 4s timer effectively). If this feels wrong on device, revisit.

- [ ] **Step 4: Build**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Pause for user review**

Have the user verify in simulator:
- Single center-tap shows the toolbar (fade + slide down).
- Second center-tap hides it.
- Exit button dismisses performance mode.
- Mode menu shows all three modes with a checkmark on the current one; tapping a mode changes the stored preference (confirm by checking tap behavior).
- Sidebar button toggles the inspector.
- With auto-dismiss OFF (settings), toolbar stays until dismissed.
- With auto-dismiss ON, toolbar disappears ~4s after showing.
- Left/right taps still navigate normally and do not show/hide the toolbar.

The *old* close and sidebar buttons are still visible at the corners — that's expected; they're removed next task.

- [ ] **Step 6: Commit**

```bash
git add Leadify/Views/Performance/PerformanceView.swift
git commit -m "feat: mount performance toolbar with center-tap reveal"
```

---

## Task 5: Remove old close and sidebar buttons

**Files:**
- Modify: `Leadify/Views/Performance/PerformanceView.swift`

**Scope:** Delete `closeButton` and `sidebarToggleButton` definitions and their `.overlay` attachments. After this task, the toolbar is the only way to dismiss / toggle the sidebar. UI tests will still pass because the toolbar buttons reuse the `close-performance` and `toggle-sidebar` accessibility identifiers — but the tests that currently tap those buttons directly will need to first reveal the toolbar. That fix is Task 6.

- [ ] **Step 1: Remove the close-button overlay**

In `PerformanceView.swift`, delete the line (around line 41):

```swift
                .overlay(alignment: .bottomTrailing) { closeButton }
```

- [ ] **Step 2: Remove the sidebar-toggle overlay**

Delete the line (around line 90):

```swift
        .overlay(alignment: .topTrailing) { sidebarToggleButton }
```

- [ ] **Step 3: Remove the button definitions**

Delete the whole block (around lines 462–500):

```swift
    // MARK: - Toolbar buttons

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: PerformanceTheme.toolButtonSize))
                .foregroundStyle(
                    PerformanceTheme.toolButtonGlyphColor,
                    PerformanceTheme.toolButtonFillColor
                )
                .symbolRenderingMode(.palette)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("close-performance")
        .padding(.top, PerformanceTheme.toolButtonTopPadding)
        .padding(.horizontal, PerformanceTheme.toolButtonHorizontalPadding)
    }

    private var sidebarToggleButton: some View {
        Button {
            withAnimation {
                showSidebar.toggle()
            }
        } label: {
            Image(systemName: "list.bullet.circle.fill")
                .font(.system(size: PerformanceTheme.toolButtonSize))
                .foregroundStyle(
                    PerformanceTheme.toolButtonGlyphColor,
                    PerformanceTheme.toolButtonFillColor
                )
                .symbolRenderingMode(.palette)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("toggle-sidebar")
        .padding(.top, PerformanceTheme.toolButtonTopPadding)
        .padding(.horizontal, PerformanceTheme.toolButtonHorizontalPadding)
    }
```

- [ ] **Step 4: Build**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Pause for user review**

Sim check: the corner buttons are gone. Only way to exit / toggle sidebar is via center-tap → toolbar → button. The left/right tap zones still navigate.

- [ ] **Step 6: Commit**

```bash
git add Leadify/Views/Performance/PerformanceView.swift
git commit -m "refactor: remove corner close and sidebar-toggle buttons"
```

---

## Task 6: Update existing UI tests to reveal toolbar before tapping buttons

**Files:**
- Modify: `Tests/UITests/PerformanceUITests.swift`
- Modify: `Tests/UITests/PerformanceIntegrationTest.swift`

**Scope:** Every existing test that taps `close-performance` or `toggle-sidebar` must first tap the center of the content area to reveal the toolbar. Introduce a shared helper `revealToolbar()` on each test class. Element queries using the identifiers `close-performance` and `toggle-sidebar` continue to work because the toolbar buttons expose the same identifiers.

- [ ] **Step 1: Add the `revealToolbar()` helper in `PerformanceUITests.swift`**

Edit `Tests/UITests/PerformanceUITests.swift`. Just after the existing `func tapCenterZone()` line (around line 98), add:

```swift
    /// Reveal the performance toolbar by center-tapping if not already visible.
    func revealToolbar() {
        let toolbar = app.descendants(matching: .any).matching(identifier: "performance-toolbar").firstMatch
        if !toolbar.exists {
            tapCenterZone()
            XCTAssertTrue(toolbar.waitForExistence(timeout: 2), "Toolbar should appear after center tap")
        }
    }
```

- [ ] **Step 2: Update `ensureSidebarOpen()` to reveal the toolbar first**

Replace the `ensureSidebarOpen()` body (around lines 78–84) with:

```swift
    /// Ensure the sidebar is visible, opening it if needed.
    func ensureSidebarOpen() {
        let sidebar = app.descendants(matching: .any).matching(identifier: "performance-sidebar").firstMatch
        if !sidebar.exists {
            revealToolbar()
            app.buttons["toggle-sidebar"].tap()
            XCTAssertTrue(sidebar.waitForExistence(timeout: 2), "Sidebar should appear after toggle")
        }
    }
```

- [ ] **Step 3: Update `test_sidebarToggle_showsAndHidesSidebar`**

Replace the body (around lines 189–197) with:

```swift
    func test_sidebarToggle_showsAndHidesSidebar() {
        enterPerformanceMode()

        revealToolbar()
        let toggleButton = app.buttons["toggle-sidebar"]
        XCTAssertTrue(toggleButton.waitForExistence(timeout: 2))

        toggleButton.tap()
        revealToolbar()
        toggleButton.tap()
    }
```

- [ ] **Step 4: Update `test_closeButton_dismissesPerformanceView`**

Replace the body (around lines 237–247) with:

```swift
    func test_closeButton_dismissesPerformanceView() {
        enterPerformanceMode()

        revealToolbar()
        let closeButton = app.buttons["close-performance"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 2))
        closeButton.tap()

        let performButton = app.buttons["Perform"]
        XCTAssertTrue(performButton.waitForExistence(timeout: 2),
                      "Should return to setlist detail after closing performance")
    }
```

- [ ] **Step 5: Update the boundary test's close-button assertion**

Replace the last two lines of `test_navigateToLastEntry_rightTapDoesNothing` (around lines 309–311) with:

```swift
        assertEntryIsActive(11)
        revealToolbar()
        XCTAssertTrue(app.buttons["close-performance"].exists, "Should still be in performance mode")
```

- [ ] **Step 6: Update `PerformanceIntegrationTest.swift` — add `revealToolbar()` helper**

Edit `Tests/UITests/PerformanceIntegrationTest.swift`. After `func tapLeftZone()` (around line 36), add:

```swift
    func tapCenterZone() { tapContentArea(atHorizontalFraction: 0.5) }

    func revealToolbar() {
        let toolbar = app.descendants(matching: .any).matching(identifier: "performance-toolbar").firstMatch
        if !toolbar.exists {
            tapCenterZone()
            XCTAssertTrue(toolbar.waitForExistence(timeout: 2), "Toolbar should appear after center tap")
        }
    }
```

- [ ] **Step 7: Update `PerformanceIntegrationTest.ensureSidebarOpen()`**

Replace the body (around lines 49–55) with:

```swift
    func ensureSidebarOpen() {
        let sidebar = app.descendants(matching: .any).matching(identifier: "performance-sidebar").firstMatch
        if !sidebar.exists {
            revealToolbar()
            app.buttons["toggle-sidebar"].tap()
            XCTAssertTrue(sidebar.waitForExistence(timeout: 2), "Sidebar should appear after toggle")
        }
    }
```

- [ ] **Step 8: Update the close-performance taps in the integration test**

`PerformanceIntegrationTest.swift` taps `close-performance` in two places and `toggle-sidebar` once.

Replace line 146 (`app.buttons["close-performance"].tap()`) with:
```swift
        revealToolbar()
        app.buttons["close-performance"].tap()
```

Replace the `toggleButton.tap(); toggleButton.tap()` block at lines 160–162 with:
```swift
        revealToolbar()
        let toggleButton = app.buttons["toggle-sidebar"]
        toggleButton.tap()
        revealToolbar()
        toggleButton.tap()
```

Replace line 169 (`app.buttons["close-performance"].tap()`) with:
```swift
        revealToolbar()
        app.buttons["close-performance"].tap()
```

- [ ] **Step 9: Build**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 10: Pause for user approval to run UI tests**

Ask: "Shall I run the UI tests now, or will you run them on device?" If user says yes:

```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' \
  -only-testing:LeadifyUITests
```

Expected: all existing tests pass.

- [ ] **Step 11: Commit**

```bash
git add Tests/UITests/PerformanceUITests.swift Tests/UITests/PerformanceIntegrationTest.swift
git commit -m "test: route existing toolbar lookups through the new center-tap reveal"
```

---

## Task 7: Add new UI tests for toolbar behaviors

**Files:**
- Modify: `Tests/UITests/PerformanceUITests.swift`

**Scope:** Cover the behaviors that are new in this feature: center-tap shows the toolbar, center-tap again hides it, left/right taps do not affect toolbar visibility, mode menu changes the stored mode.

- [ ] **Step 1: Add the new tests to `PerformanceUITests.swift`**

Append the following tests at the bottom of the class in `Tests/UITests/PerformanceUITests.swift` (before the closing brace):

```swift
    // MARK: - Toolbar

    func test_centerTap_showsAndHidesToolbar() {
        enterPerformanceMode()
        let toolbar = app.descendants(matching: .any).matching(identifier: "performance-toolbar").firstMatch

        XCTAssertFalse(toolbar.exists, "Toolbar should be hidden initially")

        tapCenterZone()
        XCTAssertTrue(toolbar.waitForExistence(timeout: 2), "Toolbar should appear after first center tap")

        tapCenterZone()
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if !toolbar.exists { return }
            usleep(50_000)
        }
        XCTFail("Toolbar should have disappeared after second center tap")
    }

    func test_leftRightTaps_doNotAffectToolbarVisibility() {
        enterPerformanceMode()
        let toolbar = app.descendants(matching: .any).matching(identifier: "performance-toolbar").firstMatch

        tapRightZone()
        XCTAssertFalse(toolbar.exists, "Right tap should not show toolbar")

        tapLeftZone()
        XCTAssertFalse(toolbar.exists, "Left tap should not show toolbar")

        revealToolbar()
        XCTAssertTrue(toolbar.exists)

        tapRightZone()
        XCTAssertTrue(toolbar.exists, "Right tap should not hide toolbar")
    }

    func test_modeMenu_changesNavigationMode() {
        enterPerformanceMode()
        revealToolbar()

        let menu = app.buttons["performance-mode-menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 2))
        menu.tap()

        let simpleItem = app.buttons["Simple"]
        XCTAssertTrue(simpleItem.waitForExistence(timeout: 2), "Menu should show 'Simple' option")
        simpleItem.tap()

        let updatedMenu = app.buttons["performance-mode-menu"]
        XCTAssertTrue(updatedMenu.waitForExistence(timeout: 2))
        XCTAssertTrue(updatedMenu.label.contains("Simple"), "Mode menu label should show new mode, got: '\(updatedMenu.label)'")
    }
```

- [ ] **Step 3: Build**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Ask user before running UI tests**

Prompt: "The new tests are ready — run them on simulator, or will you run them yourself?"

If user says yes:
```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' \
  -only-testing:LeadifyUITests/PerformanceUITests
```

Expected: all three new tests pass.

- [ ] **Step 5: Commit**

```bash
git add Tests/UITests/PerformanceUITests.swift
git commit -m "test: cover toolbar reveal and mode switch"
```

---

## Task 8: Clean up obsolete theme tokens

**Files:**
- Modify: `Leadify/Theme/PerformanceTheme.swift`

**Scope:** The `toolButton*` tokens were used only by the removed `closeButton` and `sidebarToggleButton`. Remove them. Before deleting, grep the project to confirm no other consumers remain.

- [ ] **Step 1: Verify no consumers remain**

Use the Grep tool with pattern `toolButtonSize|toolButtonTopPadding|toolButtonHorizontalPadding|toolButtonGlyphColor|toolButtonFillColor` across `Leadify/`. Expected: matches only inside `PerformanceTheme.swift` itself. If anything else matches, stop and report.

- [ ] **Step 2: Remove the tokens**

Edit `Leadify/Theme/PerformanceTheme.swift`. Delete the block (lines 67–70):

```swift
    // MARK: - Tool buttons (close, sidebar toggle)
    static let toolButtonSize: CGFloat = 28
    static let toolButtonTopPadding: CGFloat = 12
    static let toolButtonHorizontalPadding: CGFloat = 16
```

Delete the two `toolButton*` color tokens (lines 112–113):

```swift
    static let toolButtonGlyphColor = Color(light: Color(white: 0.45), dark: Color(white: 0.8))
    static let toolButtonFillColor = Color(light: Color(white: 0.82), dark: Color(white: 0.25))
```

- [ ] **Step 3: Build**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add Leadify/Theme/PerformanceTheme.swift
git commit -m "chore: drop obsolete toolButton theme tokens"
```

---

## Self-review notes

Spec sections → task coverage:

| Spec section | Covered by |
|---|---|
| Reveal & dismiss via center-tap | Tasks 3, 4 |
| Floating toolbar, native SwiftUI (Liquid Glass) | Task 2 |
| Toolbar contents (Exit / Mode / Sidebar) | Task 2 |
| Mode menu driven by `@AppStorage` | Task 2 |
| Removal of old corner buttons | Task 5 |
| UI test updates | Tasks 6, 7 |
| Theme cleanup | Task 8 |

**Deferred (by design):**
- Custom accessibility actions on the content area (so VoiceOver users can reach the toolbar actions without the gesture). Called out in the spec's "Accessibility" section but not strictly required for the first landing. If this is required before merging, add a follow-up task.
- Icon choice for the mode menu label (currently `slider.horizontal.3`) — user to review on device, tweak later.

**Not implemented:**
- Nothing in the spec is unaddressed.

---
