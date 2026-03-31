import SwiftUI

struct MedleySongRow: View {
    let entry: MedleyEntry
    let position: Int
    let onEdit: () -> Void

    var body: some View {
        Text(entry.song.title)
            .font(.body)
            .fontWeight(.regular)
            .foregroundStyle(.primary)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onEdit)
    }
}
