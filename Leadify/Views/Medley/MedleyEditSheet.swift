import SwiftUI
import SwiftData

struct MedleyEditSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var medley: Medley?

    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Opening Set", text: $name)
                }
            }
            .navigationTitle(medley == nil ? "New Medley" : "Edit Medley")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadExistingValues() }
        }
    }

    private func loadExistingValues() {
        guard let medley else { return }
        name = medley.name
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let medley {
            medley.name = trimmed
        } else {
            let new = Medley(name: trimmed)
            context.insert(new)
        }
        dismiss()
    }
}
