import SwiftData
import Foundation

@Model
final class Song {
    var title: String
    var content: String
    var reminder: String?
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \SetlistEntry.song)
    var entries: [SetlistEntry] = []

    init(title: String, content: String = "", reminder: String? = nil) {
        self.title = title
        self.content = content
        self.reminder = reminder
    }

    func duplicate(in context: ModelContext) -> Song {
        let copy = Song(title: "\(title) (copy)", content: content, reminder: reminder)
        context.insert(copy)
        return copy
    }
}
