# Leadify — Claude Instructions

## Project layout

```
/Users/bartvanraaij/Dev/leadify/          ← git root (also Claude's working dir, also Xcode project folder)
├── Leadify.xcodeproj/
├── Leadify/                         ← Swift source root
│       ├── LeadifyApp.swift
│       ├── ContentView.swift
│       ├── Models/                      Song, Tacet, SetlistEntry, Setlist, Medley, MedleyEntry,
│       │                                Performable (protocol + PerformanceItem),
│       │                                SongFileParser, SongImporter
│       ├── Theme/                       EditTheme, PerformanceTheme
│       └── Views/                       domain-based grouping (see naming conventions below)
│           ├── Song/                    SongDisplayView, SongEditorSheet, SongEditorDetailView,
│           │                            SongLibrarySheet, SongLibrarySidebarView,
│           │                            SongContentRenderer
│           ├── Tacet/                   TacetEditSheet
│           ├── Setlist/                 SetlistDetailView, SetlistSidebarView, SetlistSidebarRow,
│           │                            SetlistEditSheet, SetlistAddEntrySection,
│           │                            SongSetlistRow, TacetSetlistRow,
│           │                            MedleySetlistGroup, MedleyLibrarySheet
│           ├── Medley/                  MedleySidebarView, MedleySidebarRow, MedleyEditSheet,
│           │                            MedleyDetailView, MedleySongRow, MedleySongLibrarySheet
│           └── Performance/             PerformanceView, PerformanceTapOverlay,
│                                        PerformanceSetlistSidebar, PerformanceNavigator,
│                                        PerformanceScrollCalculator,
│                                        SongPerformanceBlock, TacetPerformanceBlock
├── Leadify.xctestplan                   test plan (at project root, referenced by scheme)
├── Tests/
│   ├── UnitTests/                       SetlistTests, SongTests, MedleyTests,
│   │                                    PerformanceNavigationTests, PerformanceScrollCalculatorTests,
│   │                                    SongFileParserTests, SongContentRendererTests,
│   │                                    SongImporterTests, TestHelpers
│   └── UITests/                         PerformanceUITests (black-box, size-agnostic),
│                                        PerformanceIntegrationTest (full user session)
├── docs/superpowers/
│   ├── specs/2026-03-28-leadify-design.md
│   ├── specs/2026-03-30-markdown-import-design.md
│   ├── specs/2026-03-30-song-library-design.md
│   ├── specs/2026-03-31-medley-design.md
│   ├── specs/2026-03-31-performance-view-redesign.md
│   ├── plans/2026-03-28-leadify-plan-1-foundation-ordering.md
│   ├── plans/2026-03-28-leadify-plan-2-performance-mode.md
│   ├── plans/2026-03-29-ui-polish-plan-3.md
│   ├── plans/2026-03-30-markdown-import-plan.md
│   ├── plans/2026-03-30-song-library-plan.md
│   ├── plans/2026-03-31-medley-plan.md
│   └── plans/2026-03-31-performance-view-redesign-plan.md
└── .claude/projects/.../memory/         persistent memory across sessions
```

## Build & test commands

```bash
# Find available simulators
xcrun simctl list devices available | grep -i ipad

# Build (use a 26.x simulator)
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'

# Run all unit tests
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' \
  -only-testing:LeadifyTests

# Run UI tests (single device)
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' \
  -only-testing:LeadifyUITests

# Run UI tests on multiple iPad sizes (parallel)
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,name=iPad mini (A17 Pro)' \
  -destination 'platform=iOS Simulator,name=iPad Air 11-inch (M3)' \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
  -only-testing:LeadifyUITests

# Run on simulator (must terminate → install → launch; launch alone uses stale binary)
xcrun simctl terminate B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5 dev.bartvanraaij.leadify 2>/dev/null
xcrun simctl install B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5 \
  ~/Library/Developer/Xcode/DerivedData/Leadify-dcfskxmsfskcybdoxvrgstsbknvm/Build/Products/Debug-iphonesimulator/Leadify.app
xcrun simctl launch B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5 dev.bartvanraaij.leadify
```

Bundle ID is `dev.bartvanraaij.leadify`.

The simulator ID `B05E0EF4-...` is "iPad (A16)" running iOS 26.3. If it disappears, find a replacement with `xcrun simctl list devices available | grep iPad`.

## Adding new Swift files

New `.swift` files created in the project directory are automatically included in the Xcode build target. No manual "Add Files" step is needed — just build directly after creating files.

## UI testing (XCUITest)

Black-box UI tests in `Tests/UITests/` test the Performance view without coupling to implementation. Key patterns:

- **Test data seeding:** `--uitesting` launch arg → `UITestSeeder.seed()` with in-memory ModelContainer (behind `#if DEBUG`)
- **Size-agnostic tap zones:** Tap coordinates derived from `performance-content-area` accessibility landmark (a `Color.clear` overlay sized to `geo.size`). Never use screen-relative coordinates.
- **Element lookup:** Always use `app.descendants(matching: .any).matching(identifier:).firstMatch` — SwiftUI element types are unpredictable across contexts (buttons in inspector sidebar may not be found via `app.buttons`).
- **Sidebar detection:** Use `ensureSidebarOpen()` pattern — check if sidebar exists before toggling, since it auto-shows at wide widths.
- **Identifier propagation:** Parent `.accessibilityIdentifier()` propagates to all children in SwiftUI. Put identifiers on `.background()` views to avoid conflicts with child button identifiers.
- **Async labels:** SwiftUI accessibility label updates are async — poll with a deadline instead of asserting immediately.
- **Viewport-dependent tests:** Use `try XCTSkipUnless()` for features that depend on content exceeding viewport (e.g., chevron scrolling). At small window sizes the content may fit.
- **Multi-device:** Run with multiple `-destination` flags on `xcodebuild test` for parallel testing across iPad sizes.

