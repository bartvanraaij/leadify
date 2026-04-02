import SwiftUI
import SwiftData

struct MedleySongLibrarySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let medley: Medley

    @Query(sort: \Song.title) private var allSongs: [Song]
    @State private var searchText = ""
    @State private var showNewSongEditor = false

    private var filteredSongs: [Song] {
        let base: [Song]
        if searchText.isEmpty {
            base = allSongs
        } else {
            base = allSongs.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }
        let inMedley = songsInMedley
        return base.sorted { a, b in
            let aIn = inMedley.contains(a.persistentModelID)
            let bIn = inMedley.contains(b.persistentModelID)
            if aIn != bIn { return aIn }
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
    }

    private var songsInMedley: Set<PersistentIdentifier> {
        Set(medley.entries.map { $0.song.persistentModelID })
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Songs") {
                    ForEach(filteredSongs) { song in
                        MedleyLibrarySongRow(
                            song: song,
                            isInMedley: songsInMedley.contains(song.persistentModelID),
                            onAdd: { addSong(song) },
                            onRemove: { removeSong(song) }
                        )
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search songs")
            .navigationTitle("Add Song to Medley")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewSongEditor = true
                    } label: {
                        Label("New Song", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewSongEditor) {
                SongEditorSheet(song: nil, onSave: { newSong in
                    addSong(newSong)
                })
            }
        }
    }

    private func addSong(_ song: Song) {
        let entry = MedleyEntry(song: song)
        context.insert(entry)
        medley.addEntry(entry)
        searchText = ""
    }

    private func removeSong(_ song: Song) {
        guard let entry = medley.sortedEntries.first(where: { $0.song.persistentModelID == song.persistentModelID }) else { return }
        medley.entries.removeAll { $0.persistentModelID == entry.persistentModelID }
        context.delete(entry)
    }
}

private struct MedleyLibrarySongRow: View {
    let song: Song
    let isInMedley: Bool
    let onAdd: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.body)
                    .fontWeight(.regular)
            }
            Spacer()
            if isInMedley {
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
