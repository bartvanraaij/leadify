import SwiftData
import Foundation

@Model
public final class Tacet {
    public var label: String?
    public var entry: SetlistEntry?

    public init(label: String? = nil) {
        self.label = label
    }
}
