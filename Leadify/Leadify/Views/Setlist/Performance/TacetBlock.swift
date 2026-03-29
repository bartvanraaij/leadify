import SwiftUI

struct TacetBlock: View {
    let tacet: Tacet

    private var displayLabel: String {
        if let label = tacet.label, !label.isEmpty {
            return "— \(label) —"
        }
        return "— Tacet —"
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(displayLabel)
                .font(.system(size: PerformanceTheme.sectionHeaderSize))
                .italic()
                .foregroundStyle(PerformanceTheme.tacetTextColor)
                .textCase(.uppercase)
                .tracking(2)
                .padding(.vertical, 10)

            Rectangle()
                .frame(height: 1)
                .foregroundStyle(PerformanceTheme.separatorColor)
        }
        .frame(maxWidth: .infinity)
    }
}
