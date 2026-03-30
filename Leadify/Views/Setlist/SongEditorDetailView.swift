import SwiftUI
import SwiftData
import MarkdownUI

struct SongEditorDetailView: View {
    let song: Song
    @Binding var selectedSong: Song?
    @Environment(\.modelContext) private var context

    @State private var title: String
    @State private var reminder: String
    @State private var content: String
    @State private var showDeleteConfirmation = false

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

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            HStack(spacing: 16) {
                // MARK: - Left card: Editor
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Title", text: $title)
                        .font(.system(size: 24, weight: .bold))
                        .textFieldStyle(.plain)

                    TextField("Reminder (optional)", text: $reminder)
                        .font(.system(size: 15))
                        .foregroundStyle(EditTheme.reminderColor)
                        .textFieldStyle(.plain)

                    Divider()

                    TextEditor(text: $content)
                        .font(.system(size: 15, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)

                // MARK: - Right card: Preview
                ScrollView {
                    SongEditorPreview(title: title, reminder: reminder, content: content)
                        .padding(24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)
            }
            .padding(20)
        }
        .navigationTitle("Edit Song")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(EditTheme.destructiveColor)
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { cancel() }
                    .disabled(!hasChanges)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!hasChanges)
                    .fontWeight(.semibold)
            }
        }
        .alert("Delete Song", isPresented: $showDeleteConfirmation) {
            Button("Delete \"\(song.title)\"", role: .destructive) {
                selectedSong = nil
                context.delete(song)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove \"\(song.title)\" from all setlists. This cannot be undone.")
        }
    }

    private func save() {
        song.title = title
        song.reminder = reminder.isEmpty ? nil : reminder
        song.content = content
    }

    private func cancel() {
        title = song.title
        reminder = song.reminder ?? ""
        content = song.content
    }
}

// MARK: - Preview panel (mirrors SongBlock layout, driven by local state)

private struct SongEditorPreview: View {
    let title: String
    let reminder: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Text(title.isEmpty ? "Untitled" : title)
                    .font(.system(size: PerformanceTheme.songTitleSize, weight: .bold))
                    .foregroundStyle(PerformanceTheme.songTitleColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !reminder.isEmpty {
                    Text(reminder)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(PerformanceTheme.reminderColor))
                        .shadow(
                            color: PerformanceTheme.reminderColor.opacity(0.3),
                            radius: 4, x: 0, y: 2
                        )
                }
            }
            .padding(.bottom, 28)

            Rectangle()
                .fill(PerformanceTheme.dividerColor)
                .frame(height: 1)
                .padding(.bottom, 28)

            SongContentPreview(content: content)
        }
    }
}
