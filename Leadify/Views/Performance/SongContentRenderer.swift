import SwiftUI
import LeadifyCore

struct SongContentRenderer: View {
    let content: String

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        let m = PerformanceTheme.metrics(for: horizontalSizeClass)

        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(SongContentParser.parse(content).enumerated()), id: \.offset) {
                _,
                block in
                blockView(block, m)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func trimmedCodeLines(from text: String) -> [String] {
        var lines = text.components(separatedBy: .newlines)
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

    private static func coloredTabLine(_ line: String, tabFontSize: CGFloat) -> AttributedString {
        let chars = Array(line)
        let firstGridIndex = chars.firstIndex(where: { gridCharacters.contains($0) || $0 == "─" }) ?? 0
        var result = AttributedString()
        for (i, ch) in chars.enumerated() {
            var attr = AttributedString(String(ch))
            if i < firstGridIndex || gridCharacters.contains(ch) {
                attr.foregroundColor = PerformanceTheme.tabGridColor
            } else {
                attr.foregroundColor = PerformanceTheme.primaryContentColor
                attr.font = .custom("Menlo-Bold", size: tabFontSize)
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
                    case (false, true, _, _):          return " "
                    case (true, false, _, _):          return " "
                    case (true, true, true, _):        return "┬"
                    case (true, true, _, true):        return "┴"
                    case (true, true, false, false):   return "┼"
                    default:                           return "│"
                    }
                default:
                    return ch
                }
            })
        }
    }

    @ViewBuilder
    private func blockView(_ block: SongContentParser.ContentBlock, _ m: PerformanceTheme.Metrics) -> some View {
        switch block {
        case .heading1(let text):
            Text(text)
                .font(
                    .system(size: m.songTitleSize, weight: .bold, design: .rounded)
                )
                .foregroundStyle(PerformanceTheme.songTitleColor)
                .lineSpacing(m.songTitleSize * PerformanceTheme.headingLineSpacingFraction)
                .padding(.top, m.songTitleSize * PerformanceTheme.headingTopPaddingFraction)
                .padding(.bottom, m.songTitleSize * PerformanceTheme.headingBottomPaddingFraction)

        case .heading2(let text):
            Text(text.lowercased())
                .font(
                    .system(
                        size: m.sectionHeaderSize,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .foregroundStyle(PerformanceTheme.sectionHeaderColor)
                .lineSpacing(m.sectionHeaderSize * PerformanceTheme.headingLineSpacingFraction)
                .padding(.top, m.sectionHeaderSize * PerformanceTheme.headingTopPaddingFraction)
                .padding(.bottom, m.sectionHeaderSize * PerformanceTheme.headingBottomPaddingFraction)

        case .chordLine(let tokens):
            chordLineView(tokens, m)
                .padding(.leading, m.contentIndent)

        case .plainText(let text):
            Text(text)
                .font(
                    .system(
                        size: m.chordTextSize,
                        weight: .semibold
                    )
                )
                .foregroundStyle(PerformanceTheme.chordTextColor)
                .padding(.leading, m.contentIndent)
                .padding(.bottom, m.plainTextBottomPadding)

        case .codeBlock(let text, _):
            let lines = Self.replaceBoxDrawingCharacters(trimmedCodeLines(from: text))

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(Self.coloredTabLine(line, tabFontSize: m.tabFontSize))
                        .font(
                            .custom("Menlo", size: m.tabFontSize)
                        )
                        .lineLimit(1)
                }
            }
            .padding(.bottom, PerformanceTheme.codeBlockVerticalPadding)
            .padding(.leading, m.contentIndent)
        @unknown default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func chordLineView(_ tokens: [SongContentParser.ChordToken], _ m: PerformanceTheme.Metrics) -> some View {
        ChordFlowLayout(rowHeight: m.chordRowHeight) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                switch token {
                case .chord(let name):
                    Text(name)
                        .font(
                            .system(
                                size: m.chordTextSize,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(PerformanceTheme.chordTextColor)
                        .minimumScaleFactor(PerformanceTheme.chordMinimumScaleFactor)
                        .lineLimit(1)
                        .frame(
                            width: m.chordCellWidth,
                            alignment: .leading
                        )

                case .divider:
                    Text("/")
                        .font(
                            .system(
                                size: m.chordTextSize,
                                weight: .regular
                            )
                        )
                        .foregroundStyle(PerformanceTheme.chordDividerColor)
                        .frame(
                            width: m.chordCellWidth,
                            alignment: .center
                        )

                case .annotation(let text):
                    Text(text)
                        .font(
                            .custom("Menlo-Bold", size: m.annotationSize)
                        )
                        .foregroundStyle(PerformanceTheme.annotationColor)
                        .padding(.leading, PerformanceTheme.annotationLeadingPadding)
                        .padding(
                            .top,
                            m.annotationBaselineOffset
                        )
                @unknown default:
                    EmptyView()
                }
            }
        }
    }

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
}
