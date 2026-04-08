# Chord Cell Rendering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace plain-text chord paragraphs with fixed-width chord cells for easier on-stage reading.

**Architecture:** Enhance `SongContentRenderer`'s parser to detect chord lines via regex and tokenize them into `ChordToken` segments. The view renders each token in a fixed-width cell. All new constants go in `PerformanceTheme`.

**Tech Stack:** SwiftUI, XCTest

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `Leadify/Theme/PerformanceTheme.swift` | Modify | Add chord cell constants |
| `Leadify/Views/Song/SongContentRenderer.swift` | Modify | New types, parser logic, chord line view |
| `Tests/UnitTests/SongContentRendererTests.swift` | Create | Parser unit tests |

---

### Task 1: Add theme constants

**Files:**
- Modify: `Leadify/Theme/PerformanceTheme.swift`

- [ ] **Step 1: Add chord cell constants to PerformanceTheme**

Add these after the existing `tabTracking` constant (line 13):

```swift
    // MARK: Chord cell layout
    static let chordCellWidth: CGFloat = 88
    static let annotationSize: CGFloat = 22
    static let chordLineSpacing: CGFloat = 2.0
    static let chordDividerColor = Color(light: Color(white: 0.7), dark: Color(white: 0.4))
    static let annotationColor = Color(light: Color(white: 0.55), dark: Color(white: 0.5))
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -scheme Leadify -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' 2>&1 | tail -5`

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Leadify/Theme/PerformanceTheme.swift
git commit -m "feat: add chord cell theme constants"
```

---

### Task 2: Write parser tests

**Files:**
- Create: `Tests/UnitTests/SongContentRendererTests.swift`

- [ ] **Step 1: Write all parser tests**

Create `Tests/UnitTests/SongContentRendererTests.swift`:

```swift
import XCTest
@testable import Leadify

final class SongContentRendererTests: XCTestCase {

    // MARK: - Chord line detection

    func test_simpleChordLine_parsedAsChordLine() {
        let blocks = SongContentRenderer.parse("Am F C G")
        guard case .chordLine(let tokens) = blocks.first else {
            return XCTFail("Expected .chordLine, got \(String(describing: blocks.first))")
        }
        XCTAssertEqual(tokens.count, 4)
        XCTAssertEqual(tokens[0], .chord("Am"))
        XCTAssertEqual(tokens[1], .chord("F"))
        XCTAssertEqual(tokens[2], .chord("C"))
        XCTAssertEqual(tokens[3], .chord("G"))
    }

    func test_chordLineWithDivider_parsedCorrectly() {
        let blocks = SongContentRenderer.parse("Am F / C G")
        guard case .chordLine(let tokens) = blocks.first else {
            return XCTFail("Expected .chordLine")
        }
        XCTAssertEqual(tokens.count, 5)
        XCTAssertEqual(tokens[0], .chord("Am"))
        XCTAssertEqual(tokens[1], .chord("F"))
        XCTAssertEqual(tokens[2], .divider)
        XCTAssertEqual(tokens[3], .chord("C"))
        XCTAssertEqual(tokens[4], .chord("G"))
    }

    func test_chordLineWithAnnotation_parsedCorrectly() {
        let blocks = SongContentRenderer.parse("Bm G D A (x4, building)")
        guard case .chordLine(let tokens) = blocks.first else {
            return XCTFail("Expected .chordLine")
        }
        XCTAssertEqual(tokens.count, 5)
        XCTAssertEqual(tokens[0], .chord("Bm"))
        XCTAssertEqual(tokens[1], .chord("G"))
        XCTAssertEqual(tokens[2], .chord("D"))
        XCTAssertEqual(tokens[3], .chord("A"))
        XCTAssertEqual(tokens[4], .annotation("(x4, building)"))
    }

