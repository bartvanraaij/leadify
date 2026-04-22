import SwiftUI
import SwiftData
import LeadifyCore

struct SetlistSidebarRow: View {
    let setlist: Setlist
    @Binding var selectedSetlist: Setlist?
    @Environment(\.modelContext) private var context
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false

    private var isSelected: Bool {
        selectedSetlist?.persistentModelID == setlist.persistentModelID
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(setlist.name)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? Color.white : Color.primary)

            if let formattedDate = setlist.formattedDate {
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.secondary)
            } else {
                Text("No date")
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.secondary.opacity(0.6))
                    .italic()
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
            
            Button {
                duplicateSetlist()
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            .tint(.blue)
            
            Button {
                showEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.orange)
        }
        .contextMenu {
            Button {
                showEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button {
                duplicateSetlist()
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Divider()
            
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
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
