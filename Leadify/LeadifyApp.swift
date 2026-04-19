import SwiftUI
import SwiftData

@main
struct LeadifyApp: App {
    let container: ModelContainer
    @State private var songImporter = SongImporter()

    init() {
        do {
            container = try ModelContainer(for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self, Medley.self, MedleyEntry.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(songImporter)
                .onOpenURL { url in
                    songImporter.importFile(url: url, context: container.mainContext)
                }
        }
        .modelContainer(container)
    }
}
