import SwiftUI
import SwiftData

@Observable
final class PerformanceViewModel {
    /// IDs of entries currently visible on screen (reported by each block view).
    private(set) var visibleEntryIDs: Set<String> = []

    /// The ordered list of entries in this setlist (set once on init).
    private let entries: [SetlistEntry]

    init(entries: [SetlistEntry]) {
        self.entries = entries
    }

    // MARK: Visibility tracking

    func markVisible(_ id: String) {
        visibleEntryIDs.insert(id)
    }

    func markHidden(_ id: String) {
        visibleEntryIDs.remove(id)
    }

    // MARK: Up Next

    /// The first song entry that is not currently visible and comes after the last visible entry.
    var upNextSong: Song? {
        guard !visibleEntryIDs.isEmpty else { return nil }
        let lastVisibleIndex = entries.indices.last(where: {
            visibleEntryIDs.contains(entryID(entries[$0]))
        }) ?? -1
        return entries[(lastVisibleIndex + 1)...].first(where: { $0.itemType == .song })?.song
    }

    // MARK: Snap Scroll

    /// The ID to scroll to when tapping the bottom zone:
    /// the first entry after the last currently-visible one.
    var snapDownTargetID: String? {
        guard !visibleEntryIDs.isEmpty else {
            return entries.first.map { entryID($0) }
        }
        let lastVisibleIndex = entries.indices.last(where: {
            visibleEntryIDs.contains(entryID(entries[$0]))
        }) ?? -1
        guard lastVisibleIndex + 1 < entries.count else { return nil }
        return entryID(entries[lastVisibleIndex + 1])
    }

    /// The ID to scroll to when tapping the top zone:
    /// jumps back by the number of currently-visible entries.
    var snapUpTargetID: String? {
        guard !visibleEntryIDs.isEmpty else { return nil }
        let firstVisibleIndex = entries.indices.first(where: {
            visibleEntryIDs.contains(entryID(entries[$0]))
        }) ?? 0
        let visibleCount = visibleEntryIDs.count
        let targetIndex = max(0, firstVisibleIndex - visibleCount)
        return entryID(entries[targetIndex])
    }

    // MARK: Helpers

    /// Stable string ID for a SetlistEntry, used as the scroll anchor.
    func entryID(_ entry: SetlistEntry) -> String {
        entry.persistentModelID.hashValue.description
    }
}
