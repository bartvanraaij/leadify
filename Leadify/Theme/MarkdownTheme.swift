import MarkdownUI
import SwiftUI

//
//  MarkdownTheme.swift
//  Leadify
//
//  Created by Bart van Raaij on 31/03/2026.
//


// MARK: - Custom MarkdownUI theme

extension MarkdownUI.Theme {
    static let leadifyPerformance = Theme()
        .heading1 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(PerformanceTheme.songTitleSize)
                    FontWeight(.bold)
                    ForegroundColor(PerformanceTheme.songTitleColor)
                }
                .relativeLineSpacing(.em(0.1))
                .markdownMargin(top: .em(0.8), bottom: .em(0.2))
        }
        .heading2 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(PerformanceTheme.sectionHeaderSize)
                    FontWeight(.semibold)
                    ForegroundColor(PerformanceTheme.sectionHeaderColor)
                }
                .relativeLineSpacing(.em(0.1))
                .markdownMargin(top: .em(0.8), bottom: .em(0.2))
        }
        .paragraph { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(PerformanceTheme.chordTextSize)
                    FontWeight(.semibold)
                    ForegroundColor(PerformanceTheme.chordTextColor)
                }
        }
        .codeBlock { configuration in
            configuration.label
                .markdownTextStyle {
                    FontFamilyVariant(.monospaced)
                    FontSize(PerformanceTheme.tabFontSize)
                    ForegroundColor(PerformanceTheme.tabColor)
                }
                .padding(.vertical, 4)
        }
}
