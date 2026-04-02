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
        let base: [Song]
        if searchText.isEmpty {
            base = allSongs
        } else {
            base = allSongs.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }
        let inSetlist = songsInSetlist
        return base.sorted { a, b in
            let aIn = inSetlist.contains(a.persistentModelID)
            let bIn = inSetlist.contains(b.persistentModelID)
            if aIn != bIn { return aIn }
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
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
                            onAdd: { addSong(song) },
                            onRemove: { removeSong(song) }
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
        searchText = ""
    }

    private func removeSong(_ song: Song) {
        guard let entry = setlist.sortedEntries.first(where: { $0.song?.persistentModelID == song.persistentModelID }) else { return }
        setlist.entries.removeAll { $0.persistentModelID == entry.persistentModelID }
        context.delete(entry)
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
    let onRemove: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.body)
                    .fontWeight(.regular)
            }
            Spacer()
            if isInSetlist {
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
