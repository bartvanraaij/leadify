import SwiftData
import Foundation

@Model
final class MedleyEntry {
    var song: Song
    var order: Int = 0
    var createdAt: Date = Date()

    init(song: Song) {
        self.song = song
    }
}
