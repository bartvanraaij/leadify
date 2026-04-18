# Medley Display Mode

Per-medley setting that controls how a medley is presented and navigated in Performance mode.

## Display Modes

Two options, stored per `Medley`:

| Mode | Behavior |
|------|----------|
| **Combined** | Current behavior — medley renders as one block with all songs inside, navigated as a single item |
| **Separated** | Each song in the medley becomes its own performance item, displayed and navigated individually |

Default for new medleys: **Separated**.

## Data Model

Add to `Medley`:

```swift
enum MedleyDisplayMode: String, Codable, CaseIterable {
    case combined
    case separated
}
```

New property: `displayMode: MedleyDisplayMode` (default `.separated`).

## Performance Item Generation

In `Setlist`'s `Performable` conformance (`performanceItems`):

- **`.combined`**: Emit one `.medley` PerformanceItem (current behavior).
- **`.separated`**: Emit N `.song` PerformanceItems — one per `MedleyEntry` in sorted order. The first item carries `medleyTitle: String?` set to the medley's name; the rest have `medleyTitle == nil`.

`PerformanceItem` gains an optional `medleyTitle: String?` field (default `nil`).

Each separated song's stable ID is derived from the `MedleyEntry`'s `persistentModelID`, not the `SetlistEntry`'s, ensuring uniqueness when multiple songs come from the same medley.

## Performance View — Main Content

`SongPerformanceBlock` gains an optional `medleyTitle: String?` parameter. When set, it renders the medley name above the song title using existing `PerformanceTheme.medleyTitleSize` and `medleyIndicatorColor` styling — same visual treatment as the `MedleyPerformanceBlock` header.

`MedleyPerformanceBlock` adds horizontal divider lines between songs within the block — same style as the dividers between standalone songs (`PerformanceTheme.dividerColor`, 1pt height). This visually separates songs while keeping them grouped under the medley title.

`PerformanceView.itemView()` requires no changes — separated songs arrive as `.song` items and route through `SongPerformanceBlock` naturally.

## Performance Sidebar

- **`.combined`**: Current behavior — medley title with indented sub-songs, navigable as one unit.
- **`.separated`**: Each song appears as its own sidebar row. The first song has a small medley label above it (medley indicator color, smaller font). Remaining songs have no extra decoration.

## Navigation

No changes to `PerformanceNavigator`. Separated medley songs are regular `.song` PerformanceItems — next/prev navigation handles them like standalone songs.

## Edit UI

Add a `Picker` to `MedleyEditSheet`:

- **Separated** — "Each song is displayed and navigated individually" (default, shown first)
- **Combined** — "Displayed and navigated as one item"

Label: "Performance display".

## Scope Boundaries

- Edit mode (setlist detail, medley detail) is unaffected — medleys always show as grouped entries there.
- `Medley`'s own `Performable` conformance (medley-only rehearsal) is unaffected — rehearsing a medley directly always shows all songs as one sequence regardless of display mode. The display mode only applies when the medley appears inside a setlist's performance.

## Testing

Unit tests on `Setlist.performanceItems`:

- A setlist with a `.combined` medley emits one `.medley` item (existing behavior preserved).
- A setlist with a `.separated` medley emits N `.song` items with correct titles.
- The first separated song has `medleyTitle` set; the rest have `nil`.
- Item IDs are stable and unique across separated songs.
