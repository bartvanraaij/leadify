import SwiftUI
import SwiftData

enum SidebarMode {
    case setlists, songs
}

struct ContentView: View {
    @Query private var allSetlists: [Setlist]
    @State private var sidebarMode: SidebarMode = .setlists
    @State private var selectedSetlist: Setlist?
    @State private var selectedSong: Song?
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
                Picker("", selection: $sidebarMode) {
                    Text("Setlists").tag(SidebarMode.setlists)
                    Text("Songs").tag(SidebarMode.songs)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.bar)
            }
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        } detail: {
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
                    SongEditorDetailView(song: song, selectedSong: $selectedSong)
                } else {
                    ContentUnavailableView(
                        "No Song Selected",
                        systemImage: "music.note",
                        description: Text("Select a song from the library to edit it.")
                    )
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Song.self, Tacet.self, SetlistEntry.self, Setlist.self],
                        inMemory: true)
}
