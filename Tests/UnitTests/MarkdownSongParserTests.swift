import XCTest
@testable import Leadify

final class MarkdownSongParserTests: XCTestCase {

    func test_parsesBasicSong() throws {
        let input = """
---
title: It's My Life
reminder: direct op Cm
---
## Couplet
Cm Cm Cm
"""
        let result = try MarkdownSongParser.parse(input)
        XCTAssertEqual(result.title, "It's My Life")
        XCTAssertEqual(result.reminder, "direct op Cm")
        XCTAssertTrue(result.content.contains("## Couplet"))
        XCTAssertTrue(result.content.contains("Cm Cm Cm"))
    }

    func test_parsesWithoutReminder() throws {
        let input = """
---
title: Du
---
## Intro
B F# B
"""
        let result = try MarkdownSongParser.parse(input)
        XCTAssertEqual(result.title, "Du")
        XCTAssertNil(result.reminder)
        XCTAssertTrue(result.content.contains("## Intro"))
    }

    func test_preservesCodeFences() throws {
        let input = """
---
title: Tab Song
---
## Intro

```
e|---------|
B|--2------|
```
"""
        let result = try MarkdownSongParser.parse(input)
        XCTAssertTrue(result.content.contains("```"))
        XCTAssertTrue(result.content.contains("e|---------|"))
    }

    func test_throwsOnMissingFrontmatter() {
        let input = "Just some text without frontmatter"
        XCTAssertThrowsError(try MarkdownSongParser.parse(input)) { error in
            XCTAssertTrue(error is MarkdownSongParser.ParseError)
        }
    }

    func test_throwsOnMissingTitle() {
        let input = """
---
reminder: some reminder
---
Body text
"""
        XCTAssertThrowsError(try MarkdownSongParser.parse(input)) { error in
            XCTAssertTrue(error is MarkdownSongParser.ParseError)
        }
    }

    func test_trimsLeadingAndTrailingWhitespace() throws {
        let input = """
---
title: Trimmed
---

## Section
Content

"""
        let result = try MarkdownSongParser.parse(input)
        XCTAssertFalse(result.content.hasPrefix("\n"))
        XCTAssertFalse(result.content.hasSuffix("\n"))
    }

    func test_handlesSpecialCharactersInTitle() throws {
        let input = """
---
title: Bohemian Rhapsody (Live) — 2024
---
Is this the real life?
"""
        let result = try MarkdownSongParser.parse(input)
        XCTAssertEqual(result.title, "Bohemian Rhapsody (Live) — 2024")
    }

    func test_handlesColonInValue() throws {
        let input = """
---
title: Song: The Remix
reminder: key: Cm
---
Body
"""
        let result = try MarkdownSongParser.parse(input)
        XCTAssertEqual(result.title, "Song: The Remix")
        XCTAssertEqual(result.reminder, "key: Cm")
    }
}
