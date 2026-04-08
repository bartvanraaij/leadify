# Chord Cell Rendering — Design Spec

**Date:** 2026-04-08  
**Status:** Approved  
**Scope:** Replace plain-text chord paragraphs with fixed-width chord cells in performance mode and editor preview.

## Problem

Song content is rendered as plain text paragraphs. Chords like "A" and "F#m7" have wildly different widths in proportional fonts, making chord lines hard to scan quickly on stage. Lines with and without bar-line separators (`/`) don't align vertically.

## Solution

Enhance `SongContentRenderer`'s parser to detect chord lines and tokenize them into structured segments. The view renders each segment in a fixed-width cell, giving all chords equal visual weight regardless of name length.

## Parser changes

### New types

```swift
enum ChordToken {
    case chord(String)       // "Am", "F#m7", "Bmaj7", "Cmaj7#5"
    case divider             // "/" bar-line separator
    case annotation(String)  // "(x2)", "(x4, building)", "(hold, fade)"
}
```

### New block type

Replace the current `.paragraph(String)` with:

- **`.chordLine([ChordToken])`** — a line whose first whitespace-separated token starts with `[A-G][b#]?`
- **`.plainText(String)`** — non-chord text (stage directions, annotations on their own line, etc.)

### Detection rule

Split line by whitespace. If the first token matches the full chord pattern → chord line. Otherwise → plain text.

**Chord regex:** `^[A-G][b#]?(?:(?:maj|M)\d*|min|m|aug|\+|dim|ø|sus[24]?|add\d+)?\d*(?:[b#+-]\d+)*(?:/[A-G][b#]?)?$`

This handles: roots (`A`), accidentals (`Bb`, `F#`), qualities (`m`, `maj`, `M`, `dim`, `aug`, `+`, `ø`, `sus2`, `sus4`), extensions (`7`, `9`, `11`, `13`), alterations (`#5`, `b9`, `#11`, multiple like `C7#9b5`), added tones (`add9`), and slash chords (`Am/G`, `D/F#`, `BbM7/E`). Rejects English words like "Dark", "Bridge", "End" that happen to start with A-G.

### Tokenization

For a chord line, split by whitespace and classify each token:
- Standalone `/` → `.divider` (only when the entire token is `/`, not when `/` appears inside a chord like `Am/G`)
- Token starting with `(` → `.annotation` (collect this and all remaining tokens as the annotation string)
- Everything else → `.chord` (including slash chords like `D/F#`, `BbM7/E`)

Each line in a paragraph is evaluated independently.

### Examples

| Input line | Parsed as |
|---|---|
| `Am F / C G` | `.chordLine([.chord("Am"), .chord("F"), .divider, .chord("C"), .chord("G")])` |
| `Bm G D A (x4, building)` | `.chordLine([.chord("Bm"), .chord("G"), .chord("D"), .chord("A"), .annotation("(x4, building)")])` |
| `(over Chorus chords x2)` | `.plainText("(over Chorus chords x2)")` |
| `(hold, fade)` | `.plainText("(hold, fade)")` |

## View rendering

### Chord line layout

An `HStack`-style layout (flex wrap) of fixed-width cells:

- **Chord cell:** `PerformanceTheme.chordCellWidth` (88pt), left-aligned, 28px semibold (`chordTextSize`). Chords longer than 5 characters use `.minimumScaleFactor` to auto-shrink within the cell.
- **Divider cell:** Same width as chord cells (88pt) for vertical alignment. `/` centered horizontally, dimmed color (`PerformanceTheme.dividerColor`), normal weight.
- **Annotation:** No fixed width. Rendered inline after the last cell with a small left margin. Dimmed color (`PerformanceTheme.annotationColor`), smaller size (`PerformanceTheme.annotationSize`, ~22px).
- **Line height:** ~2.0 relative for vertical breathing room between lines.

### Plain text

Rendered as today: full-width text at `chordTextSize`, semibold, `chordTextColor`.

### Other block types

H1, H2, and code blocks are unchanged.

## Theme additions

New constants in `PerformanceTheme`:

| Constant | Value | Purpose |
|---|---|---|
| `chordCellWidth` | 88 | Fixed width for chord and divider cells |
| `annotationSize` | 22 | Font size for inline annotations |
| `annotationColor` | Dimmed gray (light/dark adaptive) | Color for annotations |
| `chordLineSpacing` | ~2.0 (relative) | Vertical breathing room between chord lines |

The existing `dividerColor` in `PerformanceTheme` is for horizontal lines between songs — not suitable for `/` text. Add a dedicated `chordDividerColor` for the dimmed slash text color.

## Scope

- **In scope:** Parser enhancement, chord cell view rendering, theme constants, unit tests for parser.
- **Out of scope:** Font size scaling feature (future work — current approach is compatible), ABC notation blocks, changes to song editor input format.
- **No file changes needed** in SongPerformanceBlock, SongEditorSheet, SongEditorDetailView, SongDisplayView — they all use `SongContentRenderer` which gets the update internally.

## Testing

Unit tests for the parser (no SwiftUI):

- Chord line detection: line starting with chord → `.chordLine`
- Token classification: chords, dividers, annotations correctly identified
- Mixed line: `Am F / C G (x2)` → correct token array
- Non-chord line: `(over Chorus chords x2)` → `.plainText`
- Edge cases: line starting with `/`, standalone annotation line, empty lines
- Long chords: `Cmaj7#5` parsed as `.chord` (shrinking is view concern)
- All sharps/flats: `C#7`, `Bb`, `Eb`, `F#m7` detected as chords
- Slash chords: `Am/G`, `D/F#`, `BbM7/E` → `.chord` (the `/` inside is part of the chord, not a divider)
- Standalone `/` between chords → `.divider`; `/` inside a token → part of chord
- English words rejected: `Dark`, `Bridge`, `End`, `Great`, `Feel` → `.plainText`, not chord lines
