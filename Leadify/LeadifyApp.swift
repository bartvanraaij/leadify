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
                // Reset any persisted @AppStorage values so UI tests run deterministically.
                // If --uitest-nav-mode=<rawValue> is passed, use that mode; else the default.
                let navModeOverride = ProcessInfo.processInfo.arguments
                    .first { $0.hasPrefix("--uitest-nav-mode=") }
                    .map { $0.replacingOccurrences(of: "--uitest-nav-mode=", with: "") }
                    .flatMap { PerformanceNavigationMode(rawValue: $0) }
                UserDefaults.standard.set(
                    (navModeOverride ?? .defaultMode).rawValue,
                    forKey: PerformanceNavigationMode.storageKey
                )

                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                container = try ModelContainer(
                    for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self, Medley.self, MedleyEntry.self,
                    configurations: config
                )
            } else {
                container = try ModelContainer(for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self, Medley.self, MedleyEntry.self)
            }
            #else
            container = try ModelContainer(for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self, Medley.self, MedleyEntry.self)
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
