import SwiftData
import Foundation

/// A non-song setlist entry. Name from music notation: "tacet" = be silent.
@Model
final class Tacet {
    var label: String?
    var entry: SetlistEntry?

    init(label: String? = nil) {
        self.label = label
    }
}
