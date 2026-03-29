import SwiftUI

/// All visual constants for Ordering/Edit Mode and the Song Editor.
/// Adjust these after testing on the actual iPad.
struct EditTheme {
    // MARK: Font sizes
    static let setlistNameSize: CGFloat = 13
    static let setlistDateSize: CGFloat = 11
    static let songTitleSize: CGFloat = 14
    static let songPreviewSize: CGFloat = 12
    static let reminderSize: CGFloat = 11
    static let editorTitleSize: CGFloat = 16

    // MARK: Colors
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let reminderColor = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let tacetText = Color.secondary
    static let accentColor = Color.accentColor
    static let destructiveColor = Color.red
}
