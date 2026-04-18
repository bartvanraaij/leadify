import SwiftUI
import SwiftData

// Currently unused — songs open directly in SongEditorDetailView.
// Kept for potential future use as a read-only detail view.
struct SongDisplayView: View {
    let song: Song
    @Binding var selectedSong: Song?
    @Binding var isEditing: Bool
    @Environment(\.modelContext) private var context

    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: 12) {
                        Text(song.title.isEmpty ? "Untitled" : song.title)
                            .font(.system(size: PerformanceTheme.songTitleSize, weight: .bold))
                            .foregroundStyle(PerformanceTheme.songTitleColor)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if let reminder = song.reminder, !reminder.isEmpty {
                            Text(reminder)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(EditTheme.accentColor))
                        }
                    }

                    SongContentPreview(content: song.content)
                }
                .padding(24)
            }
        }
        .navigationTitle(song.title.isEmpty ? "Untitled" : song.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Edit") { isEditing = true }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .tint(EditTheme.destructiveColor)
            }
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
}
