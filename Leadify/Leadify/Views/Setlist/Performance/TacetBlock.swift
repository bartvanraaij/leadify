import SwiftUI

struct TacetBlock: View {
    let tacet: Tacet
    let entryID: String
    let viewModel: PerformanceViewModel

    private var displayLabel: String {
        if let label = tacet.label, !label.isEmpty {
            return "— \(label) —"
        }
        return "— Tacet —"
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color(white: 0.15))

            Text(displayLabel)
                .font(.system(size: PerformanceTheme.sectionHeaderSize))
                .italic()
                .foregroundStyle(PerformanceTheme.tacetTextColor)
                .textCase(.uppercase)
                .tracking(2)
                .padding(.vertical, 10)

            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color(white: 0.15))
        }
        .frame(maxWidth: .infinity)
        .onAppear { viewModel.markVisible(entryID) }
        .onDisappear { viewModel.markHidden(entryID) }
    }
}