    func test_chordLineWithDividerAndAnnotation() {
        let blocks = SongContentRenderer.parse("Eb Bb / Cm Ab (x8)")
        guard case .chordLine(let tokens) = blocks.first else {
            return XCTFail("Expected .chordLine")
        }
        XCTAssertEqual(tokens.count, 6)
        XCTAssertEqual(tokens[0], .chord("Eb"))
        XCTAssertEqual(tokens[1], .chord("Bb"))
        XCTAssertEqual(tokens[2], .divider)
        XCTAssertEqual(tokens[3], .chord("Cm"))
        XCTAssertEqual(tokens[4], .chord("Ab"))
        XCTAssertEqual(tokens[5], .annotation("(x8)"))
    }

    // MARK: - Chord varieties

    func test_sharpsAndFlats_detectedAsChords() {
        let blocks = SongContentRenderer.parse("C#7 Bb F#m7 Eb")
        guard case .chordLine(let tokens) = blocks.first else {
            return XCTFail("Expected .chordLine")
        }
        XCTAssertEqual(tokens.count, 4)
        XCTAssertEqual(tokens[0], .chord("C#7"))
        XCTAssertEqual(tokens[1], .chord("Bb"))
        XCTAssertEqual(tokens[2], .chord("F#m7"))
        XCTAssertEqual(tokens[3], .chord("Eb"))
    }

    func test_longChords_detectedAsChords() {
        let blocks = SongContentRenderer.parse("Bmaj7 Cmaj7#5 Gsus4 Asus4")
        guard case .chordLine(let tokens) = blocks.first else {
            return XCTFail("Expected .chordLine")
        }
        XCTAssertEqual(tokens.count, 4)
        XCTAssertEqual(tokens[0], .chord("Bmaj7"))
        XCTAssertEqual(tokens[1], .chord("Cmaj7#5"))
        XCTAssertEqual(tokens[2], .chord("Gsus4"))
        XCTAssertEqual(tokens[3], .chord("Asus4"))
    }

    func test_slashChords_detectedAsChords() {
        let blocks = SongContentRenderer.parse("Am/G D/F# BbM7/E")
        guard case .chordLine(let tokens) = blocks.first else {
            return XCTFail("Expected .chordLine")
        }
        XCTAssertEqual(tokens.count, 3)
        XCTAssertEqual(tokens[0], .chord("Am/G"))
        XCTAssertEqual(tokens[1], .chord("D/F#"))
        XCTAssertEqual(tokens[2], .chord("BbM7/E"))
    }

    func test_slashChordWithStandaloneDivider() {
        let blocks = SongContentRenderer.parse("Am/G D/F# / Em C")
        guard case .chordLine(let tokens) = blocks.first else {
            return XCTFail("Expected .chordLine")
        }
        XCTAssertEqual(tokens.count, 5)
        XCTAssertEqual(tokens[0], .chord("Am/G"))
        XCTAssertEqual(tokens[1], .chord("D/F#"))
        XCTAssertEqual(tokens[2], .divider)
        XCTAssertEqual(tokens[3], .chord("Em"))
        XCTAssertEqual(tokens[4], .chord("C"))
    }

    func test_augmentedAndDiminished_detectedAsChords() {
        let blocks = SongContentRenderer.parse("Cdim7 Eaug Fdim")
        guard case .chordLine(let tokens) = blocks.first else {
            return XCTFail("Expected .chordLine")
        }
        XCTAssertEqual(tokens.count, 3)
        XCTAssertEqual(tokens[0], .chord("Cdim7"))
        XCTAssertEqual(tokens[1], .chord("Eaug"))
        XCTAssertEqual(tokens[2], .chord("Fdim"))
    }

    func test_addChords_detectedAsChords() {
        let blocks = SongContentRenderer.parse("Cadd9 Gadd11")
        guard case .chordLine(let tokens) = blocks.first else {
            return XCTFail("Expected .chordLine")
        }
        XCTAssertEqual(tokens.count, 2)
        XCTAssertEqual(tokens[0], .chord("Cadd9"))
        XCTAssertEqual(tokens[1], .chord("Gadd11"))
    }

    // MARK: - Plain text detection

