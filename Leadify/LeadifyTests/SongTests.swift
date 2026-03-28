import XCTest
import SwiftData
@testable import Leadify

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
}
