import SwiftUI
import SwiftData

struct TacetEditSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let entry: SetlistEntry?
    let setlist: Setlist

    @State private var label: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. 15 min, Setlist 2", text: $label)
                } header: {
                    Text("Label")
                } footer: {
                    Text("Optional. Leave empty for a plain pause.")
                }
            }
            .navigationTitle(entry == nil ? "Add Tacet" : "Edit Tacet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                label = entry?.tacet?.label ?? ""
            }
        }
    }

    private func save() {
        let trimmedLabel = label.trimmingCharacters(in: .whitespaces)
        let labelValue = trimmedLabel.isEmpty ? nil : trimmedLabel

        if let entry {
            entry.tacet?.label = labelValue
        } else {
            let tacet = Tacet(label: labelValue)
            context.insert(tacet)
            let newEntry = SetlistEntry(tacet: tacet)
            context.insert(newEntry)
            setlist.addEntry(newEntry)
        }
        dismiss()
    }
}
