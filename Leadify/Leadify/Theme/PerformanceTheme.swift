import SwiftUI

/// All visual constants for Performance Mode.
/// Adjust these after testing on the actual iPad.
struct PerformanceTheme {
    // MARK: Font sizes
    static let songTitleSize: CGFloat = 28
    static let reminderSize: CGFloat = 18
    static let sectionHeaderSize: CGFloat = 16
    static let chordTextSize: CGFloat = 22
    static let tabFontSize: CGFloat = 18
    static let upNextSize: CGFloat = 14

    // MARK: Colors
    static let background = Color.black
    static let songTitleColor = Color.white
    static let chordTextColor = Color(white: 0.88)
    static let sectionHeaderColor = Color(white: 0.55)
    static let reminderColor = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let tabColor = Color(red: 0.49, green: 0.86, blue: 0.49)
    static let tacetTextColor = Color(white: 0.42)
    static let upNextColor = Color(white: 0.60)
    static let tapZoneIndicatorColor = Color(white: 0.25)
}
