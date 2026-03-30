import SwiftUI
import SwiftData

@main
struct LeadifyApp: App {
    let container: ModelContainer
    @State private var songImporter = SongImporter()
    @State private var sidebarMode: SidebarMode = .setlists

    init() {
        do {
            // Using default local storage.
            // To enable CloudKit sync later: add a CloudKit entitlement in Xcode,
            // then use ModelConfiguration(cloudKitDatabase: .automatic).
            container = try ModelContainer(for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(sidebarMode: $sidebarMode)
                .environment(songImporter)
                .onOpenURL { url in
                    sidebarMode = .songs
                    songImporter.importFile(url: url, context: container.mainContext)
                }
        }
        .modelContainer(container)
    }
}
