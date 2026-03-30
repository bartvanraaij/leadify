import SwiftUI
import SwiftData

struct SongLibrarySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let setlist: Setlist

    @Query(sort: \Song.title) private var allSongs: [Song]
    @State private var searchText = ""
    @State private var showNewSongEditor = false
    @State private var showTacetEdit = false

    private var filteredSongs: [Song] {
        guard !searchText.isEmpty else { return allSongs }
        return allSongs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var songsInSetlist: Set<PersistentIdentifier> {
        Set(setlist.entries.compactMap { $0.song?.persistentModelID })
    }

    var body: some View {
        NavigationStack {
            List {
                // Add Tacet Section
                Section {
                    Button {
                        showTacetEdit = true
                    } label: {
                        HStack {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 22))
                            Text("Add Tacet")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                // Songs Section
                Section {
                    ForEach(filteredSongs) { song in
                        LibrarySongRow(
                            song: song,
                            isInSetlist: songsInSetlist.contains(song.persistentModelID),
                            onAdd: { addSong(song) }
                        )
                    }
                } header: {
                    Text("Songs")
                        .textCase(.uppercase)
                }
            }
            .searchable(text: $searchText, prompt: "Search songs")
            .navigationTitle("Add to Setlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
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
            .sheet(isPresented: $showTacetEdit) {
                TacetEditSheet(entry: nil, setlist: setlist)
            }
        }
    }

    private func addSong(_ song: Song) {
        let entry = SetlistEntry(song: song)
        context.insert(entry)
        setlist.addEntry(entry)
    }
}

private struct LibrarySongRow: View {
    let song: Song
    let isInSetlist: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.body)
                    .fontWeight(.regular)
            }
            Spacer()
            if isInSetlist {
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
        .opacity(isInSetlist ? 0.5 : 1.0)
    }
}
