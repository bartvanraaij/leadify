import SwiftUI
import SwiftData

enum ConflictResolution {
    case overwrite
    case skip
    case keepBoth
}

@Observable
class SongImporter {
    var showConflictDialog = false
    var showErrorAlert = false
    var errorMessage = ""

    // Stored during conflict so resolveConflict can act on them
    private(set) var conflictParsedSong: MarkdownSongParser.ParsedSong?
    private(set) var conflictExistingSong: Song?

    /// Import a markdown file from a URL. Handles security-scoped access.
    func importFile(url: URL, context: ModelContext) {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            let parsed = try MarkdownSongParser.parse(text)
            importParsedSong(parsed, context: context)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    /// Import a parsed song, checking for duplicates.
    func importParsedSong(_ parsed: MarkdownSongParser.ParsedSong, context: ModelContext) {
        let existingSong = findExistingSong(title: parsed.title, context: context)

        if let existingSong {
            conflictParsedSong = parsed
            conflictExistingSong = existingSong
            showConflictDialog = true
        } else {
            let song = Song(title: parsed.title, content: parsed.content, reminder: parsed.reminder)
            context.insert(song)
        }
    }

    /// Resolve a duplicate conflict.
    func resolveConflict(_ resolution: ConflictResolution, context: ModelContext) {
        defer {
            conflictParsedSong = nil
            conflictExistingSong = nil
            showConflictDialog = false
        }

        guard let parsed = conflictParsedSong else { return }

        switch resolution {
        case .overwrite:
            if let existing = conflictExistingSong {
                existing.content = parsed.content
                existing.reminder = parsed.reminder
            }
        case .skip:
            break
        case .keepBoth:
            let uniqueTitle = findUniqueTitle(parsed.title, context: context)
            let song = Song(title: uniqueTitle, content: parsed.content, reminder: parsed.reminder)
            context.insert(song)
        }
    }

    // MARK: - Private helpers

    private func findExistingSong(title: String, context: ModelContext) -> Song? {
        let descriptor = FetchDescriptor<Song>()
        guard let songs = try? context.fetch(descriptor) else { return nil }
        return songs.first { $0.title.caseInsensitiveCompare(title) == .orderedSame }
    }

    private func findUniqueTitle(_ baseTitle: String, context: ModelContext) -> String {
        let descriptor = FetchDescriptor<Song>()
        guard let songs = try? context.fetch(descriptor) else { return "\(baseTitle) (2)" }
        let existingTitles = Set(songs.map { $0.title.lowercased() })

        var counter = 2
        while true {
            let candidate = "\(baseTitle) (\(counter))"
            if !existingTitles.contains(candidate.lowercased()) {
                return candidate
            }
            counter += 1
        }
    }
}
