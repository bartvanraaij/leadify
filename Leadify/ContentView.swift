import SwiftUI
import SwiftData

enum SidebarMode {
    case setlists, songs
}

struct ContentView: View {
    @Query private var allSetlists: [Setlist]
    @Environment(\.modelContext) private var modelContext
    @Environment(SongImporter.self) private var songImporter
    @Binding var sidebarMode: SidebarMode
    @State private var selectedSetlist: Setlist?
    @State private var selectedSong: Song?
    @State private var isEditingSong = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var sortedSetlists: [Setlist] {
        allSetlists.sorted { a, b in
            switch (a.date, b.date) {
            case (let d1?, let d2?): return d1 > d2
            case (nil, _): return false
            case (_, nil): return true
            }
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            Group {
                switch sidebarMode {
                case .setlists:
                    SetlistSidebarView(
                        setlists: sortedSetlists,
                        selectedSetlist: $selectedSetlist
                    )
                case .songs:
                    SongLibrarySidebarView(selectedSong: $selectedSong)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(sidebarMode == .setlists ? "Setlists" : "Songs")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    Picker("", selection: $sidebarMode) {
                        Text("Setlists").tag(SidebarMode.setlists)
                        Text("Songs").tag(SidebarMode.songs)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.bar)
            }
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        } detail: {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                switch sidebarMode {
                case .setlists:
                    if let setlist = selectedSetlist {
                        SetlistDetailView(setlist: setlist)
                    } else {
                        ContentUnavailableView(
                            "No Setlist Selected",
                            systemImage: "music.note.list",
                            description: Text("Select a setlist from the sidebar or create a new one.")
                        )
                    }
                case .songs:
                    if let song = selectedSong {
                        if isEditingSong {
                            SongEditorDetailView(song: song, selectedSong: $selectedSong, isEditing: $isEditingSong)
                                .id("\(song.persistentModelID)-edit")
                        } else {
                            SongDisplayView(song: song, selectedSong: $selectedSong, isEditing: $isEditingSong)
                                .id(song.persistentModelID)
                        }
                    } else {
                        ContentUnavailableView(
                            "No Song Selected",
                            systemImage: "music.note",
                            description: Text("Select a song from the library to edit it.")
                        )
                    }
                }
            }
        }
        .onChange(of: selectedSong) {
            // New songs (from + button) go straight to edit mode
            if let song = selectedSong, song.title.isEmpty && song.content.isEmpty {
                isEditingSong = true
            } else {
                isEditingSong = false
            }
        }
        .navigationSplitViewStyle(.balanced)
        .confirmationDialog(
            "Song Already Exists",
            isPresented: Bindable(songImporter).showConflictDialog,
            titleVisibility: .visible
        ) {
            Button("Overwrite") {
                songImporter.resolveConflict(.overwrite, context: modelContext)
            }
            Button("Keep Both") {
                songImporter.resolveConflict(.keepBoth, context: modelContext)
            }
            if songImporter.hasRemainingConflicts {
                Button("Overwrite All") {
                    songImporter.resolveConflict(.overwriteAll, context: modelContext)
                }
                Button("Skip All") {
                    songImporter.resolveConflict(.skipAll, context: modelContext)
                }
            }
            Button("Skip", role: .cancel) {
                songImporter.resolveConflict(.skip, context: modelContext)
            }
        } message: {
            if let title = songImporter.conflictParsedSong?.title {
                Text("A song titled \"\(title)\" already exists.")
            }
        }
        .alert("Import Error", isPresented: Bindable(songImporter).showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(songImporter.errorMessage)
        }
        .alert("Import Complete", isPresented: Bindable(songImporter).showImportSummary) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(songImporter.importSummaryMessage)
        }
    }
}

#Preview {
    ContentView(sidebarMode: .constant(.setlists))
        .modelContainer(for: [Song.self, Tacet.self, SetlistEntry.self, Setlist.self],
                        inMemory: true)
        .environment(SongImporter())
}
