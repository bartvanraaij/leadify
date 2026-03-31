import SwiftUI
import SwiftData

struct MedleyLibrarySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let setlist: Setlist

    @Query(sort: \Medley.name) private var allMedleys: [Medley]

    private var medleysInSetlist: Set<PersistentIdentifier> {
        Set(setlist.entries.compactMap { $0.medley?.persistentModelID })
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(allMedleys) { medley in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(medley.name)
                                    .font(.body)
                                    .fontWeight(.regular)
                                Text("\(medley.entries.count) song\(medley.entries.count == 1 ? "" : "s")")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if medleysInSetlist.contains(medley.persistentModelID) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.secondary)
                            } else {
                                Button {
                                    addMedley(medley)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .opacity(medleysInSetlist.contains(medley.persistentModelID) ? 0.5 : 1.0)
                    }
                }
            }
            .navigationTitle("Add Medley to Setlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func addMedley(_ medley: Medley) {
        let entry = SetlistEntry(medley: medley)
        context.insert(entry)
        setlist.addEntry(entry)
    }
}