    func test_englishWords_notDetectedAsChords() {
        for word in ["Dark night", "Bridge section", "End of song", "Great finale", "Feel the beat"] {
            let blocks = SongContentRenderer.parse(word)
            guard case .plainText = blocks.first else {
                return XCTFail("Expected .plainText for \"\(word)\", got \(String(describing: blocks.first))")
            }
        }
    }

    func test_parenthesizedText_isPlainText() {
        let blocks = SongContentRenderer.parse("(over Chorus chords x2)")
        guard case .plainText(let text) = blocks.first else {
            return XCTFail("Expected .plainText")
        }
        XCTAssertEqual(text, "(over Chorus chords x2)")
    }

    func test_standaloneStagDirection_isPlainText() {
        let blocks = SongContentRenderer.parse("(hold, fade)")
        guard case .plainText(let text) = blocks.first else {
            return XCTFail("Expected .plainText")
        }
        XCTAssertEqual(text, "(hold, fade)")
    }

    // MARK: - Edge cases

    func test_lineStartingWithSlash_isPlainText() {
        let blocks = SongContentRenderer.parse("/ Am G")
        guard case .plainText = blocks.first else {
            return XCTFail("Expected .plainText for line starting with /")
        }
    }

    func test_emptyContent_parsesToEmptyBlocks() {
        let blocks = SongContentRenderer.parse("")
        XCTAssertTrue(blocks.isEmpty)
    }

    // MARK: - Mixed content

    func test_mixedContentPreservesBlockOrder() {
        let input = """
        ## Verse
        Am F / C G
        (x2)
        ## Chorus
        C G / Am F
        """
        let blocks = SongContentRenderer.parse(input)
        XCTAssertEqual(blocks.count, 5)

        guard case .heading2(let h) = blocks[0] else { return XCTFail("Expected heading2") }
        XCTAssertEqual(h, "Verse")

        guard case .chordLine(let tokens1) = blocks[1] else { return XCTFail("Expected chordLine") }
        XCTAssertEqual(tokens1.count, 5)

        guard case .plainText(let text) = blocks[2] else { return XCTFail("Expected plainText") }
        XCTAssertEqual(text, "(x2)")

        guard case .heading2(let h2) = blocks[3] else { return XCTFail("Expected heading2") }
        XCTAssertEqual(h2, "Chorus")

        guard case .chordLine(let tokens2) = blocks[4] else { return XCTFail("Expected chordLine") }
        XCTAssertEqual(tokens2.count, 5)
    }

    // MARK: - Existing block types still work

    func test_headingsStillWork() {
        let blocks = SongContentRenderer.parse("# Title\n## Section")
        guard case .heading1(let h1) = blocks[0] else { return XCTFail("Expected heading1") }
        XCTAssertEqual(h1, "Title")
        guard case .heading2(let h2) = blocks[1] else { return XCTFail("Expected heading2") }
        XCTAssertEqual(h2, "Section")
    }

    func test_codeBlocksStillWork() {
        let input = "```\ne|---0---|\n```"
        let blocks = SongContentRenderer.parse(input)
        guard case .codeBlock(let code, _) = blocks.first else { return XCTFail("Expected codeBlock") }
        XCTAssertEqual(code, "e|---0---|")
    }
}
```

- [ ] **Step 2: Add test file to Xcode project exception lists**

The test file needs to be added to both exception lists in `Leadify.xcodeproj/project.pbxproj` (synchronized folder exclusions). Find the two `PBXFileSystemSynchronizedBuildFileExceptionSet` sections and add `UnitTests/SongContentRendererTests.swift` to each `membershipExceptions` array, in alphabetical order (after `UnitTests/SetlistTests.swift`).

- [ ] **Step 3: Run tests to verify they fail**

Run: `xcodebuild test -scheme Leadify -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' -only-testing:LeadifyTests/SongContentRendererTests 2>&1 | tail -20`

Expected: Build errors — `ChordToken` type doesn't exist yet, `.chordLine` and `.plainText` cases don't exist.

- [ ] **Step 4: Commit test file**

