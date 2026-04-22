import XCTest
import SwiftData
@testable import LeadifyCore

@MainActor
final class MedleyTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        container = try makeTestContainer()
        context = ModelContext(container)
    }

    // MARK: - Creation

    func test_medley_createdWithName() throws {
        let medley = Medley(name: "Rock 1")
        context.insert(medley)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Medley>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].name, "Rock 1")
    }

    // MARK: - Ordering

    func test_medley_preservesEntryOrder() throws {
        let medley = Medley(name: "Rock 1")
        context.insert(medley)

        let songs = ["Girl", "Zombie", "Smells Like Teen Spirit"].map { Song(title: $0) }
        songs.forEach { context.insert($0) }

        for song in songs {
            let entry = MedleyEntry(song: song)
            context.insert(entry)
            medley.addEntry(entry)
        }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Medley>()).first!
        XCTAssertEqual(fetched.sortedEntries.map { $0.song.title },
                       ["Girl", "Zombie", "Smells Like Teen Spirit"])
    }

    // MARK: - Duplicate

    func test_duplicate_createsSeparateMedley() throws {
        let medley = Medley(name: "Rock 1")
        context.insert(medley)
        let song = Song(title: "Girl")
        context.insert(song)
        let entry = MedleyEntry(song: song)
        context.insert(entry)
        medley.addEntry(entry)
        try context.save()

        let copy = medley.duplicate(in: context)
        try context.save()

        let medleys = try context.fetch(FetchDescriptor<Medley>())
        XCTAssertEqual(medleys.count, 2)
        XCTAssertEqual(copy.name, "Rock 1 (copy)")
    }

    func test_duplicate_sharesSongReferences() throws {
        let medley = Medley(name: "Rock 1")
        context.insert(medley)
        let song = Song(title: "Girl")
        context.insert(song)
        let entry = MedleyEntry(song: song)
        context.insert(entry)
        medley.addEntry(entry)
        try context.save()

        let copy = medley.duplicate(in: context)
        try context.save()

        XCTAssertEqual(medley.sortedEntries[0].song.persistentModelID,
                       copy.sortedEntries[0].song.persistentModelID)
    }

    func test_duplicate_preservesEntryOrder() throws {
        let medley = Medley(name: "Rock 1")
        context.insert(medley)
        let songs = ["Girl", "Zombie", "Teen Spirit"].map { Song(title: $0) }
        songs.forEach { context.insert($0) }
        for song in songs {
            let entry = MedleyEntry(song: song)
            context.insert(entry)
            medley.addEntry(entry)
        }
        try context.save()

        let copy = medley.duplicate(in: context)
        try context.save()

        XCTAssertEqual(copy.sortedEntries.map { $0.song.title },
                       ["Girl", "Zombie", "Teen Spirit"])
    }
}
