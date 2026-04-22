import XCTest
@testable import LeadifyCore

final class SongContentParserTests: XCTestCase {

    // MARK: - Chord line detection

    func test_simpleChordLine_parsedAsChordLine() {
        let blocks = SongContentParser.parse("Am F C G")
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
        let blocks = SongContentParser.parse("Am F / C G")
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
        let blocks = SongContentParser.parse("Bm G D A (x4, building)")
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
        let blocks = SongContentParser.parse("Eb Bb / Cm Ab (x8)")
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
        let blocks = SongContentParser.parse("C#7 Bb F#m7 Eb")
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
        let blocks = SongContentParser.parse("Bmaj7 Cmaj7#5 Gsus4 Asus4")
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
        let blocks = SongContentParser.parse("Am/G D/F# BbM7/E")
        guard case .chordLine(let tokens) = blocks.first else {
            return XCTFail("Expected .chordLine")
        }
        XCTAssertEqual(tokens.count, 3)
        XCTAssertEqual(tokens[0], .chord("Am/G"))
        XCTAssertEqual(tokens[1], .chord("D/F#"))
        XCTAssertEqual(tokens[2], .chord("BbM7/E"))
    }

    func test_slashChordWithStandaloneDivider() {
        let blocks = SongContentParser.parse("Am/G D/F# / Em C")
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
        let blocks = SongContentParser.parse("Cdim7 Eaug Fdim")
        guard case .chordLine(let tokens) = blocks.first else {
            return XCTFail("Expected .chordLine")
        }
        XCTAssertEqual(tokens.count, 3)
        XCTAssertEqual(tokens[0], .chord("Cdim7"))
        XCTAssertEqual(tokens[1], .chord("Eaug"))
        XCTAssertEqual(tokens[2], .chord("Fdim"))
    }

    func test_addChords_detectedAsChords() {
        let blocks = SongContentParser.parse("Cadd9 Gadd11")
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
            let blocks = SongContentParser.parse(word)
            guard case .plainText = blocks.first else {
                return XCTFail("Expected .plainText for \"\(word)\", got \(String(describing: blocks.first))")
            }
        }
    }

    func test_parenthesizedText_isPlainText() {
        let blocks = SongContentParser.parse("(over Chorus chords x2)")
        guard case .plainText(let text) = blocks.first else {
            return XCTFail("Expected .plainText")
        }
        XCTAssertEqual(text, "(over Chorus chords x2)")
    }

    func test_standaloneStageDirection_isPlainText() {
        let blocks = SongContentParser.parse("(hold, fade)")
        guard case .plainText(let text) = blocks.first else {
            return XCTFail("Expected .plainText")
        }
        XCTAssertEqual(text, "(hold, fade)")
    }

    // MARK: - Edge cases

    func test_lineStartingWithSlash_isPlainText() {
        let blocks = SongContentParser.parse("/ Am G")
        guard case .plainText = blocks.first else {
            return XCTFail("Expected .plainText for line starting with /")
        }
    }

    func test_emptyContent_parsesToEmptyBlocks() {
        let blocks = SongContentParser.parse("")
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
        let blocks = SongContentParser.parse(input)
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
        let blocks = SongContentParser.parse("# Title\n## Section")
        guard case .heading1(let h1) = blocks[0] else { return XCTFail("Expected heading1") }
        XCTAssertEqual(h1, "Title")
        guard case .heading2(let h2) = blocks[1] else { return XCTFail("Expected heading2") }
        XCTAssertEqual(h2, "Section")
    }

    func test_codeBlocksStillWork() {
        let input = "```\ne|---0---|\n```"
        let blocks = SongContentParser.parse(input)
        guard case .codeBlock(let code, _) = blocks.first else { return XCTFail("Expected codeBlock") }
        XCTAssertEqual(code, "e|---0---|")
    }
}
