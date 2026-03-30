import SwiftUI
import SwiftData

struct SongLibrarySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let setlist: Setlist

    @Query(sort: \Song.title) private var allSongs: [Song]
    @State private var searchText = ""
    @State private var showNewSongEditor = false

    private var filteredSongs: [Song] {
        guard !searchText.isEmpty else { return allSongs }
        return allSongs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var songsInSetlist: Set<PersistentIdentifier> {
        Set(setlist.entries.compactMap { $0.song?.persistentModelID })
    }

    private var songsNotInSetlist: [Song] {
        filteredSongs.filter { !songsInSetlist.contains($0.persistentModelID) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(filteredSongs) { song in
                        LibrarySongRow(
                            song: song,
                            isInSetlist: songsInSetlist.contains(song.persistentModelID),
                            onAdd: { addSong(song) }
                        )
                    }
                } header: {
                    HStack {
                        Text("Songs")
                        Spacer()
                        if !songsNotInSetlist.isEmpty {
                            Button("Add All") {
                                addAllSongs()
                            }
                            .font(.subheadline)
                            .textCase(nil)
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search songs")
            .navigationTitle("Add Song to Setlist")
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
        let entry = SetlistEntry(song: song)
        context.insert(entry)
        setlist.addEntry(entry)
    }

    private func addAllSongs() {
        for song in songsNotInSetlist {
            addSong(song)
        }
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
