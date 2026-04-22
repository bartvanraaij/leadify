import SwiftData
import Foundation

@Model
public final class Song {
    public var title: String
    public var content: String
    public var reminder: String?
    public var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \SetlistEntry.song)
    public var entries: [SetlistEntry] = []
    @Relationship(deleteRule: .cascade, inverse: \MedleyEntry.song)
    public var medleyEntries: [MedleyEntry] = []

    public init(title: String, content: String = "", reminder: String? = nil) {
        self.title = title
        self.content = content
        self.reminder = reminder
    }

    public func duplicate(in context: ModelContext) -> Song {
        let copy = Song(title: "\(title) (copy)", content: content, reminder: reminder)
        context.insert(copy)
        return copy
    }
}
