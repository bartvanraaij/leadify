import SwiftUI
import LeadifyCore

struct TacetSetlistRow: View {
    let entry: SetlistEntry
    let position: Int
    let onEdit: () -> Void
    
    @Environment(\.editMode) private var editMode

    private var tacet: Tacet { entry.tacet! }
    
    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    private var displayLabel: String {
        if let label = tacet.label, !label.isEmpty {
            return "— \(label) —"
        }
        return "— Tacet —"
    }

    var body: some View {
        Text(displayLabel)
            .font(.body)
            .fontWeight(.regular)
            .italic()
            .foregroundStyle(.secondary)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onEdit)
    }
}
