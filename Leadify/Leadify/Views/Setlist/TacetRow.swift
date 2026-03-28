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
        Button(action: onEdit) {
            HStack {
                Text(displayLabel)
                    .font(.system(size: EditTheme.songPreviewSize))
                    .italic()
                    .foregroundStyle(EditTheme.tacetText)
                Spacer()
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}
