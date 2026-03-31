# Performance View Redesign — Active Entry Navigation

**Date:** 2026-03-31
**Status:** Approved

## Problem

The current PerformanceView uses top/bottom 20% overlay tap zones with `simultaneousGesture(TapGesture())` to scroll by one viewport. This has two issues:

1. Tap zones interfere with native scrolling — SwiftUI's simultaneous gesture causes both tap and scroll to fire, making scrolling feel unnatural.
2. Viewport-based scrolling has no awareness of song boundaries — you scroll by an arbitrary distance, not to a meaningful position.

## Design

### Core Concept: Active Entry Navigation

The view tracks an `activeEntryIndex` into `setlist.sortedEntries`. The unit of navigation is a **setlist entry** — a standalone song, a tacet, or an entire medley (not individual songs within a medley).

### Two-Phase Tap Navigation (ForScore-style)

Tap zones occupy the left and right 40% of the screen. The center 20% is a safe zone (no tap handling, pure scroll).

**Right tap zone:**
1. If the active entry's bottom edge is below the viewport → scroll down ~60% of viewport height (revealing more of the current entry). `activeEntryIndex` stays the same.
2. If the active entry's bottom edge is already visible → increment `activeEntryIndex` and scroll so the new entry's top is ~20pt from the top of the viewport.

**Left tap zone:**
1. If the active entry's top edge is above the viewport → scroll up ~60% of viewport height within the current entry.
2. If the active entry's top is already visible → decrement `activeEntryIndex` and scroll to its top.

**Native scroll works everywhere**, including inside tap zones. Tap detection uses a `UIViewRepresentable` with `UITapGestureRecognizer` rather than SwiftUI's `simultaneousGesture`, so taps and scroll drags don't conflict.

### Entry Position Tracking

Each entry reports its frame via `anchorPreference`. The view maintains a dictionary of `[entryID: CGRect]` so the tap handler can determine whether the active entry fits in the current viewport.

### Visual States

- **Active entry:** opacity 1.0
- **Upcoming entries** (after active): opacity 0.4
- **Past entries** (before active): opacity 0.3
- Opacity transitions animated with ~0.3s ease when `activeEntryIndex` changes.

Past entries are NOT collapsed — they stay full-size but dimmed, scrolled naturally off the top. This avoids layout shifts and simplifies implementation.

### Adaptive Layout (Narrow vs Wide)

Width threshold: **950pt**.

**Narrow mode (<950pt) — split-screen use:**
Single column. The scroll view takes full width. Entries stacked vertically with dimming applied based on active state.

**Wide mode (≥950pt) — full-screen use:**
Two-pane layout:
- **Left ~75%:** Same scroll content as narrow mode.
- **Right ~25%:** Compact setlist sidebar showing all entry titles (song title, tacet label, or medley name). The active entry is highlighted with accent color. Tapping a sidebar title sets `activeEntryIndex` and scrolls to that entry.

The sidebar has a slightly offset background and a subtle vertical divider. Layout transitions live when resizing the split-screen divider.

### Animation

All scroll transitions use `easeInOut(duration: 0.25)`.

### Edge Cases

- **Start of set:** `activeEntryIndex` = 0. First entry at full brightness, rest dimmed.
- **End of set:** On the last entry, right-tap scrolls within if content extends below. Once bottom is visible, tap does nothing. No wrap-around.
- **Medley internals:** A medley is one navigation unit. The scroll-within phase works on the entire medley card (may take multiple taps for long medleys). No separate dimming for songs within a medley.
- **Manual scroll:** Native drag scrolling does NOT change `activeEntryIndex`. The active highlight only moves via tap-zone taps or sidebar taps. This lets the user peek ahead without losing their place.
- **Split-screen resize:** Sidebar appears/disappears at 950pt threshold. `activeEntryIndex` and scroll position preserved.
- **Tacets:** Navigable entries like songs/medleys. Since they're visually small, the scroll-within phase rarely triggers — taps usually just advance past them.

### Gesture Implementation

A `UIViewRepresentable` wraps a `UITapGestureRecognizer` attached to the scroll view's UIKit layer. This is the standard approach for tap-over-scroll (used by ForScore and similar apps). The recognizer checks the tap's X position to determine left/right zone, then runs the two-phase logic.

### Close Button

Stays as-is (`xmark.circle.fill`, top-right). In wide mode, positioned in the top-right of the scroll content pane, not the sidebar.

### Theme

No new theme tokens initially — dimming uses opacity modifiers on existing styled blocks. Sidebar uses existing `PerformanceTheme` values. Tokens added later if needed.

### Out of Scope

- Medley rehearsal mode (separate view, not affected)
- CloudKit sync
- Font size tuning (separate task, pending real hardware testing)

## Context

The user performs on stage with an iPad in landscape, typically in 2/3 split-screen mode (Leadify + SQ4You in-ear monitoring). The ForScore-style two-phase tap navigation is familiar to them. The setlist sidebar in wide mode provides a "where am I in the set" overview when the full screen is available.
