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
            ForEach(setlist.entries) { entry in
                switch entry.itemType {
                case .song:
                    SongEntryRow(entry: entry) {
                        editingEntry = entry
                    }
                case .tacet:
                    TacetRow(entry: entry) {
                        editingEntry = entry
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                            .foregroundStyle(EditTheme.secondaryText.opacity(0.4))
                    )
                }
            }
            .onMove(perform: moveEntries)
            .onDelete(perform: deleteEntries)

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
            PerformanceView(setlist: setlist)
        }
    }

    private func moveEntries(from source: IndexSet, to destination: Int) {
        setlist.entries.move(fromOffsets: source, toOffset: destination)
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            context.delete(setlist.entries[index])
        }
        setlist.entries.remove(atOffsets: offsets)
    }
}
