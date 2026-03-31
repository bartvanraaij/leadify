import SwiftUI
import SwiftData

struct SetlistDetailView: View {
    @Bindable var setlist: Setlist
    @Binding var selectedSetlist: Setlist?
    @Environment(\.modelContext) private var context

    @State private var showSongLibrary = false
    @State private var showTacetEdit = false
    @State private var showMedleyLibrary = false
    @State private var editingEntry: SetlistEntry?
    @State private var editingSongFromMedley: Song?
    @State private var showPerformance = false
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false

    var body: some View {
        List {
            if setlist.sortedEntries.isEmpty {
                emptyStateView
            } else {
                entriesSection
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(setlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                setlistMenu
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showTacetEdit = true
                } label: {
                    Label("Add Tacet", systemImage: "hourglass.badge.plus")
                }
                Button {
                    showMedleyLibrary = true
                } label: {
                    Label("Add Medley", systemImage: "music.quarternote.3")
                }
                Button {
                    showSongLibrary = true
                } label: {
                    Label("Add Song", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                performButton
            }
        }
        .sheet(isPresented: $showSongLibrary) {
            SongLibrarySheet(setlist: setlist)
        }
        .sheet(isPresented: $showTacetEdit) {
            TacetEditSheet(entry: nil, setlist: setlist)
        }
        .sheet(isPresented: $showMedleyLibrary) {
            MedleyLibrarySheet(setlist: setlist)
        }
        .sheet(item: $editingSongFromMedley) { song in
            SongEditorSheet(song: song)
        }
        .sheet(item: $editingEntry) { entry in
            switch entry.itemType {
            case .song:
                SongEditorSheet(song: entry.song!)
            case .tacet:
                TacetEditSheet(entry: entry, setlist: setlist)
            case .medley:
                EmptyView() // Medley entries are not individually editable from setlist
            }
        }
        .fullScreenCover(isPresented: $showPerformance) {
            PerformanceView(setlist: setlist)
        }
        .sheet(isPresented: $showEditSheet) {
            SetlistEditSheet(setlist: setlist)
        }
        .alert("Delete \"\(setlist.name)\"?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { deleteSetlist() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the setlist and all its entries. Songs in your library are not affected.")
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                Text("No songs yet")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("Tap + to add songs or tacet markers")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }

    private var entriesSection: some View {
        Section {
            ForEach(Array(setlist.sortedEntries.enumerated()), id: \.element.persistentModelID) { index, entry in
                entryRow(entry: entry, position: index + 1)
                
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteEntry(entry)
                    } label: {
                        Label("", systemImage: "trash")
                    }
                }
              
            }
            .onMove(perform: moveEntries)
            .onDelete(perform: deleteEntries)
        }
    }

    private func entryRow(entry: SetlistEntry, position: Int) -> some View {
        Group {
            switch entry.itemType {
            case .song:
                SongSetlistRow(entry: entry, position: position) {
                    editingEntry = entry
                }
            case .tacet:
                TacetSetlistRow(entry: entry, position: position) {
                    editingEntry = entry
                }
            case .medley:
                MedleySetlistGroup(entry: entry) { song in
                    editingSongFromMedley = song
                }
            }
        }
    }

    private var setlistMenu: some View {
        Menu {
            Button {
                showEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button {
                duplicateSetlist()
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }

            Divider()

            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Label("Options", systemImage: "ellipsis.circle")
                .labelStyle(.iconOnly)
        }
    }

    private var performButton: some View {
        Button {
            showPerformance = true
        } label: {
            Label("Perform", systemImage: "play.circle.fill")
                .labelStyle(.iconOnly)
                .font(.system(size: 20))
        }
        .disabled(setlist.sortedEntries.isEmpty)
    }

    // MARK: - Actions

    private func moveEntries(from source: IndexSet, to destination: Int) {
        var sorted = setlist.sortedEntries
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, entry) in sorted.enumerated() {
            entry.order = index
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            let entry = setlist.sortedEntries[index]
            deleteEntry(entry)
        }
    }

    private func duplicateSetlist() {
        let copy = setlist.duplicate(in: context)
        selectedSetlist = copy
    }

    private func deleteSetlist() {
        selectedSetlist = nil
        context.delete(setlist)
    }

    private func deleteEntry(_ entry: SetlistEntry) {
        withAnimation {
            setlist.entries.removeAll { $0.persistentModelID == entry.persistentModelID }
            context.delete(entry)
        }
    }
}
