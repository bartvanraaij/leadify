import SwiftUI

struct MedleySetlistGroup: View {
    let entry: SetlistEntry
    let onEditSong: (Song) -> Void

    private var medley: Medley { entry.medley! }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Medley header
            Text(medley.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.bottom, 6)

            // Songs within the medley
            ForEach(medley.sortedEntries) { medleyEntry in
                Text(medleyEntry.song.title)
                    .font(.body)
                    .fontWeight(.regular)
                    .foregroundStyle(.primary)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onEditSong(medleyEntry.song)
                    }
            }
        }
        .padding(.vertical, 4)
    }
}
