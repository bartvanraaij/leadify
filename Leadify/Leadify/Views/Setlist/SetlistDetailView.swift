import SwiftUI
import SwiftData

struct SetlistDetailView: View {
    @Bindable var setlist: Setlist
    @Environment(\.modelContext) private var context

    @State private var showSongLibrary = false
    @State private var showTacetEdit = false
    @State private var editingEntry: SetlistEntry?
    @State private var showPerformance = false

    var body: some View {
        List {
            ForEach(setlist.sortedEntries) { entry in
                Group {
                    switch entry.itemType {
                    case .song:
                        SongEntryRow(entry: entry) {
                            editingEntry = entry
                        }
                    case .tacet:
                        TacetRow(entry: entry) {
                            editingEntry = entry
                        }
                        .listRowBackground(Color.secondary.opacity(0.07))
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteEntry(entry)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onMove(perform: moveEntries)

            AddEntryRow(
                onAddSong: { showSongLibrary = true },
                onAddTacet: { showTacetEdit = true }
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(.active))
        .navigationTitle(setlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showPerformance = true
                } label: {
                    Label("Perform", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showSongLibrary) {
            SongLibrarySheet(setlist: setlist)
        }
        .sheet(isPresented: $showTacetEdit) {
            TacetEditSheet(entry: nil, setlist: setlist)
        }
        .sheet(item: $editingEntry) { entry in
            switch entry.itemType {
            case .song:
                SongEditorSheet(song: entry.song!)
            case .tacet:
                TacetEditSheet(entry: entry, setlist: setlist)
            }
        }
        .fullScreenCover(isPresented: $showPerformance) {
            if #available(iOS 18.0, *) {
                PerformanceView(setlist: setlist)
            }
        }
    }

    private func moveEntries(from source: IndexSet, to destination: Int) {
        var sorted = setlist.sortedEntries
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, entry) in sorted.enumerated() {
            entry.order = index
        }
    }

    private func deleteEntry(_ entry: SetlistEntry) {
        setlist.entries.removeAll { $0.persistentModelID == entry.persistentModelID }
        context.delete(entry)
    }
}
