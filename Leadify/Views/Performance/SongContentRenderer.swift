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

        case .plainText(let text):
            Text(text)
                .font(
                    .system(
                        size: PerformanceTheme.chordTextSize,
                        weight: .semibold
                    )
                )
                .foregroundStyle(PerformanceTheme.chordTextColor)

        case .codeBlock(let text, _):
            let lines = trimmedCodeLines(from: text)

            // Approximate a reasonable line height for the monospace font (includes ascenders/descenders)
            let approxLineHeight = PerformanceTheme.tabFontSize * 1.25
            // Compression ratio - how much to compress the vertical spacing
            let compression = (PerformanceTheme.tabFontSize / max(approxLineHeight, 1)) * PerformanceTheme.codeBlockLineCompressionMultiplier
            let compressedLineSpacing = approxLineHeight * compression
            
            // Total height: first line's full height + remaining lines with compressed spacing
            let totalHeight = approxLineHeight + CGFloat(max(lines.count - 1, 0)) * compressedLineSpacing

            let normalHeight = approxLineHeight * CGFloat(lines.count)
            let extraBottomPadding = max(0, normalHeight - totalHeight)

            Color.clear
                .frame(height: totalHeight)
                .overlay(alignment: .topLeading) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { idx, line in
                        Text(line)
                            .font(
                                .system(
                                    size: PerformanceTheme.tabFontSize,
                                    design: .monospaced
                                )
                            )
                            .foregroundStyle(PerformanceTheme.tabColor)
                            .tracking(PerformanceTheme.tabTracking)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .offset(y: CGFloat(idx) * compressedLineSpacing)
                    }
                }
                //.border(Color.purple, width: 1)
                .padding(.bottom, extraBottomPadding + PerformanceTheme.codeBlockExtraBottomPadding)
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
                            .system(
                                size: PerformanceTheme.annotationSize,
                                weight: .regular
                            )
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

