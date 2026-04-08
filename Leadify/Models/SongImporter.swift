import SwiftUI
import SwiftData

enum ConflictResolution {
    case overwrite
    case skip
    case keepBoth
    case overwriteAll
    case skipAll
}

@Observable
class SongImporter {
    var showConflictDialog = false
    var showErrorAlert = false
    var errorMessage = ""
    var showImportSummary = false
    var importSummaryMessage = ""

    // Stored during conflict so resolveConflict can act on them
    private(set) var conflictParsedSong: SongFileParser.ParsedSong?
    private(set) var conflictExistingSong: Song?

    var hasRemainingConflicts: Bool { !pendingConflicts.isEmpty }

    // Queue for batch imports
    private var pendingConflicts: [(parsed: SongFileParser.ParsedSong, existing: Song)] = []
    private var importedCount = 0
    private var skippedCount = 0
    private var overwrittenCount = 0
    private var failedCount = 0
    private var isBatchImport = false

    /// Import a markdown file from a URL. Handles security-scoped access.
    func importFile(url: URL, context: ModelContext) {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            let parsed = try SongFileParser.parse(text)
            importParsedSong(parsed, context: context)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    /// Import multiple markdown files from URLs.
    func importFiles(urls: [URL], context: ModelContext) {
        guard !urls.isEmpty else { return }

        if urls.count == 1 {
            importFile(url: urls[0], context: context)
            return
        }

        isBatchImport = true
        importedCount = 0
        skippedCount = 0
        overwrittenCount = 0
        failedCount = 0
        pendingConflicts = []

        for url in urls {
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing { url.stopAccessingSecurityScopedResource() }
            }

            do {
                let text = try String(contentsOf: url, encoding: .utf8)
                let parsed = try SongFileParser.parse(text)
                let existingSong = findExistingSong(title: parsed.title, context: context)

                if let existingSong {
                    pendingConflicts.append((parsed: parsed, existing: existingSong))
                } else {
                    let song = Song(title: parsed.title, content: parsed.content, reminder: parsed.reminder)
                    context.insert(song)
                    importedCount += 1
                }
            } catch {
                failedCount += 1
            }
        }

        if pendingConflicts.isEmpty {
            finishBatchImport()
        } else {
            showNextConflict()
        }
    }

    /// Import a parsed song, checking for duplicates.
    func importParsedSong(_ parsed: SongFileParser.ParsedSong, context: ModelContext) {
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
        guard let parsed = conflictParsedSong else { return }

        switch resolution {
        case .overwrite:
            applyOverwrite(parsed: parsed, context: context)
            if isBatchImport { overwrittenCount += 1 }
        case .skip:
            if isBatchImport { skippedCount += 1 }
        case .keepBoth:
            applyKeepBoth(parsed: parsed, context: context)
            if isBatchImport { importedCount += 1 }
        case .overwriteAll:
            applyOverwrite(parsed: parsed, context: context)
            overwrittenCount += 1
            for conflict in pendingConflicts {
                applyOverwrite(parsed: conflict.parsed, context: context)
                overwrittenCount += 1
            }
            pendingConflicts.removeAll()
        case .skipAll:
            skippedCount += 1 + pendingConflicts.count
            pendingConflicts.removeAll()
        }

        conflictParsedSong = nil
        conflictExistingSong = nil
        showConflictDialog = false

        if isBatchImport {
            if pendingConflicts.isEmpty {
                finishBatchImport()
            } else {
                showNextConflict()
            }
        }
    }

    // MARK: - Private helpers

    private func applyOverwrite(parsed: SongFileParser.ParsedSong, context: ModelContext) {
        if let existing = findExistingSong(title: parsed.title, context: context) {
            existing.content = parsed.content
            existing.reminder = parsed.reminder
        }
    }

    private func applyKeepBoth(parsed: SongFileParser.ParsedSong, context: ModelContext) {
        let uniqueTitle = findUniqueTitle(parsed.title, context: context)
        let song = Song(title: uniqueTitle, content: parsed.content, reminder: parsed.reminder)
        context.insert(song)
    }

    private func showNextConflict() {
        guard !pendingConflicts.isEmpty else { return }
        let next = pendingConflicts.removeFirst()
        conflictParsedSong = next.parsed
        conflictExistingSong = next.existing
        showConflictDialog = true
    }

    private func finishBatchImport() {
        isBatchImport = false

        var parts: [String] = []
        if importedCount > 0 { parts.append("\(importedCount) imported") }
        if overwrittenCount > 0 { parts.append("\(overwrittenCount) overwritten") }
        if skippedCount > 0 { parts.append("\(skippedCount) skipped") }
        if failedCount > 0 { parts.append("\(failedCount) failed") }

        importSummaryMessage = parts.joined(separator: ", ")
        showImportSummary = true
    }

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
