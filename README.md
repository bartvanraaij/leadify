# Leadify

A native iPadOS app for guitarists performing live. Replaces the Google Docs + ForScore workflow with a purpose-built setlist manager and fullscreen performance display.

## What it does

**Edit mode** — manage your setlists before the gig:
- Create and name setlists with an optional date
- Build a setlist from your song library (songs are shared across setlists — edit once, updated everywhere)
- Add tacet entries (breaks, set changes) with an optional label
- Create medleys — fixed groups of songs played back-to-back, shared across setlists like songs
- Reorder entries with drag handles, delete by swiping left
- Tap any entry to edit it
- Import songs from Markdown files

**Performance mode** — on stage, fullscreen:
- Dark background, no distractions, no status bar
- Songs rendered from Markdown: headings for sections, regular text for chords, monospace code blocks for tabs
- Active entry highlighted, upcoming entries dimmed
- Tap left/right zones to navigate between entries (tacets are skipped)
- Up/down chevron indicators for scrolling within tall entries
- Tap center zone to activate any visible entry
- Adaptive layout: when the app has enough width (full-screen iPad), a sidebar shows the full setlist with active-entry highlight, medley sub-songs, and tap-to-jump navigation
- Works for both setlists and medleys via the `Performable` protocol

## Tech stack

- **SwiftUI** — all UI
- **SwiftData** — local persistence
- **MarkdownUI** — Markdown rendering in song editor preview and performance mode
- Minimum deployment target: **iOS 26**

## Project structure

```
Leadify/
├── Models/
│   ├── Song.swift             shared across setlists by reference
│   ├── Tacet.swift            break entries (owned, cascade-deleted)
│   ├── SetlistEntry.swift     join object: holds Song?, Tacet?, or Medley?
│   ├── Setlist.swift          sortedEntries, addEntry(), duplicate()
│   ├── Medley.swift           fixed group of songs, shared by reference
│   ├── MedleyEntry.swift      join object with Song reference and order
│   ├── Performable.swift      protocol + PerformanceItem for shared performance UI
│   ├── MarkdownSongParser.swift  parses markdown files into Song objects
│   └── SongImporter.swift     bulk import songs from markdown files
├── Theme/
│   ├── EditTheme.swift        all sizes + colors for edit/ordering mode
│   ├── PerformanceTheme.swift all sizes + colors for performance mode
│   └── MarkdownTheme.swift    custom MarkdownUI theme for performance rendering
└── Views/                     domain-based grouping
    ├── Song/                  display, editor, library views
    ├── Tacet/                 tacet editing
    ├── Setlist/               detail, sidebar, row components
    ├── Medley/                detail, sidebar, editing, song library
    └── Performance/           fullscreen performance mode, tap overlay, sidebar
```

## Song format

Song content is Markdown:

```markdown
## Verse 1
Am  F  C  G

## Chorus
F  G  Am

```
e|----------------------------------------|
B|----------------------------------------|
G|----------------------------------------|
D|----------------------------------------|
A|--16-14-14-14--x4------12-11-11-11--x4--|
E|-0--0--0--0-----------9--9--9--9--------|
```
```

- `##` headings → section labels (dimmed, small caps in performance mode)
- Regular paragraphs → chord text
- Fenced code blocks → monospace tab notation

## Building

Open `Leadify.xcodeproj` in Xcode 26+. Select an iPad simulator (iOS 26+) and press **Cmd+R**.

Run tests with **Cmd+U**.

## Roadmap

- [ ] CloudKit sync (ModelContainer is set up to support it without migration)
- [ ] Font size / layout tuning after testing on real hardware
