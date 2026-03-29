import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var allSetlists: [Setlist]
    @State private var selectedSetlist: Setlist?

    /// Setlists sorted by date descending; undated setlists at the bottom.
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
        NavigationSplitView {
            SetlistSidebarView(
                setlists: sortedSetlists,
                selectedSetlist: $selectedSetlist
            )
        } detail: {
            if let setlist = selectedSetlist {
                SetlistDetailView(setlist: setlist)
            } else {
                ContentUnavailableView(
                    "No Setlist Selected",
                    systemImage: "music.note.list",
                    description: Text("Select a setlist from the sidebar or create a new one.")
                )
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Song.self, Tacet.self, SetlistEntry.self, Setlist.self],
                        inMemory: true)
}
