import SwiftUI

/// All visual constants for Performance Mode.
/// Modern, professional design optimized for stage performance.
/// Supports both light and dark mode.
struct PerformanceTheme {
    // MARK: Font sizes
    static let songTitleSize: CGFloat = 28
    static let reminderSize: CGFloat = 17
    static let sectionHeaderSize: CGFloat = 20
    static let chordTextSize: CGFloat = 28
    static let tabFontSize: CGFloat = 16
    static let tabTracking: CGFloat = -1.7

    // MARK: Colors - Modern, professional palette
    static let background = Color(light: Color(white: 0.98), dark: Color(white: 0.05))
    
    // Monochrome with high contrast - professional and timeless
    static let songTitleColor = Color(light: Color(white: 0.1), dark: Color(white: 0.95))
    static let chordTextColor = Color(light: Color(white: 0.15), dark: Color(white: 0.9))
    static let sectionHeaderColor = Color(light: Color(white: 0.35), dark: Color(white: 0.6))
    
    // Accent - warm orange for reminders
    static let reminderColor = Color(red: 1.0, green: 0.6, blue: 0.0)
    
    // Subtle color for tabs
    static let tabColor = Color(light: Color(red: 0.3, green: 0.5, blue: 0.4), dark: Color(red: 0.5, green: 0.8, blue: 0.6))
    
    // Neutral elements
    static let tacetTextColor = Color(light: Color(white: 0.45), dark: Color(white: 0.55))
    static let dividerColor = Color(light: Color(white: 0.88), dark: Color(white: 0.15))
    static let closeButtonColor = Color(light: Color.black.opacity(0.5), dark: Color.white.opacity(0.7))

    // Medley
    static let medleyTitleSize: CGFloat = 24
    static let medleyIndicatorColor = Color(light: Color(white: 0.5), dark: Color(white: 0.5))

    // Sidebar (wide mode)
    static let sidebarBackground = Color(light: Color(white: 0.94), dark: Color(white: 0.08))
    static let sidebarActiveColor = EditTheme.accentColor
    static let sidebarTextColor = Color(light: Color(white: 0.3), dark: Color(white: 0.7))
}

// Helper extension for adaptive colors
extension Color {
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor(dynamicProvider: { traits in
            switch traits.userInterfaceStyle {
            case .light, .unspecified:
                return UIColor(light)
            case .dark:
                return UIColor(dark)
            @unknown default:
                return UIColor(light)
            }
        }))
    }
}
