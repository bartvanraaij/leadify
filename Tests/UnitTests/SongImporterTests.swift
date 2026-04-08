import XCTest
import SwiftData
@testable import Leadify

@MainActor
final class SongImporterTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var importer: SongImporter!

    override func setUp() async throws {
        container = try makeTestContainer()
        context = ModelContext(container)
        importer = SongImporter()
    }

    // MARK: - importParsedSong (bypasses file I/O)

    func test_importNewSong_insertsSong() throws {
        let parsed = MarkdownSongParser.ParsedSong(
            title: "New Song", reminder: "Capo 2", content: "Am G C"
        )
        importer.importParsedSong(parsed, context: context)

        XCTAssertFalse(importer.showConflictDialog)
        let songs = try context.fetch(FetchDescriptor<Song>())
        XCTAssertEqual(songs.count, 1)
        XCTAssertEqual(songs[0].title, "New Song")
        XCTAssertEqual(songs[0].content, "Am G C")
        XCTAssertEqual(songs[0].reminder, "Capo 2")
    }

    func test_importDuplicateSong_showsConflictDialog() throws {
        let existing = Song(title: "Duplicate", content: "old content")
        context.insert(existing)
        try context.save()

        let parsed = MarkdownSongParser.ParsedSong(
            title: "Duplicate", reminder: nil, content: "new content"
        )
        importer.importParsedSong(parsed, context: context)

        XCTAssertTrue(importer.showConflictDialog)
        let songs = try context.fetch(FetchDescriptor<Song>())
        XCTAssertEqual(songs.count, 1)
        XCTAssertEqual(songs[0].content, "old content")
    }

    func test_importDuplicateCaseInsensitive_showsConflictDialog() throws {
        let existing = Song(title: "my song", content: "old")
        context.insert(existing)
        try context.save()

        let parsed = MarkdownSongParser.ParsedSong(
            title: "My Song", reminder: nil, content: "new"
        )
        importer.importParsedSong(parsed, context: context)

        XCTAssertTrue(importer.showConflictDialog)
    }

    func test_resolveOverwrite_updatesExistingSong() throws {
        let existing = Song(title: "Overwrite Me", content: "old", reminder: "old reminder")
        context.insert(existing)
        try context.save()

        let parsed = MarkdownSongParser.ParsedSong(
            title: "Overwrite Me", reminder: "new reminder", content: "new content"
        )
        importer.importParsedSong(parsed, context: context)
        importer.resolveConflict(.overwrite, context: context)

        let songs = try context.fetch(FetchDescriptor<Song>())
        XCTAssertEqual(songs.count, 1)
        XCTAssertEqual(songs[0].content, "new content")
        XCTAssertEqual(songs[0].reminder, "new reminder")
        XCTAssertFalse(importer.showConflictDialog)
    }

    func test_resolveSkip_doesNothing() throws {
        let existing = Song(title: "Keep Me", content: "original")
        context.insert(existing)
        try context.save()

        let parsed = MarkdownSongParser.ParsedSong(
            title: "Keep Me", reminder: nil, content: "different"
        )
        importer.importParsedSong(parsed, context: context)
        importer.resolveConflict(.skip, context: context)

        let songs = try context.fetch(FetchDescriptor<Song>())
        XCTAssertEqual(songs.count, 1)
        XCTAssertEqual(songs[0].content, "original")
        XCTAssertFalse(importer.showConflictDialog)
    }

    func test_resolveKeepBoth_addsSuffixedSong() throws {
        let existing = Song(title: "Both", content: "original")
        context.insert(existing)
        try context.save()

        let parsed = MarkdownSongParser.ParsedSong(
            title: "Both", reminder: nil, content: "imported"
        )
        importer.importParsedSong(parsed, context: context)
        importer.resolveConflict(.keepBoth, context: context)

        let songs = try context.fetch(FetchDescriptor<Song>())
        XCTAssertEqual(songs.count, 2)
        let titles = songs.map(\.title).sorted()
        XCTAssertEqual(titles, ["Both", "Both (2)"])
        XCTAssertFalse(importer.showConflictDialog)
    }

    func test_resolveKeepBoth_incrementsSuffix() throws {
        context.insert(Song(title: "Song", content: ""))
        context.insert(Song(title: "Song (2)", content: ""))
        try context.save()

        let parsed = MarkdownSongParser.ParsedSong(
            title: "Song", reminder: nil, content: "new"
        )
        importer.importParsedSong(parsed, context: context)
        importer.resolveConflict(.keepBoth, context: context)

        let songs = try context.fetch(FetchDescriptor<Song>())
        XCTAssertEqual(songs.count, 3)
        let titles = songs.map(\.title)
        XCTAssertTrue(titles.contains("Song (3)"))
    }
}
