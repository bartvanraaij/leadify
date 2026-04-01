import SwiftUI
import SwiftData

struct MedleyDetailView: View {
    @Bindable var medley: Medley
    @Binding var selectedMedley: Medley?
    @Environment(\.modelContext) private var context

    @State private var showSongLibrary = false
    @State private var editingEntry: MedleyEntry?
    @State private var showPerformance = false
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false

    var body: some View {
        List {
            if medley.sortedEntries.isEmpty {
                emptyStateView
            } else {
                entriesSection
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(medley.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                medleyMenu
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSongLibrary = true
                } label: {
                    Label("Add Song", image: "custom.music.note.badge.plus")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                performButton
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .sheet(isPresented: $showSongLibrary) {
            MedleySongLibrarySheet(medley: medley)
        }
        .sheet(item: $editingEntry) { entry in
            SongEditorSheet(song: entry.song)
        }
        .fullScreenCover(isPresented: $showPerformance) {
            PerformanceView(source: medley)
        }
        .sheet(isPresented: $showEditSheet) {
            MedleyEditSheet(medley: medley)
        }
        .alert("Delete \"\(medley.name)\"?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { deleteMedley() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the medley. Songs in your library are not affected.")
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "music.quarternote.3")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("No songs yet")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("A medley is a fixed group of songs played in order. Add songs to build your medley.")
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
            ForEach(Array(medley.sortedEntries.enumerated()), id: \.element.persistentModelID) { index, entry in
                MedleySongRow(entry: entry, position: index + 1) {
                    editingEntry = entry
                }
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

    private var medleyMenu: some View {
        Menu {
            Button {
                showEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button {
                duplicateMedley()
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
        .disabled(medley.sortedEntries.isEmpty)
    }

    // MARK: - Actions

    private func moveEntries(from source: IndexSet, to destination: Int) {
        var sorted = medley.sortedEntries
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, entry) in sorted.enumerated() {
            entry.order = index
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            let entry = medley.sortedEntries[index]
            deleteEntry(entry)
        }
    }

    private func duplicateMedley() {
        let copy = medley.duplicate(in: context)
        selectedMedley = copy
    }

    private func deleteMedley() {
        selectedMedley = nil
        context.delete(medley)
    }

    private func deleteEntry(_ entry: MedleyEntry) {
        withAnimation {
            medley.entries.removeAll { $0.persistentModelID == entry.persistentModelID }
            context.delete(entry)
        }
    }
}
