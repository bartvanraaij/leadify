import SwiftUI
import SwiftData
import LeadifyCore

@main
struct LeadifyApp: App {
    let container: ModelContainer
    @State private var songImporter = SongImporter()

    init() {
        do {
            #if DEBUG
            let isSeededRun = ProcessInfo.processInfo.arguments.contains("--seeded")
            let config = ModelConfiguration(isStoredInMemoryOnly: isSeededRun)
            
            container = try ModelContainer(
                for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self, Medley.self, MedleyEntry.self,
                configurations: config
            )
            
            if isSeededRun {
                print("[Seeded Run] Using in-memory store and seeding test data.")
                UITestSeeder.seed(in: container.mainContext)
            }
            #else
            container = try ModelContainer(
                for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self, Medley.self, MedleyEntry.self
            )
            #endif
            
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
