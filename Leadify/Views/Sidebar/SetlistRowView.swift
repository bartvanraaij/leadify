import SwiftUI
import SwiftData

struct SetlistRowView: View {
    let setlist: Setlist
    @Binding var selectedSetlist: Setlist?
    @Environment(\.modelContext) private var context
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(setlist.name)
                    .font(.system(size: EditTheme.setlistNameSize, weight: .semibold))
                    .foregroundStyle(EditTheme.primaryText)
                if let formattedDate = setlist.formattedDate {
                    Text(formattedDate)
                        .font(.system(size: EditTheme.setlistDateSize))
                        .foregroundStyle(EditTheme.secondaryText)
                } else {
                    Text("no date")
                        .font(.system(size: EditTheme.setlistDateSize))
                        .foregroundStyle(EditTheme.secondaryText.opacity(0.5))
                        .italic()
                }
            }
            Spacer()
            Menu {
                Button { showEditSheet = true } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button { duplicateSetlist() } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                Divider()
                Button(role: .destructive) { showDeleteAlert = true } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Text("···")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(EditTheme.secondaryText)
                    .padding(.horizontal, 4)
            }
        }
        .contentShape(Rectangle())
        .sheet(isPresented: $showEditSheet) {
            SetlistEditSheet(setlist: setlist)
        }
        .alert("Delete \"\(setlist.name)\"?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { deleteSetlist() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the setlist and all its entries. Songs in your library are not affected.")
        }
    }

    private func duplicateSetlist() {
        let copy = setlist.duplicate(in: context)
        selectedSetlist = copy
    }

    private func deleteSetlist() {
        if selectedSetlist?.persistentModelID == setlist.persistentModelID {
            selectedSetlist = nil
        }
        context.delete(setlist)
    }
}
