import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum SongSortOrder {
    case alphabetical
    case dateAdded
}

struct SongLibrarySidebarView: View {
    @Query private var allSongs: [Song]
    @Binding var selectedSong: Song?
    @Environment(\.modelContext) private var context
    @Environment(SongImporter.self) private var songImporter

    @State private var sortOrder: SongSortOrder = .alphabetical
    @State private var songToDelete: Song?
    @State private var showDeleteConfirmation = false
    @State private var showFileImporter = false
    @State private var showPerformance = false

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
                NavigationLink(value: song) {
                    SongLibraryRow(song: song, isSelected: selectedSong?.persistentModelID == song.persistentModelID)
                }
                .listRowBackground(
                    selectedSong?.persistentModelID == song.persistentModelID
                        ? RoundedRectangle(cornerRadius: 22, style: .continuous).fill(EditTheme.accentColor)
                        : nil
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        songToDelete = song
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .labelStyle(.iconOnly)
                    }
                    .tint(.red)

                    Button {
                        let copy = song.duplicate(in: context)
                        selectedSong = copy
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                            .labelStyle(.iconOnly)
                    }
                    .tint(.blue)
                }
                .contextMenu {
                    Button {
                        let copy = song.duplicate(in: context)
                        selectedSong = copy
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }

                    Divider()

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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        showPerformance = true
                    } label: {
                        Label("Perform all", systemImage: "play.circle")
                    }
                    .disabled(allSongs.isEmpty)

                    Button {
                        showFileImporter = true
                    } label: {
                        Label("Import songs", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Label("Options", systemImage: "ellipsis.circle")
                        .labelStyle(.iconOnly)
                }
            }
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text("Songs")
                        .font(.headline)
                    Text("\(allSongs.count) song\(allSongs.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let newSong = Song(title: "", content: "")
                    context.insert(newSong)
                    selectedSong = newSong
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .fullScreenCover(isPresented: $showPerformance) {
            PerformanceView(source: SongCollection(
                performanceTitle: "All songs",
                songs: sortedSongs
            ))
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.plainText],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                songImporter.importFiles(urls: urls, context: context)
            case .failure(let error):
                songImporter.errorMessage = error.localizedDescription
                songImporter.showErrorAlert = true
            }
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
    let isSelected: Bool

    var body: some View {
        Text(song.title.isEmpty ? "New Song" : song.title)
            .font(.body)
            .fontWeight(.medium)
            .foregroundStyle(isSelected ? .white : (song.title.isEmpty ? .secondary : .primary))
            .padding(.vertical, 4)
    }
}
