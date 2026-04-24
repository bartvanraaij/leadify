import SwiftUI
import LeadifyCore

struct TacetPerformanceBlock: View {
    let tacet: Tacet

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var displayLabel: String {
        if let label = tacet.label, !label.isEmpty {
            return label.uppercased()
        }
        return "TACET"
    }

    var body: some View {
        let m = PerformanceTheme.metrics(for: horizontalSizeClass)

        HStack(spacing: PerformanceTheme.tacetSpacing) {
            Rectangle()
                .fill(PerformanceTheme.dividerColor)
                .frame(height: 1)

            Text(displayLabel)
                .font(
                    .system(
                        size: m.sectionHeaderSize,
                        weight: .semibold
                    )
                )
                .foregroundStyle(PerformanceTheme.tacetTextColor)
                .tracking(PerformanceTheme.tacetTracking)

            Rectangle()
                .fill(PerformanceTheme.dividerColor)
                .frame(height: 1)
        }
        .padding(.horizontal, m.itemHorizontalPadding)
        .padding(.vertical, m.itemInnerVerticalPadding)
    }
}
