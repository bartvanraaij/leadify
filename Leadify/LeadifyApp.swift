import SwiftUI
import SwiftData

@main
struct LeadifyApp: App {
    let container: ModelContainer
    @State private var songImporter = SongImporter()

    init() {
        do {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--uitesting") {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                container = try ModelContainer(
                    for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self, Medley.self, MedleyEntry.self,
                    configurations: config
                )
            } else {
                let config = ModelConfiguration(cloudKitDatabase: .automatic)
                container = try ModelContainer(
                    for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self, Medley.self, MedleyEntry.self,
                    configurations: config
                )
            }
            #else
            let config = ModelConfiguration(cloudKitDatabase: .automatic)
            container = try ModelContainer(
                for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self, Medley.self, MedleyEntry.self,
                configurations: config
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
                #if DEBUG
                .onAppear {
                    if ProcessInfo.processInfo.arguments.contains("--uitesting") {
                        UITestSeeder.seed(in: container.mainContext)

                    }
                }
                #endif
        }
        .modelContainer(container)
    }
}
