import SwiftUI
import SwiftData

struct MedleyEditSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var medley: Medley?
    var onCreate: ((Medley) -> Void)?

    @State private var name: String = ""
    @State private var displayMode: MedleyDisplayMode = .separated

    private var isNew: Bool { medley == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Opening Set", text: $name)
                }

                Section {
                    ForEach(MedleyDisplayMode.allCases, id: \.self) { mode in
                        Button {
                            displayMode = mode
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: displayMode == mode ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(displayMode == mode ? Color.accentColor : Color.secondary)
                                    .font(.title3)
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mode.label)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(mode.explanation)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Performance display")
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
            onCreate?(newMedley)
        }
        dismiss()
    }
}
