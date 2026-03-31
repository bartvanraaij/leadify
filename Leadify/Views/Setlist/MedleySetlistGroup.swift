import SwiftUI

struct MedleySetlistGroup: View {
    let entry: SetlistEntry
    let onEditSong: (Song) -> Void

    private var medley: Medley { entry.medley! }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Medley header
            Text(medley.name)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(EditTheme.medleyHeaderColor)
                .padding(.vertical, 4)

            // Songs within the medley
            ForEach(medley.sortedEntries) { medleyEntry in
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(EditTheme.medleyHeaderColor.opacity(0.3))
                        .frame(width: 3)

                    Text(medleyEntry.song.title)
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    onEditSong(medleyEntry.song)
                }
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(EditTheme.medleyGroupBackground)
    }
}
