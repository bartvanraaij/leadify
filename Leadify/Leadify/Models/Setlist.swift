import SwiftData
import Foundation

@Model
final class Setlist {
    var name: String
    var date: Date?
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

    /// Creates a copy of this setlist with a new name.
    /// - Songs are shared by reference (editing a song updates all setlists).
    /// - Tacets are deep-copied (they are owned by their entry; sharing would
    ///   cause the tacet to be deleted if the original setlist is deleted).
    func duplicate(in context: ModelContext) -> Setlist {
        let copy = Setlist(name: "\(name) (copy)", date: date)
        context.insert(copy)
        for entry in entries {
            switch entry.itemType {
            case .song:
                let entryCopy = SetlistEntry(song: entry.song!)
                context.insert(entryCopy)
                copy.entries.append(entryCopy)
            case .tacet:
                let tacetCopy = Tacet(label: entry.tacet?.label)
                context.insert(tacetCopy)
                let entryCopy = SetlistEntry(tacet: tacetCopy)
                context.insert(entryCopy)
                copy.entries.append(entryCopy)
            }
        }
        return copy
    }
}
