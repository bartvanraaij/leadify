import SwiftUI
import SwiftData

struct SetlistDetailView: View {
    @Bindable var setlist: Setlist
    @Environment(\.modelContext) private var context
    @Environment(\.editMode) private var editMode

    @State private var showSongLibrary = false
    @State private var showTacetEdit = false
    @State private var editingEntry: SetlistEntry?
    @State private var showPerformance = false

    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing == true
    }

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
                if !setlist.sortedEntries.isEmpty {
                    EditButton()
                }
            }
            
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !isEditing {
                    Menu {
                        Button {
                            showSongLibrary = true
                        } label: {
                            Label("Add Song", systemImage: "music.note")
                        }
                        
                        Button {
                            showTacetEdit = true
                        } label: {
                            Label("Add Tacet", systemImage: "pause.circle")
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
                
                performButton
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
                
                Text("Tap the + button to add songs or tacet markers")
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
                SongEntryRow(entry: entry, position: position) {
                    editingEntry = entry
                }
            case .tacet:
                TacetRow(entry: entry, position: position) {
                    editingEntry = entry
                }
            }
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

    private func deleteEntry(_ entry: SetlistEntry) {
        withAnimation {
            setlist.entries.removeAll { $0.persistentModelID == entry.persistentModelID }
            context.delete(entry)
        }
    }
}
