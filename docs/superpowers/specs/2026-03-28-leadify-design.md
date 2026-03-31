# Leadify — Design Spec

**Date:** 2026-03-28
**Platform:** iPadOS 17+
**Purpose:** Live setlist management app for a guitarist in a cover band. Replaces Google Docs + PDF + ForScore workflow.

---

## 1. Core Concepts

### Song
A song is a shared library entity. Editing a song propagates changes to every setlist that references it.

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `title` | String | Displayed prominently everywhere |
| `content` | String | Markdown — see §5 for format |
| `reminder` | String? | Free text, e.g. "Capo 4", "Fuzz", "Tsw +1". Shown in reminder color. |

### Tacet
A tacet is a non-song setlist item with an optional label. (From music notation: *tacet* = "be silent".)

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `label` | String? | e.g. "15 min", "Setlist 2". Shown dimmed/italic. |

### SetlistEntry
An ordered item in a setlist. Exactly one of `song` or `tacet` is non-nil.

| Field | Type | Notes |
|---|---|---|
| `song` | Song? | Non-nil if this is a song entry |
| `tacet` | Tacet? | Non-nil if this is a tacet entry |

A computed property `var itemType: ItemType` (enum: `.song`, `.tacet`) derived from which optional is set makes intent explicit throughout the codebase. New item types (e.g. `.tuning`, `.note`) are added by extending the enum and adding a corresponding optional relationship.

### Setlist
An ordered list of entries for a specific gig.

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `name` | String | e.g. "Kermis Arcen" |
| `date` | Date? | Optional. Displayed in `dd-MM-yyyy` NL format below the name. |
| `entries` | [SetlistEntry] | Ordered array. Array order is display order — no position field. |

---

## 2. Data Model Relationships

```
Setlist ──[cascade delete]──▶ SetlistEntry[]          (ordered array, owns entries)
SetlistEntry ───────────────▶ Song?                   (shared, no cascade)
SetlistEntry ──[cascade delete]──▶ tacet: Tacet?       (owned by entry)
```

**Duplicate setlist:** Creates a new `Setlist` with new `SetlistEntry` objects. Song entries point to the same shared `Song` instances (edits propagate to both setlists). Tacet entries are deep-copied — each duplicated `SetlistEntry` gets a new `Tacet` instance with the same label — because `Tacet` is owned by its entry and would be destroyed if the original setlist were deleted.

**Delete song from library:** Removes the `Song` and its `SetlistEntry` references across all setlists. Requires a confirmation alert listing affected setlists.

---

## 3. Persistence — SwiftData

- Use `@Model` on `Song`, `Tacet`, `SetlistEntry`, `Setlist`.
- Configure `ModelContainer` with `cloudKitDatabase: .automatic` (not `.none`) even though sync is not enabled in v1. This keeps the CloudKit sync path open without a migration later.
- Store in the default app container (no custom location needed for v1).

---

## 4. App Architecture

**Pattern:** MVVM with `@Observable` (iOS 17 Observation framework). No ObservableObject.

**Navigation:** `NavigationSplitView`
- **Sidebar (left):** List of all `Setlist`s, sorted by date descending (undated at bottom). Each row shows name + date. A `···` button opens a context menu per setlist.
- **Detail (right):** Active setlist in either Ordering Mode or Performance Mode.

**Mode toggle:** A single **▶ Perform** button in the detail toolbar enters Performance Mode via `.fullScreenCover`. Triple-tap anywhere exits Performance Mode.

---

## 5. Song Content Format

Songs use a Markdown subset:

```markdown
## Section Name
Chord text on plain lines

```
e|--0--2--|
B|--3-----|
```
```

- `##` headings → section headers (Couplet, Refrein, Intro, Bridge, etc.)
- Plain text → chord lines
- Triple-backtick code blocks → monospace guitar tabs

The song `title` and `reminder` are separate model fields, not part of the Markdown content.

### Canonical file format (for future AirDrop / import)

```
---
title: Sweet Home Alabama
reminder: Capo 4
---
## Intro
D A Bm G | D A G

## Couplet
D A Bm G
```

YAML frontmatter carries `title` and optional `reminder`. Body is the Markdown content. File extension: `.md`.

---

## 6. Design Tokens

All font sizes and colors are defined as `static let` constants in two structs. Views never use magic numbers or raw hex values — they always reference a token by name.

### `PerformanceTheme` — performance mode

```swift
struct PerformanceTheme {
    // Font sizes
    static let songTitleSize: CGFloat       // large, bold — most prominent element on screen
    static let reminderSize: CGFloat        // slightly smaller than title
    static let sectionHeaderSize: CGFloat   // smaller than chord text, uppercase label feel
    static let chordTextSize: CGFloat       // primary reading size for chord lines
    static let tabFontSize: CGFloat         // same as chordTextSize, monospace
    static let upNextSize: CGFloat          // small, unobtrusive corner label

    // Colors
    static let background: Color            // pure black
    static let songTitleColor: Color        // pure white
    static let chordTextColor: Color        // slightly off-white, easy on the eyes
    static let sectionHeaderColor: Color    // mid-grey, clearly secondary
    static let reminderColor: Color         // iOS system orange — stands out without being harsh
    static let tabColor: Color              // soft green — visually distinct from chords
    static let tacetTextColor: Color         // dimmed, clearly not a song
    static let upNextColor: Color           // subtle, corner of screen
}
```

