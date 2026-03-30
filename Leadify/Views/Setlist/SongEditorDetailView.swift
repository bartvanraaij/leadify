import SwiftUI
import SwiftData
import MarkdownUI

struct SongEditorDetailView: View {
    @Bindable var song: Song
    @Binding var selectedSong: Song?
    @Environment(\.modelContext) private var context

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left: Editor
            VStack(alignment: .leading, spacing: 12) {
                TextField("Title", text: $song.title)
                    .font(.system(size: 24, weight: .bold))
                    .textFieldStyle(.plain)

                TextField("Reminder (optional)", text: Binding(
                    get: { song.reminder ?? "" },
                    set: { song.reminder = $0.isEmpty ? nil : $0 }
                ))
                .font(.system(size: EditTheme.reminderSize + 3))
                .foregroundStyle(EditTheme.reminderColor)
                .textFieldStyle(.plain)

                Divider()

                TextEditor(text: $song.content)
                    .font(.system(size: 15, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // MARK: - Right: Live preview
            ScrollView {
                SongContentPreview(content: song.content)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PerformanceTheme.background)
        }
        .navigationTitle(song.title.isEmpty ? "Untitled" : song.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(EditTheme.destructiveColor)
                }
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
}
