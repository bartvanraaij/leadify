import SwiftUI

struct TacetRow: View {
    let entry: SetlistEntry
    let onEdit: () -> Void

    private var tacet: Tacet { entry.tacet! }

    private var displayLabel: String {
        if let label = tacet.label, !label.isEmpty {
            return "— \(label) —"
        }
        return "— Tacet —"
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(EditTheme.secondaryText)

            Text(displayLabel)
                .font(.system(size: EditTheme.songPreviewSize))
                .italic()
                .foregroundStyle(EditTheme.tacetText)

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundStyle(EditTheme.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }
}
