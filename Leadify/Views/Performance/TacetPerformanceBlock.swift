import SwiftUI

struct TacetPerformanceBlock: View {
    let tacet: Tacet

    private var displayLabel: String {
        if let label = tacet.label, !label.isEmpty {
            return label.uppercased()
        }
        return "TACET"
    }

    var body: some View {
        HStack(spacing: 12) {
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
                .tracking(2)

            Rectangle()
                .fill(PerformanceTheme.dividerColor)
                .frame(height: 1)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, PerformanceTheme.itemInnerVerticalPadding)
    }
}