```bash
git add Tests/UnitTests/SongContentRendererTests.swift Leadify.xcodeproj/project.pbxproj
git commit -m "test: add SongContentRenderer parser tests (red)"
```

---

### Task 3: Implement parser changes

**Files:**
- Modify: `Leadify/Views/Song/SongContentRenderer.swift`

- [ ] **Step 1: Add ChordToken enum and Equatable conformance**

Add inside the `extension SongContentRenderer` block (after the `ContentBlock` enum, before the `parse` function):

```swift
    /// A token within a chord line.
    enum ChordToken: Equatable {
        case chord(String)
        case divider
        case annotation(String)
    }

    /// Regex matching a valid chord name.
    /// Roots (A-G), accidentals (b/#), qualities (m/maj/M/dim/aug/+/ø/sus/add/min),
    /// extensions (7/9/11/13), alterations (#5/b9), slash chords (Am/G, D/F#).
    private static let chordPattern = try! NSRegularExpression(
        pattern: #"^[A-G][b#]?(?:(?:maj|M)\d*|min|m|aug|\+|dim|ø|sus[24]?|add\d+)?\d*(?:[b#+-]\d+)*(?:/[A-G][b#]?)?$"#
    )

    /// Returns true if the token is a valid chord name.
    static func isChord(_ token: String) -> Bool {
        let range = NSRange(token.startIndex..., in: token)
        return chordPattern.firstMatch(in: token, range: range) != nil
    }

    /// Tokenize a chord line string into ChordTokens.
    static func tokenizeChordLine(_ line: String) -> [ChordToken] {
        let parts = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        var tokens: [ChordToken] = []

        for (index, part) in parts.enumerated() {
            if part.hasPrefix("(") {
                // Collect this and all remaining parts as the annotation
                let annotationText = parts[index...].joined(separator: " ")
                tokens.append(.annotation(annotationText))
                break
            } else if part == "/" {
                tokens.append(.divider)
            } else {
                tokens.append(.chord(part))
            }
        }

        return tokens
    }
```

- [ ] **Step 2: Update ContentBlock enum**

Replace the existing `.paragraph(String)` case with two new cases:

```swift
    enum ContentBlock {
        case heading1(String)
        case heading2(String)
        case chordLine([ChordToken])
        case plainText(String)
        /// Fenced code block with content and optional language hint (e.g. "abc").
        case codeBlock(String, language: String?)
    }
```

- [ ] **Step 3: Update the parse function**

Replace the paragraph-collection block at the end of the `while` loop (the section starting with `// Paragraph — collect consecutive...` through the closing `}` of that block) with:

```swift
            // Paragraph — each line evaluated independently as chord line or plain text
            var paraLines: [String] = []
            while index < lines.count {
                let l = lines[index]
                if l.trimmingCharacters(in: .whitespaces).isEmpty
                    || l.hasPrefix("# ")
                    || l.hasPrefix("## ")
                    || l.hasPrefix("```") {
                    break
                }
                paraLines.append(l)
                index += 1
            }
            for line in paraLines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let firstToken = trimmed.split(separator: " ", maxSplits: 1).first.map(String.init) ?? ""
                if isChord(firstToken) {
                    blocks.append(.chordLine(tokenizeChordLine(trimmed)))
                } else {
                    blocks.append(.plainText(trimmed))
                }
            }
```

- [ ] **Step 4: Update the view's blockView function**

Replace the `.paragraph` case with the two new cases:

```swift
        case .chordLine(let tokens):
            chordLineView(tokens)

        case .plainText(let text):
            Text(text)
                .font(.system(size: PerformanceTheme.chordTextSize, weight: .semibold))
                .foregroundStyle(PerformanceTheme.chordTextColor)
