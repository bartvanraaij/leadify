import SwiftUI

/// All visual constants for Performance Mode.
/// Modern, professional design optimized for stage performance.
/// Supports both light and dark mode.
struct PerformanceTheme {
    // MARK: Font sizes
    static let songTitleSize: CGFloat = 28
    static let reminderSize: CGFloat = 17
    static let sectionHeaderSize: CGFloat = 22
    static let chordTextSize: CGFloat = 28
    static let tabFontSize: CGFloat = 16
    static let tabTracking: CGFloat = -1.7

    // MARK: Chord cell layout
    static let chordCellWidth: CGFloat = 88
    static let annotationSize: CGFloat = 22
    static let chordLineSpacing: CGFloat = 2.0

    // MARK: Base colors
    static let primaryContentColor = Color(light: Color(white: 0.1), dark: Color(white: 0.95))
    static let dimmedContentColor = Color(light: Color(white: 0.45), dark: Color(white: 0.55))
    static let background = Color(light: Color(white: 0.98), dark: Color(white: 0.05))

    // MARK: Semantic color aliases — primary content
    static let songTitleColor = primaryContentColor
    static let chordTextColor = primaryContentColor
    static let sidebarTextColor = primaryContentColor

    // MARK: Semantic color aliases — dimmed content
    static let sectionHeaderColor = dimmedContentColor
    static let chordDividerColor = dimmedContentColor
    static let annotationColor = dimmedContentColor
    /// Top padding for annotations so their baseline aligns with chord text baseline.
    static let annotationBaselineOffset: CGFloat = {
        let chordFont = UIFont.systemFont(ofSize: chordTextSize, weight: .semibold)
        let annotationFont = UIFont.systemFont(ofSize: annotationSize)
        return chordFont.ascender - annotationFont.ascender
    }()
    static let tacetTextColor = dimmedContentColor
    static let medleyIndicatorColor = dimmedContentColor

    // MARK: Accent colors
    static let reminderColor = Color(red: 1.0, green: 0.6, blue: 0.0)
    static let tabColor = Color(light: Color(red: 0.3, green: 0.5, blue: 0.4), dark: Color(red: 0.5, green: 0.8, blue: 0.6))

    // MARK: Neutral elements
    static let dividerColor = Color(light: Color(white: 0.88), dark: Color(white: 0.15))
    static let closeButtonColor = Color(light: Color.black.opacity(0.5), dark: Color.white.opacity(0.7))

    // MARK: Medley
    static let medleyTitleSize: CGFloat = 24

    // MARK: Sidebar (wide mode)
    static let sidebarBackground = Color(light: Color(white: 0.94), dark: Color(white: 0.08))
    static let sidebarActiveColor = Color.secondary.opacity(0.2)
    static let sidebarSongSize: CGFloat = 18
    static let sidebarMedleySongSize: CGFloat = 14
    static let sidebarTacetSize: CGFloat = 15
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
