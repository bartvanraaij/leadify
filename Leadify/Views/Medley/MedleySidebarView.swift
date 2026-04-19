import SwiftUI
import SwiftData

struct MedleySidebarView: View {
    @Query private var allMedleys: [Medley]
    @Binding var selectedMedley: Medley?
    @State private var showNewMedleySheet = false

    private var sortedMedleys: [Medley] {
        allMedleys.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var body: some View {
        List(selection: $selectedMedley) {
            ForEach(sortedMedleys) { medley in
                NavigationLink(value: medley) {
                    MedleySidebarRow(medley: medley, selectedMedley: $selectedMedley)
                }
                .listRowBackground(
                    selectedMedley?.persistentModelID == medley.persistentModelID
                        ? RoundedRectangle(cornerRadius: 22, style: .continuous).fill(EditTheme.accentColor)
                        : nil
                )
            }
        }
        .listStyle(.sidebar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text("Medleys")
                        .font(.headline)
                    Text("\(allMedleys.count) medley\(allMedleys.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewMedleySheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewMedleySheet) {
            MedleyEditSheet(medley: nil) { newMedley in
                selectedMedley = newMedley
            }
        }
    }
}
