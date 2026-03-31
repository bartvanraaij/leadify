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
        guard !searchText.isEmpty else { return allSongs }
        return allSongs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
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
                            onAdd: { addSong(song) }
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
    }
}

private struct MedleyLibrarySongRow: View {
    let song: Song
    let isInMedley: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.body)
                    .fontWeight(.regular)
            }
            Spacer()
            if isInMedley {
                Image(systemName: "checkmark")
                    .foregroundStyle(.secondary)
            } else {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(isInMedley ? 0.5 : 1.0)
    }
}
