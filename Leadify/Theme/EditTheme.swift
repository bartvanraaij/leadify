import SwiftUI

/// All visual constants for Ordering/Edit Mode and the Song Editor.
/// Adjust these after testing on the actual iPad.
struct EditTheme {
    // MARK: Font sizes
    static let setlistNameSize: CGFloat = 17  // Standard body text size
    static let setlistDateSize: CGFloat = 15  // Standard subheadline size
    static let songTitleSize: CGFloat = 17    // Increased for better readability
    static let songPreviewSize: CGFloat = 12
    static let reminderSize: CGFloat = 11
    static let editorTitleSize: CGFloat = 16
    static let rowNumberSize: CGFloat = 13
    static let rowChevronSize: CGFloat = 11

    // MARK: Colors
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let reminderColor = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let tacetText = Color.secondary
    static let accentColor = Color.accentColor
    static let destructiveColor = Color.red

    // Medley
    static let medleyHeaderColor = Color.accentColor
    static let medleyGroupBackground = Color(light: Color.accentColor.opacity(0.06), dark: Color.accentColor.opacity(0.1))
}
