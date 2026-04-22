import SwiftData
import Foundation

@Model
public final class Setlist {
    public var name: String
    public var date: Date?
    public var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \SetlistEntry.setlist) public var entries: [SetlistEntry]

    public init(name: String, date: Date? = nil) {
        self.name = name
        self.date = date
        self.entries = []
    }

    public var formattedDate: String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: date)
    }

    public var sortedEntries: [SetlistEntry] {
        entries.sorted { $0.order < $1.order }
    }

    public func addEntry(_ entry: SetlistEntry) {
        entry.order = (entries.max(by: { $0.order < $1.order })?.order ?? -1) + 1
        entries.append(entry)
    }

    public func duplicate(in context: ModelContext) -> Setlist {
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
