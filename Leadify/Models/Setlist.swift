import SwiftData
import Foundation

@Model
final class Setlist {
    var name: String
    var date: Date?
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade) var entries: [SetlistEntry]

    init(name: String, date: Date? = nil) {
        self.name = name
        self.date = date
        self.entries = []
    }

    /// Date formatted as dd-MM-yyyy for display (NL convention).
    var formattedDate: String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: date)
    }

    /// Entries sorted by their explicit order index. Always use this for display and iteration.
    var sortedEntries: [SetlistEntry] {
        entries.sorted { $0.order < $1.order }
    }

    /// Appends an entry and assigns its order after the current last entry.
    func addEntry(_ entry: SetlistEntry) {
        entry.order = (entries.max(by: { $0.order < $1.order })?.order ?? -1) + 1
        entries.append(entry)
    }

    /// Creates a copy of this setlist with a new name.
    /// - Songs are shared by reference (editing a song updates all setlists).
    /// - Tacets are deep-copied (they are owned by their entry).
    /// - Medleys are shared by reference (same as songs).
    func duplicate(in context: ModelContext) -> Setlist {
        let copy = Setlist(name: "\(name) (copy)", date: date)
        context.insert(copy)
        for (index, entry) in sortedEntries.enumerated() {
            let entryCopy: SetlistEntry
            switch entry.itemType {
            case .song:
                entryCopy = SetlistEntry(song: entry.song!)
            case .tacet:
                let tacetCopy = Tacet(label: entry.tacet?.label)
                context.insert(tacetCopy)
                entryCopy = SetlistEntry(tacet: tacetCopy)
            case .medley:
                entryCopy = SetlistEntry(medley: entry.medley!)
            }
            entryCopy.order = index
            context.insert(entryCopy)
            copy.entries.append(entryCopy)
        }
        return copy
    }
}
