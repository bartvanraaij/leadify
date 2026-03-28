import SwiftUI

struct AddEntryRow: View {
    let onAddSong: () -> Void
    let onAddTacet: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onAddSong) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Add Song")
                }
                .font(.system(size: EditTheme.songTitleSize))
                .foregroundStyle(EditTheme.accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 36)

            Button(action: onAddTacet) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Add Tacet")
                }
                .font(.system(size: EditTheme.songTitleSize))
                .foregroundStyle(EditTheme.accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundStyle(EditTheme.secondaryText.opacity(0.5))
        )
    }
}
