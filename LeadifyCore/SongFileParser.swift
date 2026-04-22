import Foundation

public struct SongFileParser {

    public struct ParsedSong {
        public let title: String
        public let reminder: String?
        public let content: String

        public init(title: String, reminder: String?, content: String) {
            self.title = title
            self.reminder = reminder
            self.content = content
        }
    }

    public enum ParseError: LocalizedError {
        case noFrontmatter
        case missingTitle

        public var errorDescription: String? {
            switch self {
            case .noFrontmatter: "File does not contain valid frontmatter (expected --- delimiters)."
            case .missingTitle: "Frontmatter is missing a 'title' field."
            }
        }
    }

    public static func parse(_ text: String) throws -> ParsedSong {
        let lines = text.components(separatedBy: .newlines)

        var delimiterIndices: [Int] = []
        for (index, line) in lines.enumerated() {
            if line.trimmingCharacters(in: .whitespaces) == "---" {
                delimiterIndices.append(index)
                if delimiterIndices.count == 2 { break }
            }
        }

        guard delimiterIndices.count == 2 else {
            throw ParseError.noFrontmatter
        }

        let frontmatterLines = Array(lines[(delimiterIndices[0] + 1)..<delimiterIndices[1]])
        var fields: [String: String] = [:]
        for line in frontmatterLines {
            guard let colonIndex = line.firstIndex(of: ":") else { continue }
            let key = String(line[line.startIndex..<colonIndex]).trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
            if !key.isEmpty {
                fields[key] = value
            }
        }

        guard let title = fields["title"], !title.isEmpty else {
            throw ParseError.missingTitle
        }

        let bodyLines = Array(lines[(delimiterIndices[1] + 1)...])
        let content = bodyLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        return ParsedSong(
            title: title,
            reminder: fields["reminder"],
            content: content
        )
    }
}
