import SwiftUI
import SwiftData

enum SidebarItem: String, CaseIterable, Identifiable {
    case setlists
    case songs
    case medleys

    var id: String { rawValue }

    var title: String {
        switch self {
        case .setlists: "Setlists"
        case .songs: "Songs"
        case .medleys: "Medleys"
        }
    }

    var icon: String {
        switch self {
        case .setlists: "music.note.list"
        case .songs: "music.note"
        case .medleys: "rectangle.stack.fill"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SongImporter.self) private var songImporter
    @Query private var allSetlists: [Setlist]

    @State private var selectedSidebarItem: SidebarItem? = .setlists
    @State private var selectedSetlist: Setlist?
    @State private var selectedSong: Song?
    @State private var isEditingSong = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedMedley: Medley?
    @Query private var allMedleys: [Medley]

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
            List(SidebarItem.allCases, selection: $selectedSidebarItem) { item in
                NavigationLink(value: item) {
                    Label(item.title, systemImage: item.icon)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 240)
        } content: {
            Group {
                switch selectedSidebarItem {
                case .setlists:
                    SetlistSidebarView(
                        setlists: sortedSetlists,
                        selectedSetlist: $selectedSetlist
                    )
                case .songs:
                    SongLibrarySidebarView(selectedSong: $selectedSong)
                case .medleys:
                    MedleySidebarView(selectedMedley: $selectedMedley)
                case nil:
                    ContentUnavailableView(
                        "Select a Category",
                        systemImage: "sidebar.left",
                        description: Text("Choose Setlists, Songs, or Medleys from the sidebar.")
                    )
                }
            }
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        } detail: {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                switch selectedSidebarItem {
                case .setlists:
                    if let setlist = selectedSetlist {
                        SetlistDetailView(setlist: setlist, selectedSetlist: $selectedSetlist)
                    } else {
                        ContentUnavailableView(
                            "No Setlist Selected",
                            systemImage: "music.note.list",
                            description: Text("Select a setlist or create a new one.")
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
                case .medleys:
                    if let medley = selectedMedley {
                        MedleyDetailView(medley: medley, selectedMedley: $selectedMedley)
                    } else {
                        ContentUnavailableView(
                            "No Medley Selected",
                            systemImage: "rectangle.stack.fill",
                            description: Text("Select a medley or create a new one.")
                        )
                    }
                case nil:
                    Color.clear
                }
            }
        }
        .onChange(of: selectedSong) {
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
    ContentView()
        .modelContainer(for: [Song.self, Tacet.self, SetlistEntry.self, Setlist.self, Medley.self, MedleyEntry.self],
                        inMemory: true)
        .environment(SongImporter())
}
