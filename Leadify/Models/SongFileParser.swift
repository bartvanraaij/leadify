import Foundation

struct SongFileParser {

    struct ParsedSong {
        let title: String
        let reminder: String?
        let content: String
    }

    enum ParseError: LocalizedError {
        case noFrontmatter
        case missingTitle

        var errorDescription: String? {
            switch self {
            case .noFrontmatter: "File does not contain valid frontmatter (expected --- delimiters)."
            case .missingTitle: "Frontmatter is missing a 'title' field."
            }
        }
    }

    static func parse(_ text: String) throws -> ParsedSong {
        let lines = text.components(separatedBy: .newlines)

        // Find the two --- delimiters
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

        // Parse frontmatter key-value pairs
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

        // Everything after the second delimiter is the body
        let bodyLines = Array(lines[(delimiterIndices[1] + 1)...])
        let content = bodyLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        return ParsedSong(
            title: title,
            reminder: fields["reminder"],
            content: content
        )
    }
}
