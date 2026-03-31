# Performance View Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current viewport-based tap scrolling in PerformanceView with ForScore-style active-entry navigation, entry dimming, and an adaptive setlist sidebar in wide mode.

**Architecture:** A single `ScrollView` with entry frame tracking via `onGeometryChange`. A `UIViewRepresentable` tap gesture layer that coexists with native scroll. An `@State activeEntryIndex` drives opacity dimming and scroll-to-anchor behavior. An adaptive layout switches between single-column (narrow) and content+sidebar (wide) at 950pt width.

**Tech Stack:** SwiftUI, UIKit (`UITapGestureRecognizer` via `UIViewRepresentable`), SwiftData (read-only)

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `Leadify/Views/Performance/PerformanceView.swift` | Rewrite | Active entry state, adaptive layout, scroll content, close button |
| `Leadify/Views/Performance/PerformanceTapOverlay.swift` | Create | `UIViewRepresentable` that adds left/right tap gesture recognizers over the scroll view |
| `Leadify/Views/Performance/PerformanceSetlistSidebar.swift` | Create | Wide-mode sidebar: compact title list with active-entry highlight and tap-to-jump |
| `Leadify/Views/Performance/SongPerformanceBlock.swift` | No change | Already correct |
| `Leadify/Views/Performance/TacetPerformanceBlock.swift` | No change | Already correct |
| `Leadify/Theme/PerformanceTheme.swift` | Minor edit | Add sidebar-related tokens |
| `LeadifyTests/PerformanceNavigationTests.swift` | Create | Unit tests for the two-phase navigation logic |

---

### Task 1: Extract navigation logic into a testable helper

The two-phase tap logic is pure computation: given the active entry's frame, the viewport rect, and a tap direction, determine the scroll target and whether to advance the active index. Extract this into a standalone struct so we can unit test it without views.

**Files:**
- Create: `Leadify/Views/Performance/PerformanceNavigator.swift`
- Create: `LeadifyTests/PerformanceNavigationTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `LeadifyTests/PerformanceNavigationTests.swift`:

```swift
import XCTest
@testable import Leadify

final class PerformanceNavigationTests: XCTestCase {
    // MARK: - Right tap (forward)

    func test_rightTap_activeEntryExtendsBelow_scrollsWithinEntry() {
        // Active entry bottom (800) is below viewport bottom (600)
        let result = PerformanceNavigator.handleTap(
            direction: .forward,
            activeIndex: 0,
            entryCount: 3,
            activeEntryFrame: CGRect(x: 0, y: 0, width: 700, height: 800),
            viewportHeight: 600,
            scrollOffset: 0
        )
        // Should scroll down ~60% of viewport (360pt), not advance
        XCTAssertEqual(result.newActiveIndex, 0)
        XCTAssertEqual(result.scrollTarget, 360, accuracy: 1)
    }

    func test_rightTap_activeEntryFullyVisible_advancesToNext() {
        // Active entry bottom (400) is above viewport bottom (600)
        let result = PerformanceNavigator.handleTap(
            direction: .forward,
            activeIndex: 0,
            entryCount: 3,
            activeEntryFrame: CGRect(x: 0, y: 0, width: 700, height: 400),
            viewportHeight: 600,
            scrollOffset: 0
        )
        XCTAssertEqual(result.newActiveIndex, 1)
        // scrollTarget is nil — caller will scroll to the new entry's anchor
        XCTAssertNil(result.scrollTarget)
    }

    func test_rightTap_lastEntry_bottomVisible_doesNothing() {
        let result = PerformanceNavigator.handleTap(
            direction: .forward,
            activeIndex: 2,
            entryCount: 3,
            activeEntryFrame: CGRect(x: 0, y: 0, width: 700, height: 400),
            viewportHeight: 600,
            scrollOffset: 0
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
            viewportHeight: 600,
            scrollOffset: 0
        )
        XCTAssertEqual(result.newActiveIndex, 2)
        XCTAssertEqual(result.scrollTarget, 360, accuracy: 1)
    }

    // MARK: - Left tap (backward)

