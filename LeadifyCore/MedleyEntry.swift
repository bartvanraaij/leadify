import SwiftData
import Foundation

@Model
public final class MedleyEntry {
    public var song: Song
    public var medley: Medley?
    public var order: Int = 0
    public var createdAt: Date = Date()

    public init(song: Song) {
        self.song = song
    }
}
