import SwiftData
import Foundation

public enum SetlistItemType {
    case song
    case tacet
    case medley
}

@Model
public final class SetlistEntry {
    public var song: Song?
    @Relationship(deleteRule: .cascade, inverse: \Tacet.entry) public var tacet: Tacet?
    public var medley: Medley?
    public var setlist: Setlist?
    public var order: Int = 0
    public var createdAt: Date = Date()

    public var itemType: SetlistItemType {
        if medley != nil { return .medley }
        if song != nil { return .song }
        return .tacet
    }

    public init(song: Song) {
        self.song = song
        self.tacet = nil
        self.medley = nil
    }

    public init(tacet: Tacet) {
        self.song = nil
        self.tacet = tacet
        self.medley = nil
    }

    public init(medley: Medley) {
        self.song = nil
        self.tacet = nil
        self.medley = medley
    }
}
