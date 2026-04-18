import SwiftUI

/// Lightweight markdown renderer for song content.
/// Supports: `# H1`, `## H2`, paragraphs, and fenced code blocks (``` ... ```).
/// Replaces the external MarkdownUI dependency with a slim, extensible renderer.
struct SongContentRenderer: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(Self.parse(content).enumerated()), id: \.offset) {
                _,
                block in
                blockView(block)
                    //.border(Color.purple, width: 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Trim leading and trailing empty/whitespace-only lines from code block content.
    private func trimmedCodeLines(from text: String) -> [String] {
        var lines = text.components(separatedBy: .newlines)
        // Trim leading and trailing empty/whitespace-only lines to avoid alignment issues
        while let first = lines.first, first.trimmingCharacters(in: .whitespaces).isEmpty { 
            lines.removeFirst() 
        }
        while let last = lines.last, last.trimmingCharacters(in: .whitespaces).isEmpty { 
            lines.removeLast() 
        }
        if lines.isEmpty { 
            lines = [""] 
        }
        return lines
    }

    private static let gridCharacters: Set<Character> = ["─", "│", "┼", "┬", "┴", "├", "┤", "┌", "┐", "└", "┘", " "]

    private static func coloredTabLine(_ line: String) -> AttributedString {
        let chars = Array(line)
        let firstGridIndex = chars.firstIndex(where: { gridCharacters.contains($0) || $0 == "─" }) ?? 0
        var result = AttributedString()
        for (i, ch) in chars.enumerated() {
            var attr = AttributedString(String(ch))
            if i < firstGridIndex || gridCharacters.contains(ch) {
                attr.foregroundColor = PerformanceTheme.tabGridColor
            } else {
                attr.foregroundColor = PerformanceTheme.primaryContentColor
                attr.font = .custom("Menlo-Bold", size: PerformanceTheme.tabFontSize)
            }
            result.append(attr)
        }
        return result
    }

    private static func replaceBoxDrawingCharacters(_ lines: [String]) -> [String] {
        let grid = lines.map { Array($0) }
        let rowCount = grid.count
        let isTopRow = { (row: Int) in row == 0 }
        let isBottomRow = { (row: Int) in row == rowCount - 1 }

        func charAt(_ row: Int, _ col: Int) -> Character? {
            guard row >= 0, row < rowCount, col >= 0, col < grid[row].count else { return nil }
            return grid[row][col]
        }

        return grid.enumerated().map { row, chars in
            String(chars.enumerated().map { col, ch -> Character in
                switch ch {
                case "-":
                    return "─"
                case "|":
                    let hasLeft = charAt(row, col - 1) == "-"
                    let hasRight = charAt(row, col + 1) == "-"
                    let top = isTopRow(row)
                    let bottom = isBottomRow(row)

                    switch (hasLeft, hasRight, top, bottom) {
                    // Left/right fretboard edges — drop the vertical, show as space
                    case (false, true, _, _):          return " "
                    case (true, false, _, _):          return " "
                    // Interior (dash on both sides) — fret bar
                    case (true, true, true, _):        return "┬"
                    case (true, true, _, true):        return "┴"
                    case (true, true, false, false):   return "┼"
                    // Standalone vertical
                    default:                           return "│"
                    }
                default:
                    return ch
                }
            })
        }
    }

    @ViewBuilder
    private func blockView(_ block: ContentBlock) -> some View {
        switch block {
        case .heading1(let text):
            Text(text)
                .font(
                    .system(size: PerformanceTheme.songTitleSize, weight: .bold, design: .rounded)
                )
                .foregroundStyle(PerformanceTheme.songTitleColor)
                .lineSpacing(PerformanceTheme.songTitleSize * PerformanceTheme.headingLineSpacingFraction)
                .padding(.top, PerformanceTheme.songTitleSize * PerformanceTheme.headingTopPaddingFraction)
                .padding(.bottom, PerformanceTheme.songTitleSize * PerformanceTheme.headingBottomPaddingFraction)

        case .heading2(let text):
            Text(text.lowercased())
                .font(
                    .system(
                        size: PerformanceTheme.sectionHeaderSize,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .foregroundStyle(PerformanceTheme.sectionHeaderColor)
                .lineSpacing(PerformanceTheme.sectionHeaderSize * PerformanceTheme.headingLineSpacingFraction)
                .padding(.top, PerformanceTheme.sectionHeaderSize * PerformanceTheme.headingTopPaddingFraction)
                .padding(.bottom, PerformanceTheme.sectionHeaderSize * PerformanceTheme.headingBottomPaddingFraction)

        case .chordLine(let tokens):
            chordLineView(tokens)
                .padding(.leading, PerformanceTheme.contentIndent)

        case .plainText(let text):
            Text(text)
                .font(
                    .system(
                        size: PerformanceTheme.chordTextSize,
                        weight: .semibold
                    )
                )
                .foregroundStyle(PerformanceTheme.chordTextColor)
                .padding(.leading, PerformanceTheme.contentIndent)

        case .codeBlock(let text, _):
            let lines = Self.replaceBoxDrawingCharacters(trimmedCodeLines(from: text))

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(Self.coloredTabLine(line))
                        .font(
                            .custom("Menlo", size: PerformanceTheme.tabFontSize)
                        )
                }
            }
            .padding(.bottom, PerformanceTheme.codeBlockVerticalPadding)
            .padding(.leading, PerformanceTheme.contentIndent)
        }
    }

