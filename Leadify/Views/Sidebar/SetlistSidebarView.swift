import SwiftUI
import SwiftData

struct SetlistSidebarView: View {
    let setlists: [Setlist]
    @Binding var selectedSetlist: Setlist?
    @State private var showNewSetlistSheet = false

    var body: some View {
        List(selection: $selectedSetlist) {
            ForEach(setlists) { setlist in
                SetlistRowView(setlist: setlist, selectedSetlist: $selectedSetlist)
                    .tag(setlist)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Setlists")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showNewSetlistSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewSetlistSheet) {
            SetlistEditSheet(setlist: nil)
        }
    }
}
