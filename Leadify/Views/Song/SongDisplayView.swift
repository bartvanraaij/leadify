import SwiftUI
import SwiftData
import LeadifyCore

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
                SongPerformanceContent(song: song)
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
