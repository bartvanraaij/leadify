# Leadify

A native iPadOS app for guitarists performing live. Replaces the Google Docs + ForScore workflow with a purpose-built setlist manager and fullscreen performance display.

## What it does

**Edit mode** — manage your setlists before the gig:
- Create and name setlists with an optional date
- Build a setlist from your song library (songs are shared across setlists — edit once, updated everywhere)
- Add tacet entries (breaks, set changes) with an optional label
- Reorder entries with drag handles, delete by swiping left
- Tap any entry to edit it

**Performance mode** — on stage, fullscreen:
- Black background, no distractions, no status bar
- Songs rendered from Markdown: headings for sections, regular text for chords, monospace code blocks for tabs
- Tap the bottom edge to snap-scroll to the next entry; tap the top edge to scroll back
- "next: [song title]" label shows what's coming
- Triple-tap anywhere to exit

## Tech stack

- **SwiftUI** — all UI
- **SwiftData** — local persistence (iOS 17+)
- **MarkdownUI** — Markdown rendering in song editor preview and performance mode
- Minimum deployment target: **iOS 17.6**

## Project structure

```
Leadify/
├── Models/
│   ├── Song.swift           shared across setlists by reference
│   ├── Tacet.swift          break entries (owned, cascade-deleted)
│   ├── SetlistEntry.swift   join object: holds Song? or Tacet?, has explicit order: Int
│   └── Setlist.swift        sortedEntries, addEntry(), duplicate()
├── Theme/
│   ├── EditTheme.swift      all sizes + colors for edit/ordering mode
│   └── PerformanceTheme.swift  all sizes + colors for performance mode
└── Views/
    ├── Performance/         PerformanceView, PerformanceViewModel, SongBlock, TacetBlock
    ├── Sidebar/             setlist list, row, create/edit sheet
    └── Setlist/
        └── (ordering)       SetlistDetailView, SongEntryRow, TacetRow, AddEntryRow,
                             SongLibrarySheet, SongEditorSheet, TacetEditSheet
```

## Song format

Song content is Markdown:

```markdown
## Verse 1
Am  F  C  G

## Chorus
F  G  Am

```
tab riff here
```
```

- `##` headings → section labels (dimmed, small caps in performance mode)
- Regular paragraphs → chord text
- Fenced code blocks → monospace tab notation

## Building

Open `Leadify/Leadify.xcodeproj` in Xcode 16+. Select an iPad simulator (iOS 17.6+) and press **Cmd+R**.

Run tests with **Cmd+U**.

## Roadmap

- [ ] Fine-tune font sizes and layout after testing on real iPad hardware
- [ ] CloudKit sync (ModelContainer is set up to support it without migration)
- [ ] AirDrop / file import using canonical format: YAML frontmatter (title, reminder) + Markdown body