```

- [ ] **Step 5: Add the chordLineView function**

Add this new function after `blockView`:

```swift
    @ViewBuilder
    private func chordLineView(_ tokens: [ChordToken]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                switch token {
                case .chord(let name):
                    Text(name)
                        .font(.system(size: PerformanceTheme.chordTextSize, weight: .semibold))
                        .foregroundStyle(PerformanceTheme.chordTextColor)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .frame(width: PerformanceTheme.chordCellWidth, alignment: .leading)

                case .divider:
                    Text("/")
                        .font(.system(size: PerformanceTheme.chordTextSize, weight: .regular))
                        .foregroundStyle(PerformanceTheme.chordDividerColor)
                        .frame(width: PerformanceTheme.chordCellWidth, alignment: .center)

                case .annotation(let text):
                    Text(text)
                        .font(.system(size: PerformanceTheme.annotationSize, weight: .regular))
                        .foregroundStyle(PerformanceTheme.annotationColor)
                        .padding(.leading, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: PerformanceTheme.chordTextSize * PerformanceTheme.chordLineSpacing)
    }
```

- [ ] **Step 6: Run tests**

Run: `xcodebuild test -scheme Leadify -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' -only-testing:LeadifyTests/SongContentRendererTests 2>&1 | tail -30`

Expected: All tests pass.

- [ ] **Step 7: Run all unit tests to check for regressions**

Run: `xcodebuild test -scheme Leadify -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' -only-testing:LeadifyTests 2>&1 | tail -30`

Expected: All tests pass (including existing SongFileParser, SongImporter, Setlist, Song, Medley, PerformanceNavigation, PerformanceScrollCalculator tests).

- [ ] **Step 8: Commit**

```bash
git add Leadify/Views/Song/SongContentRenderer.swift
git commit -m "feat: chord cell rendering with fixed-width cells"
```

---

### Task 4: Update test data and visual verification

**Files:**
- Modify: `Leadify/UITestSeeder.swift`

- [ ] **Step 1: Add a song with varied chord types to UITestSeeder**

Add after the existing `veryLongContent` variable (line 196) in `UITestSeeder.swift`:

```swift
        let chordVarietyContent = """
        ## Verse
        A Bm / C#7 F#m7
        G Em / D A
        G Em D A (x2)

        ## Pre-chorus
        Dm7 Gsus4 / Bb F
        Eb Cm / Ab Fm

        ## Bridge
        F#m G A Asus4 A
        Bmaj7 Cmaj7#5 / D E

        ## Outro
        Am/G D/F# / Em C (x4, building)
        (hold, fade)
        """
```

Add this song to the `songs` array (before the closing `]`):

```swift
            Song(title: "Chord Variety Test", content: chordVarietyContent, reminder: "All chord types"),
```

- [ ] **Step 2: Build and install on simulator**

Run:
```bash
xcodebuild build -scheme Leadify -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

Then install and launch (if simulator is booted):
```bash
xcrun simctl terminate B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5 dev.bartvanraaij.leadify 2>/dev/null
xcrun simctl install B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5 ~/Library/Developer/Xcode/DerivedData/Leadify-dcfskxmsfskcybdoxvrgstsbknvm/Build/Products/Debug-iphonesimulator/Leadify.app
xcrun simctl launch B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5 dev.bartvanraaij.leadify
```

- [ ] **Step 3: Pause for user to verify in simulator**

User should verify:
- Chord cells are evenly spaced at 88pt width
- Dividers (`/`) are centered and dimmed
- Annotations like `(x2)` are inline, smaller, and dimmed
- Long chords like `Cmaj7#5` auto-shrink within their cell
- Slash chords like `Am/G` render as single chord cells
- Plain text like `(hold, fade)` renders normally
- Section headers (`## Verse`) unchanged
- Editor preview matches performance mode

- [ ] **Step 4: Commit**

```bash
git add Leadify/UITestSeeder.swift
git commit -m "test: add chord variety test song to UITestSeeder"
```

---

### Task 5: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update CLAUDE.md**

In the project layout section, add `SongContentRendererTests` to the UnitTests listing (after `SongFileParserTests`).

In the "Current status" section under "Done", add:
```
- Chord cell rendering: fixed-width chord cells in performance mode with auto-shrink for long chords, divider/annotation support ✅
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md with chord cell rendering"
```
