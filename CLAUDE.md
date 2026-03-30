# Leadify — Claude Instructions

## Project layout

```
/Users/bartvanraaij/Dev/leadify/          ← git root (also Claude's working dir, also Xcode project folder)
├── Leadify.xcodeproj/
├── Leadify/                         ← Swift source root
│       ├── LeadifyApp.swift
│       ├── ContentView.swift
│       ├── Models/                      Song, Tacet, SetlistEntry, Setlist
│       ├── Theme/                       EditTheme, PerformanceTheme
│       └── Views/
│           ├── Sidebar/                 SetlistSidebarView, SetlistRowView, SetlistEditSheet
│           ├── Performance/             PerformanceView, PerformanceViewModel, SongBlock, TacetBlock
│           └── Setlist/
│               └── (ordering views)     SetlistDetailView, SongEntryRow, TacetRow, etc.
├── LeadifyTests/                        SetlistTests, SongTests, TestHelpers
├── docs/superpowers/
│   ├── specs/2026-03-28-leadify-design.md
│   ├── plans/2026-03-28-leadify-plan-1-foundation-ordering.md
│   └── plans/2026-03-28-leadify-plan-2-performance-mode.md
└── .claude/projects/.../memory/         persistent memory across sessions
```

## Build & test commands

```bash
# Find available simulators
xcrun simctl list devices available | grep -i ipad

# Build (use a 26.2 simulator — the project targets iOS 26.2)
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=2EB88329-DA02-4D84-ABFD-8E49B53AF6B8'

# Run all tests
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=2EB88329-DA02-4D84-ABFD-8E49B53AF6B8'
```

The simulator ID `2EB88329-...` is "iPad Pro 13-inch (M5)" running iOS 26.2. If it disappears, find a replacement with `xcrun simctl list devices available | grep iPad`.

## Critical: adding new Swift files

When creating new `.swift` files with the Write tool, Xcode does **not** automatically include them in the build target. After creating files, tell the user to:

> Right-click the parent group in the Xcode file navigator → **Add Files to "Leadify"** → select the new file(s).

Then **Cmd+Shift+K** (Clean Build Folder) → **Cmd+B**.

## SwiftData ordering — always use `sortedEntries` / `addEntry`

SwiftData relationship arrays (`[SetlistEntry]`) **do not preserve insertion order** after a save/fetch cycle. We solved this with an explicit `order: Int` on `SetlistEntry`.

**Rules:**
- Never iterate or display `setlist.entries` directly — always use `setlist.sortedEntries`
- Never append to `setlist.entries` directly — always use `setlist.addEntry(entry)` which assigns the correct order value
- The `moveEntries` function in `SetlistDetailView` mutates `.order` on each entry after a move — this is the source of truth for ordering

## Theme system — no hardcoded values in views

All sizes and colors live in two structs:

- `Theme/PerformanceTheme.swift` — performance (fullscreen) mode
- `Theme/EditTheme.swift` — edit/ordering mode and song editor

Never use literal `CGFloat` sizes or `Color(...)` values in view files. Add tokens to the theme structs instead.

The custom MarkdownUI theme (`.leadifyPerformance`) is defined as an extension in `Views/Setlist/SongEditorSheet.swift`. If that file moves or grows, consider extracting it to `Theme/MarkdownTheme.swift`.

## Data model key facts

- `Song` — shared across setlists by reference. Editing a song updates it everywhere.
- `Tacet` — owned by its `SetlistEntry` (cascade delete). Must be deep-copied when duplicating a setlist.
- `SetlistEntry` — join object holding either a `Song?` or `Tacet?`. `itemType` is derived from which is non-nil.
- `Setlist.duplicate(in:)` — iterates `sortedEntries`, shares song references, deep-copies tacets, preserves order.
- `ModelContainer` is initialised without `.none` to keep the CloudKit migration path open.

## Current status (as of 2026-03-28)

### Done
- Plan 1: All data models, themes, setlist editing/ordering UI, unit tests ✅
- Plan 2: Performance mode (PerformanceViewModel, SongBlock, TacetBlock, PerformanceView) ✅
- Tests: all 10 passing ✅

### Known UI issues / next refinements
- Font sizes in performance mode bumped (28/22/18) — user wants to test on real iPad to fine-tune
- "Setlists" sidebar title left-alignment fix applied — verify visually
- Song editor form height (260) — may still need adjustment depending on Dynamic Type settings
- Tap-to-edit on rows works, but there's no visual affordance (no chevron/indicator) — consider adding `Image(systemName: "chevron.right")` in a secondary style

### Not yet started
- CloudKit sync (mentioned as future work in design spec)
- AirDrop / file import using the canonical song format (YAML frontmatter + Markdown body)
- Any font size / layout tuning after testing on real hardware

## User background

Experienced in C#, PHP, Node, TypeScript, Angular. Zero prior Swift/iOS experience. Frame Swift/SwiftUI concepts using analogues from those worlds (e.g. `@Observable` ≈ MobX store, SwiftData ≈ EF Core, `@Query` ≈ a reactive DB query).
