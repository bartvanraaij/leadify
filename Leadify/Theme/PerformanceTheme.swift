import SwiftUI
import UIKit

/// All visual constants for Performance Mode.
/// Modern, professional design optimized for stage performance.
/// Supports both light and dark mode.
struct PerformanceTheme {
    // MARK: - Font sizes
    static let songTitleSize: CGFloat = 28
    static let reminderSize: CGFloat = 17
    static let sectionHeaderSize: CGFloat = 22
    static let chordTextSize: CGFloat = 28

    // MARK: - Layout
    static let itemHorizontalPadding: CGFloat = 32
    static let itemInnerVerticalPadding: CGFloat = 32
    static let itemTopMargin: CGFloat = 0
    static let autoSidebarThreshold: CGFloat = 900

    // MARK: - Inspector column
    static let inspectorColumnWidthMin: CGFloat = 220
    static let inspectorColumnWidthIdeal: CGFloat = 280
    static let inspectorColumnWidthMax: CGFloat = 380

    // MARK: - Chord cell layout
    static let chordCellWidth: CGFloat = 88
    static let annotationSize: CGFloat = 22
    static let chordLineSpacing: CGFloat = 2.0
    static let chordRowHeight: CGFloat = chordTextSize * chordLineSpacing
    static let chordMinimumScaleFactor: CGFloat = 0.5
    static let annotationLeadingPadding: CGFloat = 8

    /// Top padding for annotations so their baseline aligns with chord text baseline.
    static let annotationBaselineOffset: CGFloat = {
        let chordFont = UIFont.systemFont(ofSize: chordTextSize, weight: .semibold)
        let annotationFont = UIFont.systemFont(ofSize: annotationSize)
        return chordFont.ascender - annotationFont.ascender
    }()

    // MARK: - Heading spacing (fraction of heading font size)
    static let headingLineSpacingFraction: CGFloat = 0.1
    static let headingTopPaddingFraction: CGFloat = 0
    static let headingBottomPaddingFraction: CGFloat = 0.2

    // MARK: - Code block
    static let tabFontSize: CGFloat = 18
    static let tabTracking: CGFloat = -2.2
    static let codeBlockVerticalPadding: CGFloat = 4
    /// Compression multiplier for tab/code block line spacing. Values closer to 1.0 = less compression = more spacing between lines.
    static let codeBlockLineCompressionMultiplier: CGFloat = 1.15
    /// Extra bottom padding added beneath overlapped code blocks to prevent adjacent content overlap.
    static let codeBlockExtraBottomPadding: CGFloat = 24

    // MARK: - Animation durations
    static let navigationAnimationDuration: Double = 0.25
    static let dimmingAnimationDuration: Double = 0.3
    static let chevronFadeAnimationDuration: Double = 0.2

    // MARK: - Dimming
    static let inactiveItemOpacity: Double = 0.6

    // MARK: - Scroll chevrons
    static let chevronEdgePadding: CGFloat = 24

    // MARK: - Reminder badge
    static let reminderFontSize: CGFloat = 20
    static let reminderHorizontalPadding: CGFloat = 16
    static let reminderVerticalPadding: CGFloat = 8
    static let reminderCornerRadius: CGFloat = 12
    static let titleReminderSpacing: CGFloat = 12

    // MARK: - Tacet
    static let tacetSpacing: CGFloat = 12
    static let tacetTracking: CGFloat = 2

    // MARK: - Medley
    static let medleyTitleSize: CGFloat = 24
    static let medleyTitleBottomPadding: CGFloat = 24
    static let medleyInnerSongTitleTopPadding: CGFloat = 16

    // MARK: - Base colors
    static let primaryContentColor = Color(light: Color(white: 0.1), dark: Color(white: 0.95))
    static let dimmedContentColor = Color(light: Color(white: 0.45), dark: Color(white: 0.55))
    static let background = Color(light: Color(white: 0.98), dark: Color(white: 0.05))

    // MARK: - Semantic color aliases — primary content
    static let songTitleColor = primaryContentColor
    static let chordTextColor = primaryContentColor
    static let sidebarTextColor = primaryContentColor

    // MARK: - Semantic color aliases — dimmed content
    static let sectionHeaderColor = dimmedContentColor
    static let chordDividerColor = dimmedContentColor
    static let annotationColor = dimmedContentColor
    static let tacetTextColor = dimmedContentColor
    static let medleyIndicatorColor = dimmedContentColor

    // MARK: - Accent colors
    static let reminderColor = Color(red: 1.0, green: 0.6, blue: 0.0)
    static let tabColor = Color(light: Color(red: 0.3, green: 0.5, blue: 0.4), dark: Color(red: 0.5, green: 0.8, blue: 0.6))

    // MARK: - Neutral elements
    static let dividerColor = dimmedContentColor
    static let dividerHeight:CGFloat = 1
    // MARK: - Sidebar (wide mode)
    static let sidebarBackground = Color(light: Color(white: 0.94), dark: Color(white: 0.08))
    static let sidebarActiveColor = Color.secondary.opacity(0.2)
    static let sidebarSongSize: CGFloat = 18
    static let sidebarMedleySongSize: CGFloat = 14
    static let sidebarTacetSize: CGFloat = 15
    static let sidebarTitleHorizontalPadding: CGFloat = 22
    static let sidebarDividerHorizontalPadding: CGFloat = 16
    static let sidebarSectionSpacing: CGFloat = 14
    static let sidebarSmallSpacing: CGFloat = 8
    static let sidebarTightSpacing: CGFloat = 4
    static let sidebarRowHorizontalPadding: CGFloat = 14
    static let sidebarRowVerticalPadding: CGFloat = 10
    static let sidebarTacetRowVerticalPadding: CGFloat = 6
    static let sidebarRowCornerRadius: CGFloat = 22
    static let sidebarNavButtonSize: CGFloat = 40
    static let sidebarNavDisabledOpacity: Double = 0.3
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

