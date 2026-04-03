import SwiftUI
import SwiftData

struct MedleySidebarRow: View {
    let medley: Medley
    @Binding var selectedMedley: Medley?
    @Environment(\.modelContext) private var context
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false

    private var isSelected: Bool {
        selectedMedley?.persistentModelID == medley.persistentModelID
    }

    private var songCount: Int {
        medley.sortedEntries.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(medley.name)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? Color.white : Color.primary)

            Text("\(songCount) song\(songCount == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.secondary)
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
                duplicateMedley()
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
                duplicateMedley()
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
            MedleyEditSheet(medley: medley)
        }
        .alert("Delete \"\(medley.name)\"?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { deleteMedley() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the medley. Songs in your library are not affected.")
        }
    }

    private func duplicateMedley() {
        let copy = medley.duplicate(in: context)
        selectedMedley = copy
    }

    private func deleteMedley() {
        if selectedMedley?.persistentModelID == medley.persistentModelID {
            selectedMedley = nil
        }
        context.delete(medley)
    }
}
