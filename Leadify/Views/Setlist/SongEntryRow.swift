import SwiftUI

struct SongEntryRow: View {
    let entry: SetlistEntry
    let position: Int
    let onEdit: () -> Void
    
    @Environment(\.editMode) private var editMode

    private var song: Song { entry.song! }
    
    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    var body: some View {
        Text(song.title)
            .font(.body)
            .fontWeight(.regular)
            .foregroundStyle(.primary)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onEdit)
    }
}
