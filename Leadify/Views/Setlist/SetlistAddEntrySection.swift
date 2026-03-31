import SwiftUI

/// A Section containing "Add Song" and "Add Tacet" rows.
/// Drop this directly inside a `List` – it renders as its own section.
struct AddEntrySection: View {
    let onAddSong: () -> Void
    let onAddTacet: () -> Void

    var body: some View {
        Section {
            Button(action: onAddSong) {
                Label("Add Song", systemImage: "music.note")
                    .font(.system(size: EditTheme.songTitleSize, weight: .medium))
            }
            
            Button(action: onAddTacet) {
                Label("Add Tacet", systemImage: "pause.circle")
                    .font(.system(size: EditTheme.songTitleSize, weight: .medium))
            }
        } header: {
            Text("Add Items")
                .textCase(.uppercase)
        }
    }
}
