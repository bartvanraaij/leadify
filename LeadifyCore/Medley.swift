import SwiftData
import Foundation

public enum MedleyDisplayMode: String, Codable, CaseIterable {
    case separated
    case combined

    public var label: String {
        switch self {
        case .separated: "Separated"
        case .combined: "Combined"
        }
    }

    public var explanation: String {
        switch self {
        case .separated: "Each song is displayed and navigated individually"
        case .combined: "Displayed and navigated as one item"
        }
    }
}

@Model
public final class Medley {
    public var name: String
    public var displayModeRaw: String = MedleyDisplayMode.separated.rawValue
    public var createdAt: Date = Date()

    public var displayMode: MedleyDisplayMode {
        get { MedleyDisplayMode(rawValue: displayModeRaw) ?? .separated }
        set { displayModeRaw = newValue.rawValue }
    }
    @Relationship(deleteRule: .cascade, inverse: \MedleyEntry.medley) public var entries: [MedleyEntry]
    @Relationship(deleteRule: .cascade, inverse: \SetlistEntry.medley)
    public var setlistEntries: [SetlistEntry] = []

    public init(name: String) {
        self.name = name
        self.entries = []
    }

    public var sortedEntries: [MedleyEntry] {
        entries.sorted { $0.order < $1.order }
    }

    public func addEntry(_ entry: MedleyEntry) {
        entry.order = (entries.max(by: { $0.order < $1.order })?.order ?? -1) + 1
        entries.append(entry)
    }

    public func duplicate(in context: ModelContext) -> Medley {
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