    func test_leftTap_activeEntryExtendsAbove_scrollsWithinEntry() {
        // We've scrolled 300pt into the entry, top is above viewport
        let result = PerformanceNavigator.handleTap(
            direction: .backward,
            activeIndex: 1,
            entryCount: 3,
            activeEntryFrame: CGRect(x: 0, y: -200, width: 700, height: 800),
            viewportHeight: 600,
            scrollOffset: 500
        )
        XCTAssertEqual(result.newActiveIndex, 1)
        // Should scroll up ~60% of viewport (360pt)
        XCTAssertEqual(result.scrollTarget, 140, accuracy: 1)
    }

    func test_leftTap_activeEntryTopVisible_goesToPrevious() {
        // Active entry top (20) is within viewport (0..600)
        let result = PerformanceNavigator.handleTap(
            direction: .backward,
            activeIndex: 1,
            entryCount: 3,
            activeEntryFrame: CGRect(x: 0, y: 20, width: 700, height: 400),
            viewportHeight: 600,
            scrollOffset: 100
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
            viewportHeight: 600,
            scrollOffset: 0
        )
        XCTAssertEqual(result.newActiveIndex, 0)
        XCTAssertNil(result.scrollTarget)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme Leadify -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' -only-testing:LeadifyTests/PerformanceNavigationTests 2>&1 | tail -20`

Expected: Compilation error — `PerformanceNavigator` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `Leadify/Views/Performance/PerformanceNavigator.swift`:

```swift
import Foundation

enum TapDirection {
    case forward
    case backward
}

struct NavigationResult {
    let newActiveIndex: Int
    /// If non-nil, scroll to this absolute Y offset. If nil, scroll to the new active entry's anchor.
    let scrollTarget: CGFloat?
}

/// Pure-logic helper for the two-phase ForScore-style tap navigation.
/// All frames are in the scroll view's coordinate space relative to the viewport.
enum PerformanceNavigator {
    private static let scrollFraction: CGFloat = 0.6

    static func handleTap(
        direction: TapDirection,
        activeIndex: Int,
        entryCount: Int,
        activeEntryFrame: CGRect,
        viewportHeight: CGFloat,
        scrollOffset: CGFloat
    ) -> NavigationResult {
        switch direction {
        case .forward:
            return handleForward(
                activeIndex: activeIndex,
                entryCount: entryCount,
                activeEntryFrame: activeEntryFrame,
                viewportHeight: viewportHeight,
                scrollOffset: scrollOffset
            )
        case .backward:
            return handleBackward(
                activeIndex: activeIndex,
                activeEntryFrame: activeEntryFrame,
                viewportHeight: viewportHeight,
                scrollOffset: scrollOffset
            )
        }
    }

    private static func handleForward(
        activeIndex: Int,
        entryCount: Int,
        activeEntryFrame: CGRect,
        viewportHeight: CGFloat,
        scrollOffset: CGFloat
    ) -> NavigationResult {
        let entryBottom = activeEntryFrame.maxY
        let viewportBottom = viewportHeight

        // Phase 1: entry extends below viewport — scroll within
        if entryBottom > viewportBottom + 1 {
            let target = scrollOffset + viewportHeight * scrollFraction
            return NavigationResult(newActiveIndex: activeIndex, scrollTarget: target)
        }

        // Phase 2: entry bottom visible — advance to next (if not last)
        if activeIndex < entryCount - 1 {
            return NavigationResult(newActiveIndex: activeIndex + 1, scrollTarget: nil)
        }

        // Already at last entry and fully visible — do nothing
        return NavigationResult(newActiveIndex: activeIndex, scrollTarget: nil)
    }

    private static func handleBackward(
        activeIndex: Int,
        activeEntryFrame: CGRect,
        viewportHeight: CGFloat,
        scrollOffset: CGFloat
    ) -> NavigationResult {
        let entryTop = activeEntryFrame.minY

        // Phase 1: entry extends above viewport — scroll within
        if entryTop < -1 {
            let target = max(0, scrollOffset - viewportHeight * scrollFraction)
            return NavigationResult(newActiveIndex: activeIndex, scrollTarget: target)
        }

        // Phase 2: entry top visible — go to previous (if not first)
        if activeIndex > 0 {
            return NavigationResult(newActiveIndex: activeIndex - 1, scrollTarget: nil)
        }

        // Already at first entry and top visible — do nothing
        return NavigationResult(newActiveIndex: activeIndex, scrollTarget: nil)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme Leadify -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' -only-testing:LeadifyTests/PerformanceNavigationTests 2>&1 | tail -20`

Expected: All 7 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Leadify/Views/Performance/PerformanceNavigator.swift LeadifyTests/PerformanceNavigationTests.swift
git commit -m "feat(performance): add PerformanceNavigator with two-phase tap logic and tests"
```

---

### Task 2: Create the UIKit tap overlay

A `UIViewRepresentable` that places a transparent `UIView` with two `UITapGestureRecognizer`s. Taps in the left 40% call `onLeftTap()`, taps in the right 40% call `onRightTap()`, taps in the center 20% are ignored. The overlay does not interfere with scroll gestures.

**Files:**
- Create: `Leadify/Views/Performance/PerformanceTapOverlay.swift`

- [ ] **Step 1: Create the tap overlay**

Create `Leadify/Views/Performance/PerformanceTapOverlay.swift`:

```swift
import SwiftUI
import UIKit

/// A transparent overlay that detects taps in left/right zones without blocking scroll gestures.
/// Uses UIKit gesture recognizers so taps and ScrollView panning coexist naturally.
struct PerformanceTapOverlay: UIViewRepresentable {
    var onLeftTap: () -> Void
    var onRightTap: () -> Void

    func makeUIView(context: Context) -> TapOverlayView {
        let view = TapOverlayView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        view.onLeftTap = onLeftTap
        view.onRightTap = onRightTap

        let tap = UITapGestureRecognizer(target: view, action: #selector(TapOverlayView.handleTap(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        return view
    }

    func updateUIView(_ uiView: TapOverlayView, context: Context) {
        uiView.onLeftTap = onLeftTap
        uiView.onRightTap = onRightTap
    }
}

class TapOverlayView: UIView {
    var onLeftTap: (() -> Void)?
    var onRightTap: (() -> Void)?

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let width = bounds.width
        let leftZoneEnd = width * 0.4
        let rightZoneStart = width * 0.6

        if location.x < leftZoneEnd {
            onLeftTap?()
        } else if location.x > rightZoneStart {
            onRightTap?()
        }
        // Center 20% — ignored (pure scroll zone)
    }
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `xcodebuild build -scheme Leadify -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Leadify/Views/Performance/PerformanceTapOverlay.swift
git commit -m "feat(performance): add UIKit-based tap overlay for scroll-friendly zone taps"
```

---

### Task 3: Add sidebar theme tokens

Add the minimal theme tokens needed for the wide-mode sidebar.

**Files:**
- Modify: `Leadify/Theme/PerformanceTheme.swift`

- [ ] **Step 1: Add sidebar tokens to PerformanceTheme**

Add after the existing `medleyIndicatorColor` line in `PerformanceTheme.swift`:

```swift
    // Sidebar (wide mode)
    static let sidebarBackground = Color(light: Color(white: 0.94), dark: Color(white: 0.08))
    static let sidebarActiveColor = EditTheme.accentColor
    static let sidebarTextColor = Color(light: Color(white: 0.3), dark: Color(white: 0.7))
```

This requires an import — check if `EditTheme` is accessible. It is (same module). The `sidebarActiveColor` reuses the app's accent for consistency.

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -scheme Leadify -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Leadify/Theme/PerformanceTheme.swift
git commit -m "feat(performance): add sidebar theme tokens to PerformanceTheme"
```

---

### Task 4: Create the setlist sidebar for wide mode

A compact vertical list of all setlist entry titles. The active entry is highlighted. Tapping a title calls an `onSelect(index)` callback.

**Files:**
- Create: `Leadify/Views/Performance/PerformanceSetlistSidebar.swift`

- [ ] **Step 1: Create the sidebar view**

Create `Leadify/Views/Performance/PerformanceSetlistSidebar.swift`:

```swift
import SwiftUI

/// Compact setlist overview for wide-mode performance. Shows entry titles with active highlight.
struct PerformanceSetlistSidebar: View {
    let entries: [SetlistEntry]
    let activeIndex: Int
    var onSelect: (Int) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.persistentModelID) { index, entry in
                        sidebarRow(index: index, entry: entry)
                            .id(index)
                    }
                }
                .padding(.vertical, 16)
            }
            .onChange(of: activeIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PerformanceTheme.sidebarBackground)
    }

    @ViewBuilder
    private func sidebarRow(index: Int, entry: SetlistEntry) -> some View {
        let isActive = index == activeIndex

        Button {
            onSelect(index)
        } label: {
            HStack(spacing: 8) {
                // Active indicator bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(isActive ? PerformanceTheme.sidebarActiveColor : .clear)
                    .frame(width: 3)

                Text(entryTitle(entry))
                    .font(.system(size: 15, weight: isActive ? .bold : .regular))
                    .foregroundStyle(isActive ? PerformanceTheme.sidebarActiveColor : PerformanceTheme.sidebarTextColor)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func entryTitle(_ entry: SetlistEntry) -> String {
        switch entry.itemType {
        case .song:
            return entry.song?.title ?? "Untitled"
        case .tacet:
            if let label = entry.tacet?.label, !label.isEmpty {
                return label
            }
            return "Tacet"
        case .medley:
            return entry.medley?.name ?? "Medley"
        }
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -scheme Leadify -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Leadify/Views/Performance/PerformanceSetlistSidebar.swift
git commit -m "feat(performance): add PerformanceSetlistSidebar for wide-mode overview"
```

---

### Task 5: Rewrite PerformanceView with active entry navigation

Replace the current PerformanceView entirely. Wire up: active entry state, entry frame tracking, tap overlay, dimming, adaptive layout with sidebar, and scroll-to-anchor on navigation.

**Files:**
- Rewrite: `Leadify/Views/Performance/PerformanceView.swift`

- [ ] **Step 1: Rewrite PerformanceView**

Replace the entire contents of `Leadify/Views/Performance/PerformanceView.swift` with:

```swift
import SwiftUI

/// Preference key to collect entry frames (in the scroll content's coordinate space).
private struct EntryFrameKey: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct PerformanceView: View {
    let setlist: Setlist
    @Environment(\.dismiss) private var dismiss

    @State private var activeIndex: Int = 0
    @State private var scrollPosition = ScrollPosition()
    @State private var scrollOffset: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0
    @State private var entryFrames: [Int: CGRect] = [:]

    private var entries: [SetlistEntry] { setlist.sortedEntries }
    private static let wideSidebarThreshold: CGFloat = 950

    var body: some View {
        GeometryReader { geo in
            let isWide = geo.size.width >= Self.wideSidebarThreshold

            HStack(spacing: 0) {
                // Main scroll content
                scrollContent(viewportSize: geo.size)

                // Sidebar in wide mode
                if isWide {
                    Divider()
                    PerformanceSetlistSidebar(
                        entries: entries,
                        activeIndex: activeIndex
                    ) { index in
                        navigateTo(index: index)
                    }
                    .frame(width: geo.size.width * 0.25)
                }
            }
            .onAppear { viewportHeight = geo.size.height }
            .onChange(of: geo.size.height) { _, h in viewportHeight = h }
        }
        .background(PerformanceTheme.background.ignoresSafeArea())
        .overlay(alignment: .topTrailing) { closeButton }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    // MARK: - Scroll content

    @ViewBuilder
    private func scrollContent(viewportSize: CGSize) -> some View {
        ZStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.persistentModelID) { index, entry in
                        entryView(entry: entry, index: index)
                            .padding(.horizontal, 32)
                            .opacity(opacityFor(index: index))
                            .animation(.easeInOut(duration: 0.3), value: activeIndex)
                            .background(
                                GeometryReader { entryGeo in
                                    Color.clear.preference(
                                        key: EntryFrameKey.self,
                                        value: [index: entryGeo.frame(in: .named("perfScroll"))]
                                    )
                                }
                            )
                            .id(index)
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 80)
            }
            .coordinateSpace(name: "perfScroll")
            .scrollPosition($scrollPosition)
            .onPreferenceChange(EntryFrameKey.self) { entryFrames = $0 }
            .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentOffset.y }) { _, y in
                scrollOffset = y
            }

            // Tap overlay — UIKit-based, does not block scroll
            PerformanceTapOverlay(
                onLeftTap: { handleTap(direction: .backward) },
                onRightTap: { handleTap(direction: .forward) }
            )
        }
    }

    // MARK: - Entry rendering

    @ViewBuilder
    private func entryView(entry: SetlistEntry, index: Int) -> some View {
        switch entry.itemType {
        case .song:
            SongPerformanceBlock(song: entry.song!)
        case .tacet:
            TacetPerformanceBlock(tacet: entry.tacet!)
        case .medley:
            if let medley = entry.medley {
                MedleyPerformanceBlock(medley: medley)
            }
        }
    }

    // MARK: - Dimming

    private func opacityFor(index: Int) -> Double {
        if index == activeIndex { return 1.0 }
        if index < activeIndex { return 0.3 }
        return 0.4 // upcoming
    }

    // MARK: - Navigation

    private func handleTap(direction: TapDirection) {
        // Get the active entry's frame relative to the viewport
        guard let frameInScroll = entryFrames[activeIndex] else { return }

        // Convert from scroll-content space to viewport space:
        // In scroll-content space, the frame's Y is relative to the content top.
        // The viewport sees content starting at scrollOffset.
        let viewportRelativeFrame = CGRect(
            x: frameInScroll.minX,
            y: frameInScroll.minY - scrollOffset,
            width: frameInScroll.width,
            height: frameInScroll.height
        )

        let result = PerformanceNavigator.handleTap(
            direction: direction,
            activeIndex: activeIndex,
            entryCount: entries.count,
            activeEntryFrame: viewportRelativeFrame,
            viewportHeight: viewportHeight,
            scrollOffset: scrollOffset
        )

        if let target = result.scrollTarget {
            // Scroll within current entry
            withAnimation(.easeInOut(duration: 0.25)) {
                scrollPosition.scrollTo(y: target)
            }
        } else if result.newActiveIndex != activeIndex {
            // Navigate to new entry — scroll to its anchor
            navigateTo(index: result.newActiveIndex)
        }

        activeIndex = result.newActiveIndex
    }

    private func navigateTo(index: Int) {
        activeIndex = index
        withAnimation(.easeInOut(duration: 0.25)) {
            scrollPosition.scrollTo(id: index, anchor: .top)
        }
    }

    // MARK: - Close button

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `xcodebuild build -scheme Leadify -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' 2>&1 | tail -10`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Run all tests to verify nothing is broken**

Run: `xcodebuild test -scheme Leadify -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' 2>&1 | tail -20`

Expected: All tests pass (existing + new PerformanceNavigationTests).

- [ ] **Step 4: Commit**

```bash
git add Leadify/Views/Performance/PerformanceView.swift
git commit -m "feat(performance): rewrite PerformanceView with active entry navigation and adaptive layout"
```

---

### Task 6: Build, run on simulator, and review

Build the app and install on the iPad simulator to verify the full experience before calling it done.

**Files:** None (verification only)

- [ ] **Step 1: Build the app**

Run: `xcodebuild build -scheme Leadify -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 2: Install and launch on simulator**

```bash
xcrun simctl terminate B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5 bartvanraaij.Leadify 2>/dev/null
xcrun simctl install B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5 \
  ~/Library/Developer/Xcode/DerivedData/Leadify-dcfskxmsfskcybdoxvrgstsbknvm/Build/Products/Debug-iphonesimulator/Leadify.app
xcrun simctl launch B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5 bartvanraaij.Leadify
```

- [ ] **Step 3: Manual verification checklist**

Verify in the simulator:
- Open a setlist with multiple songs, tacets, and a medley
- Enter performance mode
- **Tap right zone**: first song scrolls if taller than viewport, then advances to next entry
- **Tap left zone**: reverses — scrolls up within entry, then goes to previous
- **Native scroll**: drag-scrolling works smoothly, does not change active entry
- **Dimming**: active entry is bright, upcoming entries dimmed, past entries more dimmed
- **Center zone**: tapping center 20% does nothing (scroll only)
- **End of set**: tapping right on last entry with bottom visible does nothing
- **Resize to full-screen**: sidebar appears with all titles and active marker
- **Sidebar tap**: tapping a title jumps to that entry
- **Resize back to split**: sidebar disappears, scroll position preserved

- [ ] **Step 4: Pause for user review in simulator**

Wait for user feedback before proceeding.
