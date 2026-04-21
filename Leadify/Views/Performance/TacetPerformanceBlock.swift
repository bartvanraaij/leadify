import SwiftUI
import LeadifyCore

struct TacetPerformanceBlock: View {
    let tacet: Tacet

    private var displayLabel: String {
        if let label = tacet.label, !label.isEmpty {
            return label.uppercased()
        }
        return "TACET"
    }

    var body: some View {
        HStack(spacing: PerformanceTheme.tacetSpacing) {
            Rectangle()
                .fill(PerformanceTheme.dividerColor)
                .frame(height: 1)

            Text(displayLabel)
                .font(
                    .system(
                        size: PerformanceTheme.sectionHeaderSize,
                        weight: .semibold
                    )
                )
                .foregroundStyle(PerformanceTheme.tacetTextColor)
                .tracking(PerformanceTheme.tacetTracking)

            Rectangle()
                .fill(PerformanceTheme.dividerColor)
                .frame(height: 1)
        }
        .padding(.horizontal, PerformanceTheme.itemHorizontalPadding)
        .padding(.vertical, PerformanceTheme.itemInnerVerticalPadding)
    }
}
