import SwiftUI
import SwiftData
import LeadifyCore

enum SetlistSortOrder {
    case name
    case performanceDate
}

struct SetlistSidebarView: View {
    let setlists: [Setlist]
    @Binding var selectedSetlist: Setlist?
    @State private var showNewSetlistSheet = false
    @State private var sortOrder: SetlistSortOrder = .performanceDate

    var sortedSetlists: [Setlist] {
        switch sortOrder {
        case .name:
            return setlists.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .performanceDate:
            return setlists.sorted { a, b in
                switch (a.date, b.date) {
                case (let d1?, let d2?): return d1 > d2
                case (nil, _): return false
                case (_, nil): return true
                }
            }
        }
    }

    var body: some View {
        List(selection: $selectedSetlist) {
            ForEach(sortedSetlists) { setlist in
                NavigationLink(value: setlist) {
                    SetlistSidebarRow(setlist: setlist, selectedSetlist: $selectedSetlist)
                }
                .listRowBackground(
                    selectedSetlist?.persistentModelID == setlist.persistentModelID
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
                    Text("Setlists")
                        .font(.headline)
                    Text("\(setlists.count) setlist\(setlists.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewSetlistSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewSetlistSheet) {
            SetlistEditSheet(setlist: nil) { newSetlist in
                selectedSetlist = newSetlist
            }
        }
    }

}
