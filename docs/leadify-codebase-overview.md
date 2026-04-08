# Leadify — Codebase Overview

## 1. What the App Does

**Leadify** is an iPad app for **live musicians** to manage and perform setlists. The core value proposition is a clean, stage-usable UI: you build setlists in edit mode, then switch to a full-screen **Performance Mode** (think ForScore, but for chord charts) where you navigate through songs with large tap zones rather than tiny buttons. The target user is a gigging musician who writes their own chord charts in a lightweight markdown format.

---

## 2. Main Features

| Feature | Description |
|---|---|
| **Song library** | Global song database (`SongLibrarySidebarView`). Create, edit, duplicate, delete songs. Sort alphabetically or by date added. |
| **Song editor** | `SongEditorDetailView` — plain-text editor with monospaced font, title + optional reminder field, explicit Save/Revert buttons, live preview sheet (`SongEditorPreview`). |
| **Markdown import** | `SongImporter` + `SongFileParser` — import `.txt`/`.md` files with YAML-style frontmatter (`title:`, `reminder:`). Supports single-file, multi-file batch import, and conflict resolution (Overwrite / Keep Both / Skip / Overwrite All / Skip All). |
| **Setlists** | Create and manage named setlists with optional date. `SetlistDetailView` supports drag-to-reorder, swipe-to-delete, duplicate. |
| **Medleys** | A named, ordered group of songs (`Medley`/`MedleyEntry`). Managed in `MedleyDetailView`, same CRUD pattern as setlists. Can be embedded in setlists as a single entry, displayed as a grouped block with song sub-rows. |
| **Tacets** | Silence markers in a setlist (from music notation). Created via `TacetEditSheet`, displayed as `TacetSetlistRow`. Skipped during next/prev navigation in performance mode. |
| **Performance Mode** | Full-screen, status-bar-hidden, scrollable view of all items. Left/right tap zones (36%/64% split) for prev/next navigation. Center-tap activates an entry directly. Up/down chevrons for snapping through long entries. Non-active entries dim to 50% opacity. Auto-shows sidebar at ≥900pt width. |
| **Performance sidebar** | `PerformanceSetlistSidebar` — inspector-style panel showing all items, active highlighted, prev/next buttons at bottom. Auto-scrolls to keep the active item in view. |
| **Medley performance** | Medley renders as a single `MedleyPerformanceBlock` (all songs in one card with dividers). Counts as one navigation stop. |
| **"Perform all songs"** | `SongLibrarySidebarView` can launch a `PerformanceView` over a `SongCollection` (all songs in sorted order), bypassing setlists entirely. |

---

## 3. Data Models

All models use **SwiftData** (`@Model`), stored locally on-device.

```
Song
 ├── title: String
 ├── content: String          ← markdown-like chord chart text
 ├── reminder: String?        ← shown as accent badge in performance (e.g. "Capo 2")
 ├── entries: [SetlistEntry]  ← back-reference (cascade delete)
 └── medleyEntries: [MedleyEntry]  ← back-reference (cascade delete)

Setlist
 ├── name: String
 ├── date: Date?
 └── entries: [SetlistEntry]  ← cascade delete; use .sortedEntries for display

SetlistEntry                  ← join/discriminated union
 ├── song: Song?              ← non-nil for .song type
 ├── tacet: Tacet?            ← non-nil for .tacet type (cascade delete)
 ├── medley: Medley?          ← non-nil for .medley type
 ├── setlist: Setlist?
 └── order: Int               ← explicit ordering (SwiftData doesn't preserve insertion order)

Tacet
 ├── label: String?           ← optional display name (e.g. "Intro" or "Break")
 └── entry: SetlistEntry?     ← owned by its entry

Medley
 ├── name: String
 ├── entries: [MedleyEntry]   ← cascade delete; use .sortedEntries
 └── setlistEntries: [SetlistEntry]  ← back-reference

MedleyEntry
 ├── song: Song               ← non-optional (medley songs are never absent)
 ├── medley: Medley?
 └── order: Int
```

**Key relationships:**
- `Song` is **shared by reference** across setlists and medleys — editing a song updates it everywhere
- `Tacet` is **owned** by its `SetlistEntry` and is deep-copied on setlist duplication
- `Medley` is **shared by reference** across setlists (like `Song`)
- `SetlistEntry.itemType` is a computed discriminator derived from which optional is non-nil (priority: medley > song > tacet)

**Ordering workaround:** SwiftData relationship arrays don't preserve insertion order after a save/fetch cycle. All entry objects carry an explicit `order: Int`; views always iterate via `.sortedEntries`, and new entries go through `.addEntry(_:)` which assigns the correct order.

---

## 4. Screen Structure

