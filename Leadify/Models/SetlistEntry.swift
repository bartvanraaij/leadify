import SwiftData
import Foundation

enum SetlistItemType {
    case song
    case tacet
}

@Model
final class SetlistEntry {
    var song: Song?
    @Relationship(deleteRule: .cascade) var tacet: Tacet?
    var order: Int = 0
    var createdAt: Date = Date()

    /// Derived from which optional is non-nil. Extend this enum to add new item types.
    var itemType: SetlistItemType {
        song != nil ? .song : .tacet
    }

    init(song: Song) {
        self.song = song
        self.tacet = nil
    }

    init(tacet: Tacet) {
        self.song = nil
        self.tacet = tacet
    }
}
