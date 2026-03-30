import SwiftUI
import SwiftData

enum SongSortOrder {
    case alphabetical
    case dateAdded
}

struct SongLibrarySidebarView: View {
    @Query private var allSongs: [Song]
    @Binding var selectedSong: Song?
    @Environment(\.modelContext) private var context

    @State private var sortOrder: SongSortOrder = .alphabetical
    @State private var songToDelete: Song?
    @State private var showDeleteConfirmation = false
    @State private var showNewSongSheet = false

    var sortedSongs: [Song] {
        switch sortOrder {
        case .alphabetical:
            return allSongs.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        case .dateAdded:
            return allSongs.sorted { $0.createdAt > $1.createdAt }
        }
    }

    var body: some View {
        List(selection: $selectedSong) {
            ForEach(sortedSongs) { song in
                SongLibraryRow(song: song)
                    .tag(song)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            songToDelete = song
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewSongSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort", selection: $sortOrder) {
                        Text("A → Z").tag(SongSortOrder.alphabetical)
                        Text("Date Added").tag(SongSortOrder.dateAdded)
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
        .sheet(isPresented: $showNewSongSheet) {
            SongEditorSheet(song: nil, onSave: { newSong in
                selectedSong = newSong
            })
        }
        .alert("Delete Song", isPresented: $showDeleteConfirmation, presenting: songToDelete) { song in
            Button("Delete \"\(song.title)\"", role: .destructive) {
                if selectedSong == song { selectedSong = nil }
                context.delete(song)
            }
            Button("Cancel", role: .cancel) {}
        } message: { song in
            Text("This will remove \"\(song.title)\" from all setlists. This cannot be undone.")
        }
    }
}

private struct SongLibraryRow: View {
    let song: Song

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(song.title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            Text(song.createdAt, style: .date)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