```
ContentView (NavigationSplitView, 3-column)
 ├── Column 1 — App sidebar (SidebarItem enum: Setlists / Songs / Medleys)
 ├── Column 2 — Content list (switches based on selected SidebarItem)
 │    ├── SetlistSidebarView          → SetlistSidebarRow
 │    ├── SongLibrarySidebarView      → SongLibraryRow
 │    └── MedleySidebarView           → MedleySidebarRow
 └── Column 3 — Detail pane
      ├── SetlistDetailView
      │    ├── Sheet: SongLibrarySheet       (pick song → add to setlist)
      │    ├── Sheet: TacetEditSheet
      │    ├── Sheet: MedleyLibrarySheet     (pick medley → add to setlist)
      │    ├── Sheet: SongEditorSheet        (edit song inline)
      │    ├── Sheet: SetlistEditSheet       (rename/redate setlist)
      │    └── FullScreenCover: PerformanceView(source: setlist)
      ├── SongEditorDetailView
      │    └── Sheet: preview (SongEditorPreview via SongContentRenderer)
      └── MedleyDetailView
           ├── Sheet: MedleySongLibrarySheet (pick song → add to medley)
           ├── Sheet: MedleyEditSheet        (rename medley)
           └── FullScreenCover: PerformanceView(source: medley)

PerformanceView (fullscreen, status bar hidden)
 ├── ScrollView of PerformanceItems
 │    ├── SongPerformanceBlock (or SongPerformanceContent for standalone)
 │    ├── TacetPerformanceBlock
 │    └── MedleyPerformanceBlock (renders all songs in the medley)
 ├── PerformanceTapOverlay (UIViewRepresentable, gesture on UIScrollView)
 ├── Chevron buttons (up/down, conditional)
 ├── Close button (top-left)
 ├── Sidebar toggle button (top-right)
 └── Inspector: PerformanceSetlistSidebar (prev/next buttons + item list)
```

---

## 5. Architecture

- **No MVVM layer** — views talk directly to SwiftData models via `@Query` and `@Environment(\.modelContext)`. Observable state is local `@State` or `@Bindable` on the model.
- **`@Observable` class** — `SongImporter` is the one app-level service object, injected via `.environment()`. It owns the import flow state machine and conflict resolution queue.
- **`Performable` protocol** — `Setlist`, `Medley`, and the ad-hoc `SongCollection` struct all conform. `PerformanceView` accepts `any Performable`, making it completely decoupled from the source type.
- **Pure-logic helpers** — `PerformanceNavigator` (tap navigation math) and `PerformanceScrollCalculator` (chevron scroll snap math) are stateless enums, extracted specifically to be unit-tested without a view.
- **Theme structs** — `PerformanceTheme` and `EditTheme` are static constant structs. No literal `CGFloat` or `Color` values in views — all go through the theme. Adaptive light/dark colors via a custom `Color(light:dark:)` initializer backed by `UIColor(dynamicProvider:)`.
- **Custom renderer** — `SongContentRenderer` is a hand-rolled SwiftUI view that parses and renders the song content markdown (replaces an earlier external MarkdownUI dependency). It supports H1, H2, chord lines (with fixed-width cell layout via a custom `ChordFlowLayout: Layout`), plain text, and fenced code blocks.
- **UIKit bridge** — `PerformanceTapOverlay: UIViewRepresentable` walks the view hierarchy to find the enclosing `UIScrollView` and attaches a `UITapGestureRecognizer` directly to it, so taps and native scroll coexist.
- **UI test seeding** — `--uitesting` launch arg triggers an in-memory `ModelContainer` and `UITestSeeder.seed()` for deterministic black-box UI tests.

---

## 6. Integrations

| Integration | Purpose |
|---|---|
| **SwiftData** | Only persistence layer. No Core Data, no CloudKit (yet — schema intentionally not using `.none` to keep CloudKit path open). |
| **SwiftUI** | Entire UI including `NavigationSplitView`, `.inspector()` for performance sidebar, `ScrollPosition`, `PreferenceKey` for frame tracking. |
| **UIKit** | `UITapGestureRecognizer` via `UIViewRepresentable` (`PerformanceTapOverlay`); `UIColor(dynamicProvider:)` for adaptive colors; `UIFont` metrics in `PerformanceTheme.annotationBaselineOffset`. |
| **`UniformTypeIdentifiers`** | `.plainText` type for `.fileImporter` in song import. |
| **`NSRegularExpression`** | Chord name validation regex in `SongContentRenderer.isChord(_:)`. |
| **No external dependencies** | No SPM packages. The MarkdownUI dependency was removed and replaced with the custom renderer. |

---

## 7. Notable Things

**Clever:**
- `SetlistEntry` as a discriminated union (one nullable per type, `itemType` as computed discriminator) avoids an enum-with-associated-values in SwiftData, which doesn't support that natively.
- `PerformanceTapOverlay` attaches its gesture recognizer to the underlying `UIScrollView` by walking the view hierarchy — avoids the classic problem of an overlay stealing scroll events from SwiftUI's `ScrollView`.
- `ChordFlowLayout: Layout` is a custom SwiftUI layout protocol implementation that wraps chord cells to the next line when they overflow — handles long chord sequences gracefully without truncation.
- `SongCollection` is a zero-persistence `Performable` struct, so the "play all songs" feature reuses `PerformanceView` entirely without any model changes.
- Frame tracking via `EntryFrameKey: PreferenceKey` in the scroll coordinate space gives stable content positions (not screen positions), enabling reliable scroll-to calculations even after window resize.

**Current limitations / gaps:**
- **No CloudKit sync** — data is local only.
- **No search** across songs or setlists.
- **No audio/MIDI** — purely visual display, no playback.
- **No font-size control** — all sizes are fixed constants in theme structs (planned tuning after real-device testing).
- **No ABC notation rendering** — code blocks with `language: "abc"` are accepted but rendered as plain monospaced text; the renderer is extensible to support it.
- **No visual affordance for tap-to-edit** on setlist rows (no chevron indicator).
- **Medley display in setlist** uses "header + flat sub-rows" approach (`MedleySetlistGroup`); grouped/collapsed variations were considered but not implemented.
- `findExistingSong` in `SongImporter` does a full `FetchDescriptor<Song>()` (no predicate) and filters in memory — will degrade on large libraries.
