import SwiftUI
import SwiftData

struct SongEditorDetailView: View {
    let song: Song
    @Binding var selectedSong: Song?
    @Environment(\.modelContext) private var context

    @State private var title: String
    @State private var reminder: String
    @State private var content: String
    @State private var showDeleteConfirmation = false
    @State private var showPreview = false

    init(song: Song, selectedSong: Binding<Song?>) {
        self.song = song
        self._selectedSong = selectedSong
        self._title = State(initialValue: song.title)
        self._reminder = State(initialValue: song.reminder ?? "")
        self._content = State(initialValue: song.content)
    }

    var hasChanges: Bool {
        title != song.title || reminder != (song.reminder ?? "") || content != song.content
    }

    /// True when this song was just created by the + button and has never been saved.
    private var isNewSong: Bool {
        song.title.isEmpty && song.content.isEmpty && song.reminder == nil
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                VStack(spacing: 0) {
                    TextField("Title", text: $title)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                    Divider().padding(.leading, 16)

                    TextField("Reminder", text: $reminder)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Content")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    TextEditor(text: $content)
                        .font(.system(size: 15, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.top, 35)
            .padding(.bottom, 20)
        }
        .navigationTitle(isNewSong ? "New Song" : song.title)
        .onDisappear {
            if isNewSong {
                if !title.trimmingCharacters(in: .whitespaces).isEmpty || !content.trimmingCharacters(in: .whitespaces).isEmpty {
                    // Auto-save new songs that have content
                    save()
                } else {
                    // Clean up truly empty new songs
                    context.delete(song)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        duplicateSong()
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    revert()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(!hasChanges)

                Button {
                    showPreview = true
                } label: {
                    Image(systemName: "eye")
                }

                Button("Save") { save() }
                    .disabled(!hasChanges)
                    .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showPreview) {
            SongPreviewSheet(title: title, reminder: reminder.isEmpty ? nil : reminder, content: content)
        }
        .alert("Delete Song", isPresented: $showDeleteConfirmation) {
            Button("Delete \"\(song.title.isEmpty ? "New Song" : song.title)\"", role: .destructive) {
                selectedSong = nil
                context.delete(song)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove this song from all setlists. This cannot be undone.")
        }
    }

    private func save() {
        song.title = title
        song.reminder = reminder.isEmpty ? nil : reminder
        song.content = content
    }

    private func revert() {
        title = song.title
        reminder = song.reminder ?? ""
        content = song.content
    }

    private func duplicateSong() {
        if hasChanges { save() }
        let copy = song.duplicate(in: context)
        selectedSong = copy
    }
}

