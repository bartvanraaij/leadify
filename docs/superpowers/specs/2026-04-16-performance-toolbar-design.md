# Performance Toolbar — Design Spec

**Date:** 2026-04-16
**Status:** Approved for planning

## Background

The current performance view has two persistent controls pinned to the screen edges:

- A close button (`xmark.circle.fill`) at the bottom-trailing corner.
- A sidebar-toggle button (`list.bullet.circle.fill`) at the top-trailing corner.

Both are always visible while performing and are visually distracting. Switching the performance navigation mode currently requires leaving performance mode to open the app's settings sheet.

## Goals

- Hide chrome by default while performing.
- Surface the same actions (plus navigation-mode switching) on demand via a single gesture.
- Use stock SwiftUI components and system styling; no custom drawing or bespoke chrome.

## Non-goals

- No changes to the existing left/right navigation tap zones or the up/down chevron scrolling.
- No changes to the sidebar itself (`PerformanceSetlistSidebar`).
- No changes to the three navigation modes' behavior.

## User-facing behavior

### Reveal & dismiss

- A single tap in the existing **center tap zone** shows the toolbar.
- Another single tap in the center zone hides it.
- Taps in the left or right tap zones continue to drive navigation and do not affect toolbar visibility.
- **No auto-dismiss.** The user explicitly controls visibility. Auto-dismiss was considered and rejected: any time-based dismissal forces every future toolbar feature (metronome, annotations, tuner, etc.) to dance around pause/resume logic. The toolbar is ephemeral-by-invocation, not ephemeral-by-timer.

### Removed capability

The current center-tap behavior ("activate the entry whose content was tapped") is removed. The sidebar remains the way to jump to an arbitrary entry. This is an accepted trade-off — the shortcut was rarely used.

## Visual design

A single floating capsule, horizontally centered near the top of the viewport, respecting the top safe-area inset.

Implementation uses only stock SwiftUI:

- An `HStack` of `Button` / `Menu` views using `Label(_, systemImage:)` for icon + text.
- Container styling: `.background(.regularMaterial, in: Capsule())` with standard padding. No custom colors, no custom `buttonStyle`. Tint inherits from the system.
- Show/hide transition: `.transition(.opacity.combined(with: .move(edge: .top)))`.
- Anchored via `.overlay(alignment: .top)` on the performance root.

The toolbar sits above content and below the sidebar inspector. It does not shift scroll content.

## Toolbar contents

Left → right:

1. **Exit** — `Button` with `Label("Done", systemImage: "xmark")`. Dismisses the performance view (same action as the removed close button).
2. **Mode menu** — `Menu` whose label is `Label(currentModeName, systemImage: <mode-icon>)`. Menu items: one `Button` per navigation mode (Simple, Song, Smart). Selecting a mode updates the stored preference (`PerformanceNavigationMode.storageKey`) immediately; the toolbar's label updates reactively. SwiftUI handles the popover, tap-outside-to-dismiss, and checkmark affordance.
3. **Sidebar toggle** — `Button` with `Label("Sidebar", systemImage: "sidebar.right")`. Toggles the inspector (same action as the removed sidebar button).

The ordering places the sidebar toggle on the right to match the sidebar's right-hand position; the exit lives on the left as a standard "back out" affordance.

There is no explicit close-the-toolbar button; the center-tap toggle and (optional) auto-dismiss cover that.

## Settings-sheet change

None. No new settings are introduced by this feature.

## Removed code

- `closeButton` in `PerformanceView.swift` and its `.overlay(alignment: .bottomTrailing)` attachment.
- `sidebarToggleButton` in `PerformanceView.swift` and its `.overlay(alignment: .topTrailing)` attachment.
- The `onCenterTap: activateEntryAt(contentY:)` path in `PerformanceTapOverlay` callers. The overlay's center-tap closure is repurposed to toggle the toolbar.

## Accessibility

- Toolbar container has `accessibilityIdentifier("performance-toolbar")`.
- Each button keeps a stable identifier: `close-performance`, `toggle-sidebar`, `performance-mode-menu` (plus one identifier per mode item).
- Because the toolbar is hidden by default, the same three actions are also exposed as **custom accessibility actions** on the performance content area so VoiceOver users can reach them without needing to discover the center-tap gesture.
- The toolbar itself is announced when shown.

## Testing impact

Existing UI tests that tap `close-performance` or `toggle-sidebar` directly will break. They must be updated to:

1. Tap the center of `performance-content-area` to reveal the toolbar.
2. Then tap the intended toolbar button.

A new UI test covers:

- Center-tap shows the toolbar; another center-tap hides it.
- Left/right tap zones still navigate and do not affect toolbar visibility.
- Changing the mode via the menu updates the stored preference and the menu label.

Existing unit tests for `PerformanceNavigator` and `PerformanceScrollCalculator` are unaffected.

## Components affected

- `Leadify/Views/Performance/PerformanceView.swift` — remove old buttons, add toolbar overlay, wire center-tap to toggle.
- `Leadify/Views/Performance/PerformanceTapOverlay.swift` — center-tap callback now emits a plain toggle event (no content-Y payload needed).
- New file: `Leadify/Views/Performance/PerformanceToolbar.swift` — the capsule toolbar view.
- `Leadify/Theme/PerformanceTheme.swift` — add any token used by the toolbar (padding, vertical offset). No new color tokens needed since it uses `.regularMaterial` and system tint.
- (No changes to `SettingsSheet.swift`.)
- `Tests/UITests/PerformanceUITests.swift` and `PerformanceIntegrationTest.swift` — update lookups.

## Open questions / deferred

- **Icon choice for the mode menu label.** Starting with a single consistent icon (e.g. `slider.horizontal.3`) rather than a per-mode icon; can iterate after seeing it.
- **Labels-vs-icons** for Exit and Sidebar buttons. Starting with icon + label; user may revisit once it's on-device.
- **Future additions to the toolbar** (e.g. annotation, font size, metronome) are explicitly out of scope here but the layout leaves room.
