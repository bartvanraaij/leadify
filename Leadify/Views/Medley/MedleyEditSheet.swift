import SwiftUI
import SwiftData

struct MedleyEditSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var medley: Medley?

    @State private var name: String = ""
    @State private var displayMode: MedleyDisplayMode = .separated

    private var isNew: Bool { medley == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Opening Set", text: $name)
                }

                Section("Performance display") {
                    Picker("Display as", selection: $displayMode) {
                        ForEach(MedleyDisplayMode.allCases, id: \.self) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                    .listRowSeparator(.hidden)

                    Text(displayMode.explanation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(isNew ? "New Medley" : "Edit Medley")
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
        displayMode = medley.displayMode
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let medley {
            medley.name = trimmed
            medley.displayMode = displayMode
        } else {
            let newMedley = Medley(name: trimmed)
            newMedley.displayMode = displayMode
            context.insert(newMedley)
        }
        dismiss()
    }
}
