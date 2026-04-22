import Foundation

public enum SongContentParser {
    public enum ContentBlock {
        case heading1(String)
        case heading2(String)
        case chordLine([ChordToken])
        case plainText(String)
        case codeBlock(String, language: String?)
    }

    public enum ChordToken: Equatable {
        case chord(String)
        case divider
        case annotation(String)
    }

    private static let chordPattern = try! NSRegularExpression(
        pattern:
            #"^[A-G][b#]?(?:(?:maj|M)\d*|min|m|aug|\+|dim|ø|sus[24]?|add\d+)?\d*(?:[b#+-]\d+)*(?:/[A-G][b#]?)?$"#
    )

    public static func isChord(_ token: String) -> Bool {
        let range = NSRange(token.startIndex..., in: token)
        return chordPattern.firstMatch(in: token, range: range) != nil
    }

    public static func tokenizeChordLine(_ line: String) -> [ChordToken] {
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

    public static func parse(_ text: String) -> [ContentBlock] {
        let lines = text.components(separatedBy: .newlines)
        var blocks: [ContentBlock] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]

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
                if index < lines.count { index += 1 }
                let content = codeLines.joined(separator: "\n")
                if !content.isEmpty {
                    blocks.append(.codeBlock(content, language: lang))
                }
                continue
            }

            if line.hasPrefix("## ") {
                let text = String(line.dropFirst(3)).trimmingCharacters(
                    in: .whitespaces
                )
                if !text.isEmpty { blocks.append(.heading2(text)) }
                index += 1
                continue
            }

            if line.hasPrefix("# ") {
                let text = String(line.dropFirst(2)).trimmingCharacters(
                    in: .whitespaces
                )
                if !text.isEmpty { blocks.append(.heading1(text)) }
                index += 1
                continue
            }

            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                index += 1
                continue
            }

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
