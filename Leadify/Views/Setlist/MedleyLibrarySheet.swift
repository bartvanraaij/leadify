import SwiftUI
import SwiftData
import LeadifyCore

struct MedleyLibrarySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let setlist: Setlist

    @Query(sort: \Medley.name) private var allMedleys: [Medley]

    private var medleysInSetlist: Set<PersistentIdentifier> {
        Set(setlist.entries.compactMap { $0.medley?.persistentModelID })
    }

    private var sortedMedleys: [Medley] {
        let inSetlist = medleysInSetlist
        return allMedleys.sorted { a, b in
            let aIn = inSetlist.contains(a.persistentModelID)
            let bIn = inSetlist.contains(b.persistentModelID)
            if aIn != bIn { return aIn }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(sortedMedleys) { medley in
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
                                Button {
                                    removeMedley(medley)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
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

    private func removeMedley(_ medley: Medley) {
        guard let entry = setlist.sortedEntries.first(where: { $0.medley?.persistentModelID == medley.persistentModelID }) else { return }
        setlist.entries.removeAll { $0.persistentModelID == entry.persistentModelID }
        context.delete(entry)
    }
}
