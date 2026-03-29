import SwiftData
import Foundation

@Model
final class Song {
    var title: String
    var content: String
    var reminder: String?

    init(title: String, content: String = "", reminder: String? = nil) {
        self.title = title
        self.content = content
        self.reminder = reminder
    }
}
