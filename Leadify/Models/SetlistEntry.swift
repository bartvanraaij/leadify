import SwiftData
import Foundation

enum SetlistItemType {
    case song
    case tacet
    case medley
}

@Model
final class SetlistEntry {
    var song: Song?
    @Relationship(deleteRule: .cascade) var tacet: Tacet?
    var medley: Medley?
    var order: Int = 0
    var createdAt: Date = Date()

    /// Derived from which optional is non-nil. Extend this enum to add new item types.
    var itemType: SetlistItemType {
        if medley != nil { return .medley }
        if song != nil { return .song }
        return .tacet
    }

    init(song: Song) {
        self.song = song
        self.tacet = nil
        self.medley = nil
    }

    init(tacet: Tacet) {
        self.song = nil
        self.tacet = tacet
        self.medley = nil
    }

    init(medley: Medley) {
        self.song = nil
        self.tacet = nil
        self.medley = medley
    }
}
