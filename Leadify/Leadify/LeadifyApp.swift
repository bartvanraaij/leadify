import SwiftUI
import SwiftData

@main
struct LeadifyApp: App {
    let container: ModelContainer

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
            ContentView()
        }
        .modelContainer(container)
    }
}
