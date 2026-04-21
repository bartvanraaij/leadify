import XCTest
import SwiftData
@testable import LeadifyCore

@MainActor
final class SongTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        container = try makeTestContainer()
        context = ModelContext(container)
    }

    func test_song_createdWithTitle() throws {
        let song = Song(title: "Sweet Home Alabama", content: "D A Bm G")
        context.insert(song)
        try context.save()

        let songs = try context.fetch(FetchDescriptor<Song>())
        XCTAssertEqual(songs.count, 1)
        XCTAssertEqual(songs[0].title, "Sweet Home Alabama")
        XCTAssertEqual(songs[0].content, "D A Bm G")
        XCTAssertNil(songs[0].reminder)
    }

    func test_song_withReminder() throws {
        let song = Song(title: "Wonderwall", reminder: "Capo 2")
        context.insert(song)
        try context.save()

        let songs = try context.fetch(FetchDescriptor<Song>())
        XCTAssertEqual(songs[0].reminder, "Capo 2")
    }

    func test_song_hasCreatedAt() throws {
        let before = Date()
        let song = Song(title: "Test", content: "")
        context.insert(song)
        try context.save()

        let songs = try context.fetch(FetchDescriptor<Song>())
        XCTAssertGreaterThanOrEqual(songs[0].createdAt, before)
    }

    func test_deletingSong_cascadesToSetlistEntries() throws {
        let song = Song(title: "Cascade Test", content: "")
        context.insert(song)
        let setlist = Setlist(name: "Test Setlist")
        context.insert(setlist)
        let entry = SetlistEntry(song: song)
        context.insert(entry)
        setlist.addEntry(entry)
        try context.save()

        context.delete(song)
        try context.save()

        let entries = try context.fetch(FetchDescriptor<SetlistEntry>())
        XCTAssertTrue(entries.isEmpty, "SetlistEntry should be deleted when its song is deleted")
    }
}
