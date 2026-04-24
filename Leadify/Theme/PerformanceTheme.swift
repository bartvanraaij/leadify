import SwiftUI
import UIKit
import LeadifyCore

/// All visual constants for Performance Mode.
/// Modern, professional design optimized for stage performance.
/// Supports both light and dark mode.
struct PerformanceTheme {
    // MARK: - Adaptive metrics (font sizes, spacing that varies by size class)

    struct Metrics {
        let songTitleSize: CGFloat
        let sectionHeaderSize: CGFloat
        let chordTextSize: CGFloat
        let reminderFontSize: CGFloat
        let annotationSize: CGFloat
        let tabFontSize: CGFloat
        let medleyTitleSize: CGFloat
        let chordCellWidth: CGFloat
        let itemHorizontalPadding: CGFloat
        let itemInnerVerticalPadding: CGFloat
        let contentIndent: CGFloat
        let plainTextBottomPadding: CGFloat

        let activeIndicatorSize: CGFloat
        let activeIndicatorLeadingOffset: CGFloat
        let activeIndicatorTopPadding: CGFloat

        var chordRowHeight: CGFloat { chordTextSize * chordLineSpacing }

        var annotationBaselineOffset: CGFloat {
            let chordFont = UIFont.systemFont(ofSize: chordTextSize, weight: .semibold)
            let annotationFont = UIFont(name: "Menlo-Bold", size: annotationSize) ?? UIFont.systemFont(ofSize: annotationSize)
            return chordFont.ascender - annotationFont.ascender
        }

        static let regular = Metrics(
            songTitleSize: 32,
            sectionHeaderSize: 22,
            chordTextSize: 28,
            reminderFontSize: 20,
            annotationSize: 22,
            tabFontSize: 20,
            medleyTitleSize: 24,
            chordCellWidth: 88,
            itemHorizontalPadding: 32,
            itemInnerVerticalPadding: 32,
            contentIndent: 16,
            plainTextBottomPadding: 24,
            activeIndicatorSize: 12,
            activeIndicatorLeadingOffset: 12,
            activeIndicatorTopPadding: 44
        )

        static let compact = Metrics(
            songTitleSize: 25,
            sectionHeaderSize: 18,
            chordTextSize: 22,
            reminderFontSize: 16,
            annotationSize: 18,
            tabFontSize: 16,
            medleyTitleSize: 20,
            chordCellWidth: 64,
            itemHorizontalPadding: 16,
            itemInnerVerticalPadding: 24,
            contentIndent: 12,
            plainTextBottomPadding: 16,
            activeIndicatorSize: 10,
            activeIndicatorLeadingOffset: 3,
            activeIndicatorTopPadding: 34
        )
    }

    static func metrics(for sizeClass: UserInterfaceSizeClass?) -> Metrics {
        sizeClass == .compact ? .compact : .regular
    }

    // MARK: - Non-adaptive constants

    static let chordLineSpacing: CGFloat = 2.0
    static let chordMinimumScaleFactor: CGFloat = 0.5
    static let annotationLeadingPadding: CGFloat = 8


    // MARK: - Layout
    static let itemTopMargin: CGFloat = 0
    static let autoSidebarThreshold: CGFloat = 900

    // MARK: - Inspector column
    static let inspectorColumnWidthMin: CGFloat = 220
    static let inspectorColumnWidthIdeal: CGFloat = 280
    static let inspectorColumnWidthMax: CGFloat = 380

    // MARK: - Heading spacing (fraction of heading font size)
    static let headingLineSpacingFraction: CGFloat = 0.1
    static let headingTopPaddingFraction: CGFloat = 0
    static let headingBottomPaddingFraction: CGFloat = 0.5

    // MARK: - Code block
    static let codeBlockVerticalPadding: CGFloat = 24

    // MARK: - Animation durations
    static let navigationAnimationDuration: Double = 0.25
    static let chevronFadeAnimationDuration: Double = 0.2

    // MARK: - Active indicator
    static let activeIndicatorColor = Color.purple
    static let nextIndicatorColor = Color.gray

    // MARK: - Scroll chevrons
    static let chevronEdgePadding: CGFloat = 24

    // MARK: - Reminder
    static let titleReminderSpacing: CGFloat = 12

    // MARK: - Tacet
    static let tacetSpacing: CGFloat = 12
    static let tacetTracking: CGFloat = 2

    // MARK: - Medley
    static let medleyTitleBottomPadding: CGFloat = 8
    static let medleyInnerSongTitleTopPadding: CGFloat = 16

    // MARK: - Base colors
    static let primaryContentColor = Color(light: Color(white: 0.1), dark: Color(white: 0.95))
    static let dimmedContentColor = Color(light: Color(white: 0.45), dark: Color(white: 0.55))
    static let background = Color(light: Color(white: 0.98), dark: Color(white: 0.05))
    static let toolbarScrimColor = Color(light: .black.opacity(0.15), dark: .white.opacity(0.08))

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

    // MARK: - Tab grid
    static let tabGridColor = Color(light: Color(white: 0.7), dark: Color(white: 0.3))

    // MARK: - Neutral elements
    static let dividerColor = Color(light: Color(white: 0.8), dark: Color(white: 0.25))
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

