# Leadify — Medley Feature Design Spec

**Date:** 2026-03-31
**Builds on:** 2026-03-28-leadify-design.md

---

## 1. Concept

A **medley** is a fixed group of songs played in a specific order. Musicians rehearse medleys as a unit with practiced transitions between songs. Examples: "Rock 1" = Girl → Zombie → Smells Like Teen Spirit → It's My Life → Sex on Fire.

A song can belong to multiple medleys. Editing a song updates it everywhere (same shared-reference behavior as songs in setlists). Medleys can be duplicated to create variations (e.g. "Feest 2" → "Feest 2B").

---

## 2. Data Model

### Medley

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Auto-generated |
| `name` | String | e.g. "Rock 1", "Feest 2" |
| `createdAt` | Date | For default sorting |

### MedleyEntry

| Field | Type | Notes |
|---|---|---|
| `song` | Song | Required — medleys only contain songs, no tacets |
| `order` | Int | Explicit ordering (same pattern as `SetlistEntry.order`) |
| `createdAt` | Date | Tiebreaker |

### Relationships

```
Medley ──[cascade delete]──▶ MedleyEntry[]    (ordered, owns entries)
MedleyEntry ────────────────▶ Song             (shared, no cascade)
```

### Changes to existing models

**`SetlistEntry`:**
- New optional relationship: `medley: Medley?` (no cascade — medley is shared)
- When `medley` is set, `song` and `tacet` are both nil

**`SetlistItemType`:**
- New case: `.medley`
- Derived: `medley != nil ? .medley : (song != nil ? .song : .tacet)`

**`Song`:**
- Gains inverse relationship from `MedleyEntry`

### Ordering rules

Same as existing `SetlistEntry` pattern:
- `Medley.sortedEntries` — always use for display/iteration
- `Medley.addEntry(_:)` — assigns correct order value
- Never iterate `medley.entries` directly

### Duplication

`Medley.duplicate(in:)` creates a new `Medley` with name `"{name} (copy)"`, new `MedleyEntry` objects pointing to the same shared `Song` instances, preserving order.

---

## 3. Sidebar Navigation

The sidebar segmented control expands to three segments: **Setlists / Songs / Medleys**.

### Medleys section

- List of all medleys, sorted alphabetically by name
- Each row shows: medley name (primary) + song count (secondary, e.g. "5 songs")
- `+` button in header creates a new medley
- `···` menu on each row:
  - **Edit** — sheet with name text field
  - **Duplicate** — creates "{name} (copy)" with same songs in same order
  - **Delete** — destructive, confirmation alert listing affected setlists if any

---

## 4. Medley Detail View

When a medley is selected in the sidebar, the detail pane shows:

**Header:** Medley name as title, song count subtitle.

**Song list:**
- Drag-to-reorder rows
- Each row shows song title only (matching `SongSetlistRow` pattern)
- Swipe-to-delete removes song from medley (not from library)
- Tapping a song row opens the Song Editor sheet

**Add row:** "+ Add Song" — opens Song Library sheet.

**Toolbar:** "Perform" button — opens Performance Mode for just this medley's songs (useful for rehearsals).

**Empty state:** When no songs added yet: *"A medley is a fixed group of songs played in order. Add songs to build your medley."*

---

## 5. Medleys in Setlist Detail View (Ordering Mode)

### Display

A medley in a setlist appears as a grouped block:

- **Header row:** Medley name in primary text (e.g. "Rock 1")
- **Song rows:** Indented or visually grouped beneath the header, each showing song title only
- The whole group (header + songs) **drags as one unit** for reordering
- Song order within the medley is **locked** — not individually draggable or removable in setlist context
- Tapping a song row opens the Song Editor (editing the shared song)

Visual grouping approach: start with **header + indented songs** (approach A). May iterate to a side bracket (B) or collapsed/expandable (C) based on real-device testing.

### Adding a medley to a setlist

The add row at the bottom of the setlist becomes three sections:
- **+ Add Song** → Song Library sheet (existing)
- **+ Add Medley** → Medley Library sheet (new — lists all medleys, tap to add)
- **+ Add Tacet** → Tacet edit sheet (existing)

### Medley Library sheet

- Lists all medleys with name + song count
- Tap to add to current setlist
- Medleys already in the setlist are dimmed with a checkmark (can still be added again)

---

## 6. Performance Mode

### Medley songs

Each song in a medley renders as a normal `SongPerformanceBlock` with one addition:

**Medley indicator:** A small label showing medley name + position, e.g. **"Rock 1 — 3/5"**. Uses `PerformanceTheme` tokens (new tokens to be added). Appears on every song that belongs to a medley. Standalone songs show no indicator.

### Medley-only perform mode

When performing from the Medley detail view, same rendering — medley's songs with position indicators.

---

## 7. Theme Additions

### `PerformanceTheme`

New tokens:
- `medleyIndicatorSize: CGFloat` — small, unobtrusive
- `medleyIndicatorColor: Color` — subtle, secondary

### `EditTheme`

New tokens:
- `medleyHeaderColor: Color` — for medley group headers in setlist view
- `medleyGroupBackground: Color` — subtle tint for grouped songs

---

## 8. Documentation Updates (Pre-Implementation)

Fix outdated information in CLAUDE.md and design spec:
- `SongSetlistRow` displays song title only (not reminder or first line preview)
- "Up next" label in Performance Mode has been removed
- Update view naming conventions to include Medley views

---

## 9. Out of Scope

- Tacets within medleys (medleys are songs only)
- Per-setlist overrides of medley song order
- Nested medleys (a medley containing another medley)
