import SwiftUI
import SwiftData

struct MedleyEditSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var medley: Medley?

    @Query(sort: \Song.title) private var allSongs: [Song]
    @State private var name: String = ""
    @State private var searchText: String = ""
    @State private var selectedSongIDs: Set<PersistentIdentifier> = []

    private var isNew: Bool { medley == nil }

    private var filteredSongs: [Song] {
        guard !searchText.isEmpty else { return allSongs }
        return allSongs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Opening Set", text: $name)
                }

                if isNew {
                    Section("Songs") {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Search songs", text: $searchText)
                        }
                        ForEach(filteredSongs) { song in
                            HStack {
                                Text(song.title)
                                    .font(.body)
                                Spacer()
                                if selectedSongIDs.contains(song.persistentModelID) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(EditTheme.accentColor)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedSongIDs.contains(song.persistentModelID) {
                                    selectedSongIDs.remove(song.persistentModelID)
                                } else {
                                    selectedSongIDs.insert(song.persistentModelID)
                                }
                            }
                        }
                    }
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
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let medley {
            medley.name = trimmed
        } else {
            let newMedley = Medley(name: trimmed)
            context.insert(newMedley)

            // Add selected songs in the order they appear in the library
            for song in allSongs where selectedSongIDs.contains(song.persistentModelID) {
                let entry = MedleyEntry(song: song)
                context.insert(entry)
                newMedley.addEntry(entry)
            }
        }
        dismiss()
    }
}
