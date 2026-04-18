import SwiftData
import Foundation

enum MedleyDisplayMode: String, Codable, CaseIterable {
    case separated
    case combined

    var label: String {
        switch self {
        case .separated: "Separated"
        case .combined: "Combined"
        }
    }

    var explanation: String {
        switch self {
        case .separated: "Each song is displayed and navigated individually"
        case .combined: "Displayed and navigated as one item"
        }
    }
}

@Model
final class Medley {
    var name: String
    var displayModeRaw: String = MedleyDisplayMode.separated.rawValue
    var createdAt: Date = Date()

    var displayMode: MedleyDisplayMode {
        get { MedleyDisplayMode(rawValue: displayModeRaw) ?? .separated }
        set { displayModeRaw = newValue.rawValue }
    }
    @Relationship(deleteRule: .cascade, inverse: \MedleyEntry.medley) var entries: [MedleyEntry]
    @Relationship(deleteRule: .cascade, inverse: \SetlistEntry.medley)
    var setlistEntries: [SetlistEntry] = []

    init(name: String) {
        self.name = name
        self.entries = []
    }

    /// Entries sorted by their explicit order index. Always use this for display and iteration.
    var sortedEntries: [MedleyEntry] {
        entries.sorted { $0.order < $1.order }
    }

    /// Appends an entry and assigns its order after the current last entry.
    func addEntry(_ entry: MedleyEntry) {
        entry.order = (entries.max(by: { $0.order < $1.order })?.order ?? -1) + 1
        entries.append(entry)
    }

    /// Creates a copy of this medley. Songs are shared by reference (same as setlist duplication).
    func duplicate(in context: ModelContext) -> Medley {
        let copy = Medley(name: "\(name) (copy)")
        context.insert(copy)
        for (index, entry) in sortedEntries.enumerated() {
            let entryCopy = MedleyEntry(song: entry.song)
            entryCopy.order = index
            context.insert(entryCopy)
            copy.entries.append(entryCopy)
        }
        return copy
    }
}
