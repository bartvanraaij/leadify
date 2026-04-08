import XCTest
import SwiftData
@testable import Leadify

@MainActor
final class SetlistTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        container = try makeTestContainer()
        context = ModelContext(container)
    }

    // MARK: - Duplicate

    func test_duplicate_createsSeparateSetlist() throws {
        let song = Song(title: "Mr. Brightside")
        context.insert(song)
        let original = Setlist(name: "Gig A", date: Date())
        context.insert(original)
        let entry = SetlistEntry(song: song)
        context.insert(entry)
        original.addEntry(entry)
        try context.save()

        let copy = original.duplicate(in: context)
        try context.save()

        let setlists = try context.fetch(FetchDescriptor<Setlist>())
        XCTAssertEqual(setlists.count, 2)
        XCTAssertEqual(copy.name, "Gig A (copy)")
    }

    func test_duplicate_sharesSongReferences() throws {
        let song = Song(title: "Wonderwall")
        context.insert(song)
        let original = Setlist(name: "Gig A")
        context.insert(original)
        let entry = SetlistEntry(song: song)
        context.insert(entry)
        original.addEntry(entry)
        try context.save()

        let copy = original.duplicate(in: context)
        try context.save()

        XCTAssertEqual(original.sortedEntries[0].song?.persistentModelID,
                       copy.sortedEntries[0].song?.persistentModelID)
    }

    func test_duplicate_deepCopiesTacets() throws {
        let tacet = Tacet(label: "15 min")
        context.insert(tacet)
        let original = Setlist(name: "Gig A")
        context.insert(original)
        let entry = SetlistEntry(tacet: tacet)
        context.insert(entry)
        original.addEntry(entry)
        try context.save()

        let copy = original.duplicate(in: context)
        try context.save()

        XCTAssertNotEqual(original.sortedEntries[0].tacet?.persistentModelID,
                          copy.sortedEntries[0].tacet?.persistentModelID)
        XCTAssertEqual(copy.sortedEntries[0].tacet?.label, "15 min")
    }

    func test_duplicate_preservesEntryOrder() throws {
        let s1 = Song(title: "Song 1")
        let s2 = Song(title: "Song 2")
        let s3 = Song(title: "Song 3")
        [s1, s2, s3].forEach { context.insert($0) }
        let original = Setlist(name: "Gig A")
        context.insert(original)
        for song in [s1, s2, s3] {
            let e = SetlistEntry(song: song)
            context.insert(e)
            original.addEntry(e)
        }
        try context.save()

        let copy = original.duplicate(in: context)
        try context.save()

        XCTAssertEqual(copy.sortedEntries.compactMap { $0.song?.title }, ["Song 1", "Song 2", "Song 3"])
    }

    // MARK: - Ordering

    func test_setlist_preservesEntryOrder() throws {
        let setlist = Setlist(name: "Test")
        context.insert(setlist)
        for i in 1...5 {
            let song = Song(title: "Song \(i)")
            context.insert(song)
            let entry = SetlistEntry(song: song)
            context.insert(entry)
            setlist.addEntry(entry)
        }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Setlist>()).first!
        XCTAssertEqual(fetched.sortedEntries.compactMap { $0.song?.title },
                       ["Song 1", "Song 2", "Song 3", "Song 4", "Song 5"])
    }

    // MARK: - Medley entries

    func test_medleyEntry_hasCorrectItemType() throws {
        let medley = Medley(name: "Rock 1")
        context.insert(medley)
        let entry = SetlistEntry(medley: medley)
        context.insert(entry)
        XCTAssertEqual(entry.itemType, .medley)
    }

    func test_duplicate_sharesMedleyReferences() throws {
        let medley = Medley(name: "Rock 1")
        context.insert(medley)
        let original = Setlist(name: "Gig A")
        context.insert(original)
        let entry = SetlistEntry(medley: medley)
        context.insert(entry)
        original.addEntry(entry)
        try context.save()

        let copy = original.duplicate(in: context)
        try context.save()

        XCTAssertEqual(copy.sortedEntries[0].medley?.persistentModelID,
                       medley.persistentModelID)
    }

    // MARK: - formattedDate

    func test_formattedDate_nilWhenNoDate() {
        let setlist = Setlist(name: "Test")
        XCTAssertNil(setlist.formattedDate)
    }

    func test_formattedDate_nlFormat() {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 28
        let date = Calendar.current.date(from: components)!
        let setlist = Setlist(name: "Test", date: date)
        XCTAssertEqual(setlist.formattedDate, "28-03-2026")
    }
}