    @ViewBuilder
    private func chordLineView(_ tokens: [ChordToken]) -> some View {
        ChordFlowLayout(rowHeight: PerformanceTheme.chordRowHeight) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                switch token {
                case .chord(let name):
                    Text(name)
                        .font(
                            .system(
                                size: PerformanceTheme.chordTextSize,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(PerformanceTheme.chordTextColor)
                        .minimumScaleFactor(PerformanceTheme.chordMinimumScaleFactor)
                        .lineLimit(1)
                        .frame(
                            width: PerformanceTheme.chordCellWidth,
                            alignment: .leading
                        )

                case .divider:
                    Text("/")
                        .font(
                            .system(
                                size: PerformanceTheme.chordTextSize,
                                weight: .regular
                            )
                        )
                        .foregroundStyle(PerformanceTheme.chordDividerColor)
                        .frame(
                            width: PerformanceTheme.chordCellWidth,
                            alignment: .center
                        )

                case .annotation(let text):
                    Text(text)
                        .font(
                            .custom("Menlo-Bold", size: PerformanceTheme.annotationSize)
                        )
                        .foregroundStyle(PerformanceTheme.annotationColor)
                        .padding(.leading, PerformanceTheme.annotationLeadingPadding)
                        .padding(
                            .top,
                            PerformanceTheme.annotationBaselineOffset
                        )
                }
            }
        }
    }
}

// MARK: - Content blocks

extension SongContentRenderer {
    /// A parsed block of song content.
    enum ContentBlock {
        case heading1(String)
        case heading2(String)
        case chordLine([ChordToken])
        case plainText(String)
        /// Fenced code block with content and optional language hint (e.g. "abc").
        case codeBlock(String, language: String?)
    }

    /// A token within a chord line.
    enum ChordToken: Equatable {
        case chord(String)
        case divider
        case annotation(String)
    }

    /// Regex matching a valid chord name.
    private static let chordPattern = try! NSRegularExpression(
        pattern:
            #"^[A-G][b#]?(?:(?:maj|M)\d*|min|m|aug|\+|dim|ø|sus[24]?|add\d+)?\d*(?:[b#+-]\d+)*(?:/[A-G][b#]?)?$"#
    )

    /// Returns true if the token is a valid chord name.
    static func isChord(_ token: String) -> Bool {
        let range = NSRange(token.startIndex..., in: token)
        return chordPattern.firstMatch(in: token, range: range) != nil
    }

    /// Tokenize a chord line string into ChordTokens.
    static func tokenizeChordLine(_ line: String) -> [ChordToken] {
        let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            .map(String.init)
        var tokens: [ChordToken] = []

        for (index, part) in parts.enumerated() {
            if part.hasPrefix("(") {
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

    /// A flow layout that wraps chord cells to the next row when they exceed the available width.
    struct ChordFlowLayout: Layout {
        let rowHeight: CGFloat

        func sizeThatFits(
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout ()
        ) -> CGSize {
            let maxWidth = proposal.width ?? .infinity
            var x: CGFloat = 0
            var rows = 1

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    rows += 1
                }
                x += size.width
            }

            return CGSize(width: maxWidth, height: rowHeight * CGFloat(rows))
        }

        func placeSubviews(
            in bounds: CGRect,
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout ()
        ) {
            var x: CGFloat = bounds.minX
            var y: CGFloat = bounds.minY

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > bounds.maxX && x > bounds.minX {
                    x = bounds.minX
                    y += rowHeight
                }
                subview.place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: .unspecified
                )
                x += size.width
            }
        }
    }

    /// Parse a markdown string into content blocks.
    static func parse(_ text: String) -> [ContentBlock] {
        let lines = text.components(separatedBy: .newlines)
        var blocks: [ContentBlock] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]

            // Fenced code block
            if line.hasPrefix("```") {
                let language = String(line.dropFirst(3)).trimmingCharacters(
                    in: .whitespaces
                )
                let lang: String? = language.isEmpty ? nil : language
                var codeLines: [String] = []
                index += 1
                while index < lines.count && !lines[index].hasPrefix("```") {
                    codeLines.append(lines[index])
                    index += 1
                }
                // Skip closing ```
                if index < lines.count { index += 1 }
                let content = codeLines.joined(separator: "\n")
                if !content.isEmpty {
                    blocks.append(.codeBlock(content, language: lang))
                }
                continue
            }

            // Heading 2 (check before H1 since ## also starts with #)
            if line.hasPrefix("## ") {
                let text = String(line.dropFirst(3)).trimmingCharacters(
                    in: .whitespaces
                )
                if !text.isEmpty { blocks.append(.heading2(text)) }
                index += 1
                continue
            }

            // Heading 1
            if line.hasPrefix("# ") {
                let text = String(line.dropFirst(2)).trimmingCharacters(
                    in: .whitespaces
                )
                if !text.isEmpty { blocks.append(.heading1(text)) }
                index += 1
                continue
            }

            // Empty line — skip
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                index += 1
                continue
            }

            // Paragraph — each line evaluated independently as chord line or plain text
            var paraLines: [String] = []
            while index < lines.count {
                let l = lines[index]
                if l.trimmingCharacters(in: .whitespaces).isEmpty
                    || l.hasPrefix("# ")
                    || l.hasPrefix("## ")
                    || l.hasPrefix("```")
                {
                    break
                }
                paraLines.append(l)
                index += 1
            }
            for line in paraLines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let firstToken =
                    trimmed.split(separator: " ", maxSplits: 1).first.map(
                        String.init
                    ) ?? ""
                if isChord(firstToken) {
                    blocks.append(.chordLine(tokenizeChordLine(trimmed)))
                } else {
                    blocks.append(.plainText(trimmed))
                }
            }
        }

        return blocks
    }
}

