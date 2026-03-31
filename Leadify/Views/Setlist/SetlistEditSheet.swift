import SwiftUI
import SwiftData

struct SetlistEditSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var setlist: Setlist?

    @State private var name: String = ""
    @State private var date: Date = Date()
    @State private var hasDate: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("e.g. Kermis Arcen", text: $name)
                }
                Section {
                    Toggle("Set date", isOn: $hasDate)
                    if hasDate {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                } header: {
                    Text("Date")
                } footer: {
                    Text("Optional. Shown as dd-MM-yyyy in the setlist list.")
                }
            }
            .navigationTitle(setlist == nil ? "New Setlist" : "Edit Setlist")
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
        guard let setlist else { return }
        name = setlist.name
        if let d = setlist.date {
            date = d
            hasDate = true
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let setlist {
            setlist.name = trimmed
            setlist.date = hasDate ? date : nil
        } else {
            let new = Setlist(name: trimmed, date: hasDate ? date : nil)
            context.insert(new)
        }
        dismiss()
    }
}