### `EditTheme` — ordering mode and editor

```swift
struct EditTheme {
    // Font sizes
    static let setlistNameSize: CGFloat     // primary label in sidebar rows
    static let setlistDateSize: CGFloat     // smaller, below setlist name
    static let songTitleSize: CGFloat       // primary label in song rows
    static let songPreviewSize: CGFloat     // smaller, preview of first content line
    static let reminderSize: CGFloat        // same level as song title, inline
    static let editorTitleSize: CGFloat     // large, bold — the title field in the song editor

    // Colors
    static let background: Color            // dark system background
    static let primaryText: Color           // white — titles, names
    static let secondaryText: Color         // lighter grey — dates, previews, counts
    static let reminderColor: Color         // same orange as PerformanceTheme
    static let tacetText: Color              // dimmed — clearly not a song row
    static let accentColor: Color           // iOS system blue — buttons, active states
    static let destructiveColor: Color      // iOS system red — delete actions
}
```

**Starting values** are set during implementation based on what reads well on the actual device. Adjusting the entire app's visual style is a matter of changing values in these two structs.

---

## 7. Ordering Mode (Edit Mode)

**Layout:** `NavigationSplitView` — sidebar + detail pane.

**Sidebar — setlist list:**
- Each row: name (primary text, larger) + date in `dd-MM-yyyy` format (secondary text, smaller). Undated shows a dimmed "no date" placeholder.
- `+` button in header creates a new setlist.
- `···` button on each row opens a popover menu:
  - **Edit** — sheet with title text field + optional date picker
  - **Duplicate** — copies setlist. New entries point to the same `Song` instances; `Tacet` entries are deep-copied. New name: `"{name} (copy)"`.
  - **Delete** — destructive, requires confirmation alert.

**Detail pane — setlist contents:**
- Drag-to-reorder rows using SwiftUI `List` with `.onMove`.
- Each song row: drag handle (left) · title (primary) · edit pencil (right).
- Each tacet row: drag handle · italic dimmed label · edit pencil. Visually distinct with dashed border.
- **Inline add row at bottom** (dashed border, two tappable sections divided by a separator):
  - **+ Add Song** → opens Song Library sheet
  - **+ Add Tacet** → opens a small sheet to enter optional tacet label, appends tacet to list
- Toolbar: **▶ Perform** button only.

**Song Library sheet:**
- Search bar at top.
- All songs in library listed. Tap **+** to append to current setlist. Songs already in the setlist are dimmed with a checkmark (can still be added again if intentional).
- **+ New Song** button opens the Song Editor for a new song, which is added to both the library and the current setlist on save.

**Song Editor sheet:**
- Fields: **Title** (large, bold), **Reminder** (reminder color, optional), **Content** (Markdown text area).
- Edit/Preview toggle above the content area. Preview renders using the same visual style as Performance Mode.
- Cancel / Save in the navigation bar.

---

## 8. Performance Mode

**Activation:** Tap **▶ Perform** in ordering mode toolbar → `.fullScreenCover`.
**Exit:** Triple-tap anywhere on screen.

**Layout:**
- `PerformanceTheme.background`, no chrome.
- Single vertically scrollable view of all setlist entries stacked.
- Invisible tap zones at top and bottom of screen for snap scrolling.
  - Tap bottom → scrolls so the first currently off-screen song appears at the top of the view.
  - Tap top → reverse.

**Song block:**
- Title: `songTitleSize`, bold, `songTitleColor`
- Reminder: `reminderSize`, `reminderColor` — shown directly below title if present
- Section headers (`##`): `sectionHeaderSize`, `sectionHeaderColor`, uppercase
- Chord text: `chordTextSize`, `chordTextColor`
- Tab (code block): `tabFontSize`, monospace (`SF Mono` / `Menlo`), `tabColor`

**Tacet block:**
- Centered, uppercase, italic, `tacetTextColor`
- Subtle top and bottom divider lines

---

## 9. Markdown Rendering

Use **swift-markdown-ui** (`MarkdownUI`) for rendering song content in both the Preview tab of the Song Editor and in Performance Mode. It handles `##` headers, plain text, and fenced code blocks correctly.

Apply a custom `MarkdownUI.Theme` driven entirely by `PerformanceTheme` — heading styles, body font, code font, and colors all reference the token struct. No values are duplicated.

---

## 10. Future: Mac Editing (not in v1)

Two paths, both unblocked by the current architecture:

**Path A — CloudKit sync:**
SwiftData's `ModelContainer` is already configured with `cloudKitDatabase: .automatic`. Enabling sync requires a CloudKit container in the app's entitlements and a companion macOS target (Mac Catalyst or native). No data migration needed.

**Path B — AirDrop / file import:**
Register the app as a handler for `.md` files (UTI: `public.markdown`) in `Info.plist`. On receiving a file, parse the YAML frontmatter + Markdown body (§5 canonical format) and upsert the song by title. The parser can be written independently of any UI work.

Both paths use the canonical `.md` file format defined in §5 as the interchange format.

---

## 11. Out of Scope (v1)

- Cloud sync / Mac editing
- Auto-scroll
- Music notation
- Networking or accounts
- Multiple simultaneous setlists open
