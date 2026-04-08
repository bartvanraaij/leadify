import SwiftUI

/// Lightweight markdown renderer for song content.
/// Supports: `# H1`, `## H2`, paragraphs, and fenced code blocks (``` ... ```).
/// Replaces the external MarkdownUI dependency with a slim, extensible renderer.
struct SongContentRenderer: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(Self.parse(content).enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(_ block: ContentBlock) -> some View {
        switch block {
        case .heading1(let text):
            Text(text)
                .font(.system(size: PerformanceTheme.songTitleSize, weight: .bold))
                .foregroundStyle(PerformanceTheme.songTitleColor)
                .lineSpacing(PerformanceTheme.songTitleSize * 0.1)
                .padding(.top, PerformanceTheme.songTitleSize * 0.8)
                .padding(.bottom, PerformanceTheme.songTitleSize * 0.2)

        case .heading2(let text):
            Text(text)
                .font(.system(size: PerformanceTheme.sectionHeaderSize, weight: .semibold))
                .foregroundStyle(PerformanceTheme.sectionHeaderColor)
                .lineSpacing(PerformanceTheme.sectionHeaderSize * 0.1)
                .padding(.top, PerformanceTheme.sectionHeaderSize * 0.8)
                .padding(.bottom, PerformanceTheme.sectionHeaderSize * 0.2)

        case .paragraph(let text):
            Text(text)
                .font(.system(size: PerformanceTheme.chordTextSize, weight: .semibold))
                .foregroundStyle(PerformanceTheme.chordTextColor)

        case .codeBlock(let text, _):
            Text(text)
                .font(.system(size: PerformanceTheme.tabFontSize, design: .monospaced))
                .foregroundStyle(PerformanceTheme.tabColor)
                .tracking(PerformanceTheme.tabTracking)
                .padding(.vertical, 4)
        }
    }
}

// MARK: - Content blocks

extension SongContentRenderer {
    /// A parsed block of song content.
    enum ContentBlock {
        case heading1(String)
        case heading2(String)
        case paragraph(String)
        /// Fenced code block with content and optional language hint (e.g. "abc").
        case codeBlock(String, language: String?)
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
                let language = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
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
                let text = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                if !text.isEmpty { blocks.append(.heading2(text)) }
                index += 1
                continue
            }

            // Heading 1
            if line.hasPrefix("# ") {
                let text = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                if !text.isEmpty { blocks.append(.heading1(text)) }
                index += 1
                continue
            }

            // Empty line — skip
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                index += 1
                continue
            }

            // Paragraph — collect consecutive non-empty, non-special lines
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
            if !paraLines.isEmpty {
                blocks.append(.paragraph(paraLines.joined(separator: "\n")))
            }
        }

        return blocks
    }
}
