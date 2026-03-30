# Song Library UI — Design Spec

**Date:** 2026-03-30
**Status:** Approved

---

## Overview

Add a Song Library to Leadify: a second sidebar mode that lists all songs in the database, lets the user sort, delete, and edit songs, with a full-pane side-by-side editor in the detail column.

This spec covers:
1. Data model additions (`createdAt`)
2. Sidebar navigation restructure (segmented control)
3. Song Library sidebar view
4. Song editor detail view

Markdown import is explicitly out of scope — covered in a future spec.

---

## 1. Data Model

Add `createdAt: Date = Date()` to three models:

| Model | Change |
|-------|--------|
| `Song` | Add `var createdAt: Date = Date()`; add `@Relationship(deleteRule: .cascade, inverse: \SetlistEntry.song) var entries: [SetlistEntry] = []` |
| `Setlist` | Add `var createdAt: Date = Date()` |
| `SetlistEntry` | Add `var createdAt: Date = Date()` |

SwiftData lightweight migration handles existing records automatically — it assigns `Date()` at the time of first launch after the update.

No other model changes are required.

---

## 2. Sidebar Navigation

### `ContentView` changes

Add to `ContentView`:

```swift
enum SidebarMode { case setlists, songs }

@State private var sidebarMode: SidebarMode = .setlists
@State private var selectedSong: Song?
```

The existing `selectedSetlist` remains unchanged.

### Sidebar rendering

The sidebar column conditionally renders based on `sidebarMode`:
- `.setlists` → existing `SetlistSidebarView` (no changes)
- `.songs` → new `SongLibrarySidebarView`

### Detail pane rendering

| Mode | Selection | Detail pane |
|------|-----------|-------------|
| `.setlists` | setlist selected | `SetlistDetailView` (existing) |
| `.setlists` | none | `ContentUnavailableView("No Setlist Selected", …)` (existing) |
| `.songs` | song selected | `SongEditorDetailView` (new) |
| `.songs` | none | `ContentUnavailableView("No Song Selected", …)` (new) |

### Segmented control

A `Picker("Mode", selection: $sidebarMode)` with `.pickerStyle(.segmented)` placed in the sidebar column's `.toolbar`. Labels: "Setlists" / "Songs".

Each mode remembers its own selection independently — switching modes restores the last selection in that mode.

---

## 3. Song Library Sidebar (`SongLibrarySidebarView`)

### Layout

- A `List` of all songs, driven by a `@Query` with sort order controlled by the active sort option.
- Each row shows the song title (primary) and `createdAt` date (secondary, smaller).
- Tapping a row sets `selectedSong` via a binding.
- Swipe left on a row reveals a **Delete** action (destructive, with confirmation alert).

### Sorting

A toolbar menu button (system image: `arrow.up.arrow.down`) with two options:
- **A → Z** (default) — sorts by `title` ascending, case-insensitive
- **Date added** — sorts by `createdAt` descending (newest first)

Sort preference is held in `@State` within the view (not persisted — defaults to A→Z on each launch).

### Toolbar

- Leading: sort menu button
- Trailing: **Import** button (reserved for future use — present but disabled/hidden in this iteration)

---

## 4. Song Editor Detail View (`SongEditorDetailView`)

### Layout

Two equal columns separated by a `Divider`, filling the full detail pane:

**Left column — editor:**
- Large title `TextField` at the top
- Smaller reminder `TextField` below (placeholder: "Reminder (optional)")
- `TextEditor` filling remaining height — markdown source

**Right column — live preview:**
- Read-only `MarkdownUI` render of the current `content`
- Uses the existing `.leadifyPerformance` MarkdownUI theme
- Updates reactively as the user types (driven by the same `@Bindable` song)

### Persistence

Changes write directly to SwiftData via `@Bindable` on the `Song` object — no explicit Save button, no draft/discard flow. This matches the existing editing pattern in the app.

### Toolbar

- Trailing: **Delete Song** button (system image: `trash`, destructive tint)
  - Tapping shows a confirmation alert: "Delete "[title]"? This cannot be undone."
  - On confirm: deletes the song from the model context, clears `selectedSong`
  - **Note:** deleting a song must also delete all `SetlistEntry` rows that reference it. Implement by adding an inverse relationship on `Song`: `@Relationship(deleteRule: .cascade, inverse: \SetlistEntry.song) var entries: [SetlistEntry] = []`. SwiftData will then cascade-delete the entries automatically.

### Relation to `SongEditorSheet`

`SongEditorSheet` is currently used when editing a song from within a setlist (via `SongEntryRow`). It remains in place for that flow. `SongEditorDetailView` is the new full-pane editor used exclusively from the Song Library. They share the same underlying `Song` model — edits in either view update the song everywhere.

---

## File Plan

New files:
- `Leadify/Views/Sidebar/SongLibrarySidebarView.swift`
- `Leadify/Views/Setlist/SongEditorDetailView.swift`

Modified files:
- `Leadify/Models/Song.swift` — add `createdAt`
- `Leadify/Models/Setlist.swift` — add `createdAt`
- `Leadify/Models/SetlistEntry.swift` — add `createdAt`
- `Leadify/ContentView.swift` — add `sidebarMode`, `selectedSong`, conditional rendering

---

## Out of Scope

- Markdown / YAML frontmatter import (future spec)
- CloudKit sync
- Export