## SwiftData ordering — always use `sortedEntries` / `addEntry`

SwiftData relationship arrays (`[SetlistEntry]`, `[MedleyEntry]`) **do not preserve insertion order** after a save/fetch cycle. We solved this with an explicit `order: Int` on entry objects.

**Rules:**
- Never iterate or display `setlist.entries` or `medley.entries` directly — always use `.sortedEntries`
- Never append directly — always use `.addEntry(entry)` which assigns the correct order value
- The `moveEntries` function in `SetlistDetailView` and `MedleyDetailView` mutates `.order` on each entry after a move — this is the source of truth for ordering

## Theme system — no hardcoded values in views

All sizes and colors live in two structs:

- `Theme/PerformanceTheme.swift` — performance (fullscreen) mode
- `Theme/EditTheme.swift` — edit/ordering mode and song editor

Never use literal `CGFloat` sizes or `Color(...)` values in view files. Add tokens to the theme structs instead.

The custom MarkdownUI theme (`.leadifyPerformance`) is defined in `Theme/MarkdownTheme.swift`.

## View naming conventions

Views are grouped by **domain** (Song, Tacet, Setlist, Medley, Performance). File and struct names encode both the domain and the role:

- `*View` — full-screen / pane-level views (e.g. `SetlistDetailView`, `PerformanceView`)
- `*Sheet` — modal/sheet presentations (e.g. `SongEditorSheet`, `TacetEditSheet`)
- `*Row` — list row components (e.g. `SongSetlistRow`, `SetlistSidebarRow`)
- `*Block` — performance mode sections (e.g. `SongPerformanceBlock`)
- `*Overlay` — transparent gesture layers (e.g. `PerformanceTapOverlay`)
- `*Navigator` — pure-logic navigation helpers (e.g. `PerformanceNavigator`)
- `*Sidebar` — sidebar/panel components (e.g. `PerformanceSetlistSidebar`)

Cross-domain components (e.g. `SongSetlistRow`) live with the **consumer** (Setlist/), not the entity (Song/). `SongSetlistRow` displays the song title only (no reminder, no preview in the row).

## Data model key facts

- `Song` — shared across setlists and medleys by reference. Editing a song updates it everywhere.
- `Tacet` — owned by its `SetlistEntry` (cascade delete). Must be deep-copied when duplicating a setlist.
- `SetlistEntry` — join object holding a `Song?`, `Tacet?`, or `Medley?`. `itemType` (.song/.tacet/.medley) is derived from which is non-nil.
- `Medley` — a fixed group of songs in a specific order. Shared across setlists by reference (like Song). Has `sortedEntries`, `addEntry()`, and `duplicate(in:)`.
- `MedleyEntry` — join object with a non-optional `Song` reference and `order: Int`. Same ordering pattern as `SetlistEntry`.
- `Setlist.duplicate(in:)` — shares song and medley references, deep-copies tacets, preserves order.
- `Performable` — protocol conforming types (`Setlist`, `Medley`) provide `performanceTitle` and `performanceItems: [PerformanceItem]`. `PerformanceView` accepts `any Performable`, so both setlists and medleys share the same performance UI.
- `PerformanceItem` — lightweight value struct with `kind` (.song/.tacet/.medley), `title`, and optional model refs. `isSkippable` returns true for tacets (skipped during next/prev navigation).
- `ModelContainer` is initialised without `.none` to keep the CloudKit migration path open.

## Current status (as of 2026-04-01)

### Done
- Plan 1: All data models, themes, setlist editing/ordering UI, unit tests ✅
- Performance mode redesigned with ForScore-style active-entry navigation: left/right tap zones for next/prev entry, up/down chevrons for within-entry scrolling, entry dimming, adaptive sidebar in wide mode (≥950pt), Performable protocol so both Setlist and Medley share the same PerformanceView ✅
- Medley feature: Medley/MedleyEntry models, sidebar section, detail view with CRUD, setlist integration (grouped display), performance mode (single card with medley title), medley-only rehearsal mode ✅
- Markdown song import: SongFileParser + SongImporter for importing songs from markdown files ✅
- Custom song content renderer: SongContentRenderer replaces external MarkdownUI dependency — supports H1, H2, chord lines (fixed-width cells), plain text, code blocks, extensible for ABC notation ✅
- Chord cell rendering: fixed-width chord cells in performance mode with auto-shrink for long chords, divider/annotation support ✅
- Song library: SongLibrarySheet, SongLibrarySidebarView for browsing/managing songs ✅
- UI polish (plan 3) ✅
- Sidebar: three sections — Setlists / Songs / Medleys ✅
- Tests: all passing ✅

### Known UI issues / next refinements
- Performance view tap zone sizes and scroll fractions may need tuning after real-device testing
- Song editor form height (260) — may still need adjustment depending on Dynamic Type settings
- Tap-to-edit on rows works, but there's no visual affordance (no chevron/indicator)
- Medley grouped display in setlist uses approach A (header + flat songs) — may iterate to B (bracket) or C (collapsed) based on testing

### Not yet started
- CloudKit sync (mentioned as future work in design spec)
- Font size / layout tuning after testing on real hardware

## User background

Experienced in C#, PHP, Node, TypeScript, Angular. Zero prior Swift/iOS experience. Frame Swift/SwiftUI concepts using analogues from those worlds (e.g. `@Observable` ≈ MobX store, SwiftData ≈ EF Core, `@Query` ≈ a reactive DB query).
