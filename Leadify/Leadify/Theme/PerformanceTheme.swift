import SwiftUI

/// All visual constants for Performance Mode.
/// Colors are adaptive — they respond to light / dark mode automatically.
struct PerformanceTheme {
    // MARK: Font sizes
    static let songTitleSize: CGFloat = 28
    static let reminderSize: CGFloat = 18
    static let sectionHeaderSize: CGFloat = 16
    static let chordTextSize: CGFloat = 26       // bumped from 22
    static let tabFontSize: CGFloat = 18
    static let upNextSize: CGFloat = 14

    // MARK: Colors
    static let background = Color(UIColor.systemBackground)
    static let songTitleColor = Color.primary
    static let chordTextColor = Color.primary
    static let sectionHeaderColor = Color.secondary
    static let reminderColor = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let tabColor = Color.primary          // was hard-coded green
    static let tacetTextColor = Color.secondary
    static let tacetDividerColor = Color.primary.opacity(0.12)
    static let upNextColor = Color.secondary
    static let tapZoneIndicatorColor = Color.primary.opacity(0.3)
    static let closeButtonColor = Color.primary.opacity(0.5)
    static let closeButtonBackground = Color.primary.opacity(0.08)
}
