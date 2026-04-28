# Leadify — Claude Instructions

## Project layout

```
LeadifyCore/             Framework target — models, navigators, parsers, calculators (no SwiftUI)
LeadifyCoreTests/        Unit tests for LeadifyCore (runs on macOS natively)
Leadify/
├── Theme/               PerformanceTheme, EditTheme
├── Views/
│   ├── Song/            Song editing, preview, library
│   ├── Tacet/           Tacet editing
│   ├── Setlist/         Setlist editing, sidebar, rows
│   ├── Medley/          Medley editing, sidebar, rows
│   └── Performance/     Performance mode UI, rendering, toolbar
docs/superpowers/        Design specs and implementation plans
```

## Build & test commands

```bash
# Find available simulators
xcrun simctl list devices available | grep -i ipad

# Build (use a 26.x simulator)
xcodebuild build -project Leadify.xcodeproj -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'

# Run all unit tests (on macOS, no simulator needed)
xcodebuild test -scheme LeadifyCoreTests -destination 'platform=macOS'

# Run on simulator with seeded data (must terminate → install → launch; launch alone uses stale binary)
xcrun simctl terminate B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5 dev.bartvanraaij.leadify 2>/dev/null
xcrun simctl install B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5 \
  ~/Library/Developer/Xcode/DerivedData/Leadify-dcfskxmsfskcybdoxvrgstsbknvm/Build/Products/Debug-iphonesimulator/Leadify.app
xcrun simctl launch B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5 dev.bartvanraaij.leadify --seeded

# Run on physical iPad (release build)
xcodebuild build -scheme "Leadify (Release)" -destination 'platform=iOS,name=iPad (2)'
xcrun devicectl device install app --device 'iPad (2)' \
  ~/Library/Developer/Xcode/DerivedData/Leadify-dcfskxmsfskcybdoxvrgstsbknvm/Build/Products/Release-iphoneos/Leadify.app
xcrun devicectl device process launch --terminate-existing --device 'iPad (2)' dev.bartvanraaij.leadify
```

Bundle ID is `dev.bartvanraaij.leadify`.

The iPad simulator ID `B05E0EF4-...` is "iPad (A16)" running iOS 26.3. If it disappears, find a replacement with `xcrun simctl list devices available | grep iPad`.
The iPhone simulator ID `DC9A3E5F-...` is for testing compact layout. Find a replacement with `xcrun simctl list devices available | grep iPhone`.
The physical iPad is named "iPad (2)". After changes, deploy to **both** simulators (with `--seeded` for seeded data) and physical iPad (release build) before asking for feedback.

## Adding new Swift files

New `.swift` files created in `Leadify/`, `LeadifyCore/`, or `LeadifyCoreTests/` are automatically included in their respective Xcode targets. No manual "Add Files" step is needed — just build directly after creating files.

## LeadifyCore framework

All data models, navigators, parsers, and calculators live in the `LeadifyCore` framework target. This framework has no SwiftUI/UIKit dependencies and supports both iOS and native macOS destinations, so tests run on macOS without a simulator.

**Rules:**
- New model or pure-logic files go in `LeadifyCore/` — not in `Leadify/`
- Types in the framework must be marked `public` for the app to use them
- New tests go in `LeadifyCoreTests/` with `@testable import LeadifyCore`
- View files in the app need `import LeadifyCore` to access framework types
- `SongContentParser` (Foundation, in LeadifyCore) handles parsing; `SongContentRenderer` (SwiftUI, in Leadify) handles rendering
- `PerformanceScrollCalculator` takes `dividerHeight` as a parameter (default `1`) instead of reading `PerformanceTheme` directly

## SwiftData enum properties

SwiftData's `@Model` macro can't handle enum default values inline. Use a `String` backing property with a computed getter/setter:
```swift
var displayModeRaw: String = MedleyDisplayMode.separated.rawValue
var displayMode: MedleyDisplayMode {
    get { MedleyDisplayMode(rawValue: displayModeRaw) ?? .separated }
    set { displayModeRaw = newValue.rawValue }
}
```

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
- `Medley` — a fixed group of songs in a specific order. Shared across setlists by reference (like Song). Has `sortedEntries`, `addEntry()`, `duplicate(in:)`, and `displayMode` (`.separated`/`.combined`) controlling how it renders in performance mode.
- `MedleyEntry` — join object with a non-optional `Song` reference and `order: Int`. Same ordering pattern as `SetlistEntry`.
- `Setlist.duplicate(in:)` — shares song and medley references, deep-copies tacets, preserves order.
- `Performable` — protocol conforming types (`Setlist`, `Medley`) provide `performanceTitle` and `performanceItems: [PerformanceItem]`. `PerformanceView` accepts `any Performable`, so both setlists and medleys share the same performance UI.
- `PerformanceItem` — lightweight value struct with `kind` (.song/.tacet/.medley), `title`, `medleyTitle` (for first song in a separated medley), and optional model refs. `isSkippable` returns true for tacets (skipped during next/prev navigation).
- `ModelContainer` is initialised without `.none` to keep the CloudKit migration path open.

## Current status (as of 2026-04-22)

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
- Medley display mode: per-medley setting (separated/combined) for performance view ✅
- Performance typography: rounded font for titles/headings, lowercase section headers, content indent ✅
- Tab rendering: box-drawing characters, Menlo font, dual-color (grey grid, primary notation), fretboard-aware corners ✅
- Reminder badge: inline accent-colored text after song title (replaced filled pill) ✅
- SongPerformanceContent: unified component used by performance view and editor previews ✅
- SongPreviewSheet: shared preview sheet for both song editors ✅
- Performance toolbar: fog gradient backdrop, navigation mode menu with section header ✅
- Settings sheet removed — nav mode accessible from performance toolbar only ✅
- Font size / layout tuning on real hardware ✅
- UI tests removed — visual validation done on device, behavior covered by unit tests ✅
- LeadifyCore framework: models, navigators, parsers extracted into framework target; 95 tests run on macOS natively without simulator ✅
- GitHub Actions CI: runs `swift test` on PRs and pushes to main ✅
- Tests: all passing ✅

### Known UI issues / next refinements
- Code blocks (tabs) clip when too wide for the view — horizontal scrolling not yet solved
- TextEditor doesn't support disabling word wrap natively

### Not yet started
- CloudKit sync (mentioned as future work in design spec)

## User background

Experienced in C#, PHP, Node, TypeScript, HTML/CSS. Zero prior Swift/iOS experience. Frame Swift/SwiftUI concepts using analogues from those worlds (e.g. `@Observable` ≈ MobX store, SwiftData ≈ EF Core, `@Query` ≈ a reactive DB query).
