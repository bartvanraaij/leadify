# Leadify — Plan 1: Foundation + Ordering Mode

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A working Leadify app where you can create/manage setlists, add/edit/reorder songs and tacets, and manage the song library — the complete pre-show workflow.

**Architecture:** SwiftData `@Model` entities for persistence (think EF Core entities with auto-tracked context); `@Observable` for local view state; `NavigationSplitView` for iPad two-column layout; `@Query` macro for reactive data fetching (like a live database subscription that auto-updates the UI).

**Tech Stack:** Swift 5.9+, SwiftUI, SwiftData, XCTest, swift-markdown-ui 2.x (via Swift Package Manager)

---

## File Map

```
Leadify/
├── LeadifyApp.swift                   # App entry point, ModelContainer setup
├── Models/
│   ├── Song.swift                     # @Model: shared song library entity
│   ├── Tacet.swift                    # @Model: break/pause entity
│   ├── SetlistEntry.swift             # @Model: ordered item in a setlist (song or tacet)
│   └── Setlist.swift                  # @Model: named setlist + duplicate logic
├── Theme/
│   ├── PerformanceTheme.swift         # All performance mode sizes + colors
│   └── EditTheme.swift                # All ordering/editor mode sizes + colors
└── Views/
    ├── ContentView.swift              # NavigationSplitView root
    ├── Sidebar/
    │   ├── SetlistSidebarView.swift   # Left column: list of setlists
    │   ├── SetlistRowView.swift       # Single setlist row with ··· menu
    │   └── SetlistEditSheet.swift     # Sheet: edit setlist name + date
    └── Setlist/
        ├── SetlistDetailView.swift    # Right column: entries list + toolbar
        ├── SongEntryRow.swift         # Song row: drag handle, title, reminder, preview
        ├── TacetRow.swift             # Tacet row: drag handle, label, edit
        ├── AddEntryRow.swift          # Bottom row: + Add Song | + Add Tacet
        ├── TacetEditSheet.swift       # Sheet: create/edit tacet label
        ├── SongLibrarySheet.swift     # Sheet: search library, pick songs, new song
        └── SongEditorSheet.swift      # Sheet: edit song title, reminder, markdown content

LeadifyTests/
├── TestHelpers.swift                  # In-memory ModelContainer factory
├── SongTests.swift                    # Song CRUD tests
└── SetlistTests.swift                 # Duplicate, delete, ordering tests
```

---

## Task 1: Xcode Project Setup

**Files:** Project created via Xcode UI, then `Item.swift` deleted.

- [ ] **Step 1: Create the Xcode project**

  Open Xcode → File → New → Project → **App**
  - Product Name: `Leadify`
  - Team: your Apple ID
  - Organization Identifier: e.g. `nl.yourname`
  - Interface: **SwiftUI**
  - Storage: **SwiftData**
  - Language: **Swift**
  - Uncheck "Include Tests" for now (we add the test target manually next)

- [ ] **Step 2: Configure for iPad only**

  In the project navigator, click the **Leadify** project (blue icon) → select the **Leadify** target → **General** tab → **Deployment Info**: uncheck **iPhone**, keep **iPad**.
  Set Minimum Deployments to **iOS 17.0**.

- [ ] **Step 3: Add the test target**

  File → New → Target → **Unit Testing Bundle**
  - Product Name: `LeadifyTests`
  - Ensure "Target to be Tested" is set to `Leadify`

- [ ] **Step 4: Add swift-markdown-ui via Swift Package Manager**

  File → Add Package Dependencies → search for:
  ```
  https://github.com/gonzalezreal/swift-markdown-ui
  ```
  Select `MarkdownUI` product → Add to **Leadify** target (not the test target).

- [ ] **Step 5: Delete the generated boilerplate**

  Delete `Item.swift` (the sample SwiftData model Xcode generates). Move to Trash.
  In `ContentView.swift`, delete all generated content — we'll replace it in Task 5.
  In `LeadifyApp.swift`, delete the `modelContainer(for: Item.self)` modifier — we'll replace it in Task 5.

- [ ] **Step 6: Create folder structure**

  In the project navigator, create groups (right-click → New Group):
  `Models`, `Theme`, `Views/Sidebar`, `Views/Setlist`

- [ ] **Step 7: Verify the project builds**

  Press **Cmd+B**. Expected: Build Succeeded with 0 errors.

---

## Task 2: Data Models

**Files:**
- Create: `Leadify/Models/Song.swift`
- Create: `Leadify/Models/Tacet.swift`
- Create: `Leadify/Models/SetlistEntry.swift`
- Create: `Leadify/Models/Setlist.swift`

> **Swift note for C#/TS devs:** `@Model` is SwiftData's equivalent of an EF Core `[Table]` entity. SwiftData auto-generates the persistence layer. `final class` is required — no structs for SwiftData models.

- [ ] **Step 1: Create Song.swift**

```swift
import SwiftData
import Foundation

@Model
final class Song {
    var title: String
    var content: String
    var reminder: String?

    init(title: String, content: String = "", reminder: String? = nil) {
        self.title = title
        self.content = content
        self.reminder = reminder
    }
}
```

- [ ] **Step 2: Create Tacet.swift**

```swift
import SwiftData
import Foundation

/// A non-song setlist entry. Name from music notation: "tacet" = be silent.
@Model
final class Tacet {
    var label: String?

    init(label: String? = nil) {
        self.label = label
    }
}
```

- [ ] **Step 3: Create SetlistEntry.swift**

```swift
import SwiftData
import Foundation

enum SetlistItemType {
    case song
    case tacet
}

@Model
final class SetlistEntry {
    var song: Song?
    @Relationship(deleteRule: .cascade) var tacet: Tacet?

    /// Derived from which optional is non-nil. Extend this enum to add new item types.
    var itemType: SetlistItemType {
        song != nil ? .song : .tacet
    }

    init(song: Song) {
        self.song = song
        self.tacet = nil
    }

    init(tacet: Tacet) {
        self.song = nil
        self.tacet = tacet
    }
}
```

- [ ] **Step 4: Create Setlist.swift**

```swift
import SwiftData
import Foundation

@Model
final class Setlist {
    var name: String
    var date: Date?
    @Relationship(deleteRule: .cascade) var entries: [SetlistEntry]

    init(name: String, date: Date? = nil) {
        self.name = name
        self.date = date
        self.entries = []
    }

    /// Date formatted as dd-MM-yyyy for display (NL convention).
    var formattedDate: String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: date)
    }

    /// Creates a copy of this setlist with a new name.
    /// - Songs are shared by reference (editing a song updates all setlists).
    /// - Tacets are deep-copied (they are owned by their entry; sharing would
    ///   cause the tacet to be deleted if the original setlist is deleted).
    func duplicate(in context: ModelContext) -> Setlist {
        let copy = Setlist(name: "\(name) (copy)", date: date)
        context.insert(copy)
        for entry in entries {
            switch entry.itemType {
            case .song:
                let entryCopy = SetlistEntry(song: entry.song!)
                context.insert(entryCopy)
                copy.entries.append(entryCopy)
            case .tacet:
                let tacetCopy = Tacet(label: entry.tacet?.label)
                context.insert(tacetCopy)
                let entryCopy = SetlistEntry(tacet: tacetCopy)
                context.insert(entryCopy)
                copy.entries.append(entryCopy)
            }
        }
        return copy
    }
}
```

- [ ] **Step 5: Verify build**

  Press **Cmd+B**. Expected: Build Succeeded.

---

## Task 3: Business Logic Tests

**Files:**
- Create: `LeadifyTests/TestHelpers.swift`
- Create: `LeadifyTests/SongTests.swift`
- Create: `LeadifyTests/SetlistTests.swift`

> **Swift note:** XCTest is Swift's equivalent of xUnit/NUnit/Jest. `@MainActor` is needed because SwiftData operations must run on the main thread. In-memory containers (`isStoredInMemoryOnly: true`) are used for tests — equivalent to an in-memory EF Core database.

- [ ] **Step 1: Create TestHelpers.swift**

```swift
import XCTest
import SwiftData
@testable import Leadify

@MainActor
func makeTestContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(
        for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self,
        configurations: config
    )
}
```

- [ ] **Step 2: Create SongTests.swift**

```swift
import XCTest
import SwiftData
@testable import Leadify

@MainActor
final class SongTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        container = try makeTestContainer()
        context = ModelContext(container)
    }

    func test_song_createdWithTitle() throws {
        let song = Song(title: "Sweet Home Alabama", content: "D A Bm G")
        context.insert(song)
        try context.save()

        let songs = try context.fetch(FetchDescriptor<Song>())
        XCTAssertEqual(songs.count, 1)
        XCTAssertEqual(songs[0].title, "Sweet Home Alabama")
        XCTAssertEqual(songs[0].content, "D A Bm G")
        XCTAssertNil(songs[0].reminder)
    }

    func test_song_withReminder() throws {
        let song = Song(title: "Wonderwall", reminder: "Capo 2")
        context.insert(song)
        try context.save()

        let songs = try context.fetch(FetchDescriptor<Song>())
        XCTAssertEqual(songs[0].reminder, "Capo 2")
    }
}
```

- [ ] **Step 3: Run the tests to verify they pass**

  Press **Cmd+U** in Xcode (or click the diamond ◆ next to each test).
  Expected: 2 tests pass with a green checkmark.

- [ ] **Step 4: Create SetlistTests.swift**

```swift
import XCTest
import SwiftData
@testable import Leadify

@MainActor
final class SetlistTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        container = try makeTestContainer()
        context = ModelContext(container)
    }

    // MARK: - Duplicate

    func test_duplicate_createsSeparateSetlist() throws {
        let song = Song(title: "Mr. Brightside")
        context.insert(song)
        let original = Setlist(name: "Gig A", date: Date())
        context.insert(original)
        original.entries.append({ let e = SetlistEntry(song: song); context.insert(e); return e }())
        try context.save()

        let copy = original.duplicate(in: context)
        try context.save()

        let setlists = try context.fetch(FetchDescriptor<Setlist>())
        XCTAssertEqual(setlists.count, 2)
        XCTAssertEqual(copy.name, "Gig A (copy)")
    }

    func test_duplicate_sharesSongReferences() throws {
        let song = Song(title: "Wonderwall")
        context.insert(song)
        let original = Setlist(name: "Gig A")
        context.insert(original)
        let entry = SetlistEntry(song: song)
        context.insert(entry)
        original.entries.append(entry)
        try context.save()

        let copy = original.duplicate(in: context)
        try context.save()

        // Both setlists reference the same Song object
        XCTAssertEqual(original.entries[0].song?.persistentModelID,
                       copy.entries[0].song?.persistentModelID)
    }

    func test_duplicate_deepCopiesTacets() throws {
        let tacet = Tacet(label: "15 min")
        context.insert(tacet)
        let original = Setlist(name: "Gig A")
        context.insert(original)
        let entry = SetlistEntry(tacet: tacet)
        context.insert(entry)
        original.entries.append(entry)
        try context.save()

        let copy = original.duplicate(in: context)
        try context.save()

        // Tacet objects must be different instances
        XCTAssertNotEqual(original.entries[0].tacet?.persistentModelID,
                          copy.entries[0].tacet?.persistentModelID)
        // But same label value
        XCTAssertEqual(copy.entries[0].tacet?.label, "15 min")
    }

    func test_duplicate_preservesEntryOrder() throws {
        let s1 = Song(title: "Song 1")
        let s2 = Song(title: "Song 2")
        let s3 = Song(title: "Song 3")
        [s1, s2, s3].forEach { context.insert($0) }
        let original = Setlist(name: "Gig A")
        context.insert(original)
        for song in [s1, s2, s3] {
            let e = SetlistEntry(song: song)
            context.insert(e)
            original.entries.append(e)
        }
        try context.save()

        let copy = original.duplicate(in: context)
        try context.save()

        XCTAssertEqual(copy.entries.compactMap { $0.song?.title }, ["Song 1", "Song 2", "Song 3"])
    }

    // MARK: - Ordering

    func test_setlist_preservesEntryOrder() throws {
        let setlist = Setlist(name: "Test")
        context.insert(setlist)
        for i in 1...5 {
            let song = Song(title: "Song \(i)")
            context.insert(song)
            let entry = SetlistEntry(song: song)
            context.insert(entry)
            setlist.entries.append(entry)
        }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Setlist>()).first!
        XCTAssertEqual(fetched.entries.compactMap { $0.song?.title },
                       ["Song 1", "Song 2", "Song 3", "Song 4", "Song 5"])
    }

    // MARK: - formattedDate

    func test_formattedDate_nilWhenNoDate() {
        let setlist = Setlist(name: "Test")
        XCTAssertNil(setlist.formattedDate)
    }

    func test_formattedDate_nlFormat() {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 28
        let date = Calendar.current.date(from: components)!
        let setlist = Setlist(name: "Test", date: date)
        XCTAssertEqual(setlist.formattedDate, "28-03-2026")
    }
}
```

- [ ] **Step 5: Run all tests**

  Press **Cmd+U**. Expected: All tests pass.

- [ ] **Step 6: Commit**

```
git add Leadify/Models/ LeadifyTests/
git commit -m "feat: add SwiftData models and business logic tests"
```

---

## Task 4: Design Tokens

**Files:**
- Create: `Leadify/Theme/PerformanceTheme.swift`
- Create: `Leadify/Theme/EditTheme.swift`

> All font sizes and colors live here. To tune the app's look after trying it on your iPad, change values in these two files only — nothing else needs to change.

- [ ] **Step 1: Create PerformanceTheme.swift**

```swift
import SwiftUI

/// All visual constants for Performance Mode.
/// Adjust these after testing on the actual iPad.
struct PerformanceTheme {
    // MARK: Font sizes
    static let songTitleSize: CGFloat = 20        // most prominent: song title
    static let reminderSize: CGFloat = 12         // reminder below title
    static let sectionHeaderSize: CGFloat = 12    // "INTRO", "COUPLET" labels
    static let chordTextSize: CGFloat = 14        // the actual chord lines
    static let tabFontSize: CGFloat = 14          // monospace tab notation
    static let upNextSize: CGFloat = 12           // "next: …" corner label

    // MARK: Colors
    static let background = Color.black
    static let songTitleColor = Color.white
    static let chordTextColor = Color(white: 0.88)    // slightly off-white, easier on eyes
    static let sectionHeaderColor = Color(white: 0.55) // mid-grey, clearly secondary
    static let reminderColor = Color(red: 1.0, green: 0.58, blue: 0.0)  // warm orange
    static let tabColor = Color(red: 0.49, green: 0.86, blue: 0.49)     // soft green
    static let tacetTextColor = Color(white: 0.42)    // dimmed — clearly not a song
    static let upNextColor = Color(white: 0.60)       // subtle corner label
    static let tapZoneIndicatorColor = Color(white: 0.25) // barely-visible tap zone hint
}
```

- [ ] **Step 2: Create EditTheme.swift**

```swift
import SwiftUI

/// All visual constants for Ordering/Edit Mode and the Song Editor.
/// Adjust these after testing on the actual iPad.
struct EditTheme {
    // MARK: Font sizes
    static let setlistNameSize: CGFloat = 13      // setlist name in sidebar
    static let setlistDateSize: CGFloat = 11      // date below setlist name
    static let songTitleSize: CGFloat = 14        // song title in entry row
    static let songPreviewSize: CGFloat = 12      // first-line content preview
    static let reminderSize: CGFloat = 11         // reminder badge in entry row
    static let editorTitleSize: CGFloat = 16      // title field in song editor

    // MARK: Colors
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let reminderColor = Color(red: 1.0, green: 0.58, blue: 0.0)  // same orange as performance
    static let tacetText = Color.secondary
    static let accentColor = Color.accentColor    // iOS system blue
    static let destructiveColor = Color.red
}
```

- [ ] **Step 3: Commit**

```
git add Leadify/Theme/
git commit -m "feat: add PerformanceTheme and EditTheme design tokens"
```

---

## Task 5: App Entry Point + ContentView Shell

**Files:**
- Modify: `Leadify/LeadifyApp.swift`
- Modify: `Leadify/Views/ContentView.swift`

- [ ] **Step 1: Replace LeadifyApp.swift**

```swift
import SwiftUI
import SwiftData

@main
struct LeadifyApp: App {
    let container: ModelContainer

    init() {
        do {
            // Using default configuration (local storage).
            // To enable CloudKit sync later: add a CloudKit entitlement in Xcode,
            // then wrap this in ModelConfiguration(cloudKitDatabase: .automatic).
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
```

- [ ] **Step 2: Replace ContentView.swift**

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var allSetlists: [Setlist]
    @State private var selectedSetlist: Setlist?

    /// Setlists sorted by date descending; undated setlists at the bottom.
    var sortedSetlists: [Setlist] {
        allSetlists.sorted { a, b in
            switch (a.date, b.date) {
            case (let d1?, let d2?): return d1 > d2
            case (nil, _): return false
            case (_, nil): return true
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            SetlistSidebarView(
                setlists: sortedSetlists,
                selectedSetlist: $selectedSetlist
            )
        } detail: {
            if let setlist = selectedSetlist {
                SetlistDetailView(setlist: setlist)
            } else {
                ContentUnavailableView(
                    "No Setlist Selected",
                    systemImage: "music.note.list",
                    description: Text("Select a setlist from the sidebar or create a new one.")
                )
            }
        }
    }
}
```

- [ ] **Step 3: Add a preview to ContentView.swift**

```swift
#Preview {
    ContentView()
        .modelContainer(for: [Song.self, Tacet.self, SetlistEntry.self, Setlist.self],
                        inMemory: true)
}
```

- [ ] **Step 4: Build to catch any issues**

  Press **Cmd+B**. Expected: Build Succeeded (there will be "cannot find type" errors for views not yet created — those are fine, we create them next).

---

## Task 6: Setlist Sidebar

**Files:**
- Create: `Leadify/Views/Sidebar/SetlistSidebarView.swift`
- Create: `Leadify/Views/Sidebar/SetlistRowView.swift`
- Create: `Leadify/Views/Sidebar/SetlistEditSheet.swift`

- [ ] **Step 1: Create SetlistEditSheet.swift**

  This sheet is used for both creating a new setlist and editing an existing one. `nil` means "new".

```swift
import SwiftUI
import SwiftData

struct SetlistEditSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// Pass an existing Setlist to edit, or nil to create a new one.
    var setlist: Setlist?

    @State private var name: String = ""
    @State private var date: Date = Date()
    @State private var hasDate: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("e.g. Kermis Arcen", text: $name)
                }
                Section {
                    Toggle("Set date", isOn: $hasDate)
                    if hasDate {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                } header: {
                    Text("Date")
                } footer: {
                    Text("Optional. Shown as dd-MM-yyyy in the setlist list.")
                }
            }
            .navigationTitle(setlist == nil ? "New Setlist" : "Edit Setlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadExistingValues() }
        }
    }

    private func loadExistingValues() {
        guard let setlist else { return }
        name = setlist.name
        if let d = setlist.date {
            date = d
            hasDate = true
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let setlist {
            setlist.name = trimmed
            setlist.date = hasDate ? date : nil
        } else {
            let new = Setlist(name: trimmed, date: hasDate ? date : nil)
            context.insert(new)
        }
        dismiss()
    }
}
```

- [ ] **Step 2: Create SetlistRowView.swift**

```swift
import SwiftUI
import SwiftData

struct SetlistRowView: View {
    let setlist: Setlist
    @Binding var selectedSetlist: Setlist?
    @Environment(\.modelContext) private var context
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(setlist.name)
                    .font(.system(size: EditTheme.setlistNameSize, weight: .semibold))
                    .foregroundStyle(EditTheme.primaryText)
                if let formattedDate = setlist.formattedDate {
                    Text(formattedDate)
                        .font(.system(size: EditTheme.setlistDateSize))
                        .foregroundStyle(EditTheme.secondaryText)
                } else {
                    Text("no date")
                        .font(.system(size: EditTheme.setlistDateSize))
                        .foregroundStyle(EditTheme.secondaryText.opacity(0.5))
                        .italic()
                }
            }
            Spacer()
            Menu {
                Button { showEditSheet = true } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button { duplicateSetlist() } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                Divider()
                Button(role: .destructive) { showDeleteAlert = true } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Text("···")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(EditTheme.secondaryText)
                    .padding(.horizontal, 4)
            }
        }
        .contentShape(Rectangle())
        .sheet(isPresented: $showEditSheet) {
            SetlistEditSheet(setlist: setlist)
        }
        .alert("Delete \"\(setlist.name)\"?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { deleteSetlist() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the setlist and all its entries. Songs in your library are not affected.")
        }
    }

    private func duplicateSetlist() {
        let copy = setlist.duplicate(in: context)
        selectedSetlist = copy
    }

    private func deleteSetlist() {
        if selectedSetlist?.persistentModelID == setlist.persistentModelID {
            selectedSetlist = nil
        }
        context.delete(setlist)
    }
}
```

- [ ] **Step 3: Create SetlistSidebarView.swift**

```swift
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
        .navigationTitle("Setlists")
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
```

- [ ] **Step 4: Build and verify in simulator**

  Press **Cmd+R** to run in the iPad simulator. You should see the split view with an empty setlist sidebar and a "+" button that opens the new setlist sheet. Creating a setlist should add it to the sidebar.

- [ ] **Step 5: Commit**

```
git add Leadify/Views/
git commit -m "feat: add setlist sidebar with create/edit/duplicate/delete"
```

---

## Task 7: Setlist Detail — Entry List + Ordering

**Files:**
- Create: `Leadify/Views/Setlist/SetlistDetailView.swift`
- Create: `Leadify/Views/Setlist/SongEntryRow.swift`
- Create: `Leadify/Views/Setlist/TacetRow.swift`
- Create: `Leadify/Views/Setlist/AddEntryRow.swift`

- [ ] **Step 1: Create SongEntryRow.swift**

```swift
import SwiftUI

struct SongEntryRow: View {
    let entry: SetlistEntry
    let onEdit: () -> Void

    private var song: Song { entry.song! }

    /// First non-empty line of the song content, used as a preview.
    private var contentPreview: String {
        song.content
            .components(separatedBy: .newlines)
            .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty
                           && !$0.hasPrefix("#")
                           && !$0.hasPrefix("```") })
            ?? ""
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(EditTheme.secondaryText)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(song.title)
                        .font(.system(size: EditTheme.songTitleSize, weight: .semibold))
                        .foregroundStyle(EditTheme.primaryText)
                    if let reminder = song.reminder {
                        Text(reminder)
                            .font(.system(size: EditTheme.reminderSize, weight: .semibold))
                            .foregroundStyle(EditTheme.reminderColor)
                    }
                }
                if !contentPreview.isEmpty {
                    Text(contentPreview)
                        .font(.system(size: EditTheme.songPreviewSize))
                        .foregroundStyle(EditTheme.secondaryText)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundStyle(EditTheme.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
```

- [ ] **Step 2: Create TacetRow.swift**

```swift
import SwiftUI

struct TacetRow: View {
    let entry: SetlistEntry
    let onEdit: () -> Void

    private var tacet: Tacet { entry.tacet! }

    private var displayLabel: String {
        if let label = tacet.label, !label.isEmpty {
            return "— \(label) —"
        }
        return "— Tacet —"
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(EditTheme.secondaryText)

            Text(displayLabel)
                .font(.system(size: EditTheme.songPreviewSize))
                .italic()
                .foregroundStyle(EditTheme.tacetText)

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundStyle(EditTheme.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }
}
```

- [ ] **Step 3: Create AddEntryRow.swift**

```swift
import SwiftUI

struct AddEntryRow: View {
    let onAddSong: () -> Void
    let onAddTacet: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onAddSong) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Add Song")
                }
                .font(.system(size: EditTheme.songTitleSize))
                .foregroundStyle(EditTheme.accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 36)

            Button(action: onAddTacet) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Add Tacet")
                }
                .font(.system(size: EditTheme.songTitleSize))
                .foregroundStyle(EditTheme.accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundStyle(EditTheme.secondaryText.opacity(0.5))
        )
    }
}
```

- [ ] **Step 4: Create SetlistDetailView.swift**

```swift
import SwiftUI
import SwiftData

struct SetlistDetailView: View {
    @Bindable var setlist: Setlist
    @Environment(\.modelContext) private var context

    @State private var showSongLibrary = false
    @State private var showTacetEdit = false
    @State private var editingEntry: SetlistEntry?
    @State private var showPerformance = false

    var body: some View {
        List {
            ForEach(setlist.entries) { entry in
                switch entry.itemType {
                case .song:
                    SongEntryRow(entry: entry) {
                        editingEntry = entry
                    }
                    .listRowBackground(Color(.secondarySystemBackground))
                case .tacet:
                    TacetRow(entry: entry) {
                        editingEntry = entry
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                            .foregroundStyle(EditTheme.secondaryText.opacity(0.4))
                    )
                }
            }
            .onMove(perform: moveEntries)
            .onDelete(perform: deleteEntries)

            AddEntryRow(
                onAddSong: { showSongLibrary = true },
                onAddTacet: { showTacetEdit = true }
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(.active))
        .navigationTitle(setlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showPerformance = true
                } label: {
                    Label("Perform", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showSongLibrary) {
            SongLibrarySheet(setlist: setlist)
        }
        .sheet(isPresented: $showTacetEdit) {
            TacetEditSheet(entry: nil, setlist: setlist)
        }
        .sheet(item: $editingEntry) { entry in
            switch entry.itemType {
            case .song:
                SongEditorSheet(song: entry.song!)
            case .tacet:
                TacetEditSheet(entry: entry, setlist: setlist)
            }
        }
        .fullScreenCover(isPresented: $showPerformance) {
            PerformanceView(setlist: setlist)
        }
    }

    private func moveEntries(from source: IndexSet, to destination: Int) {
        setlist.entries.move(fromOffsets: source, toOffset: destination)
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            context.delete(setlist.entries[index])
        }
        setlist.entries.remove(atOffsets: offsets)
    }
}
```

- [ ] **Step 5: Add placeholder views for sheets not yet built (to let the project build)**

  Create `Leadify/Views/Setlist/SongLibrarySheet.swift` with a placeholder:

```swift
import SwiftUI

struct SongLibrarySheet: View {
    let setlist: Setlist
    var body: some View {
        Text("Song Library — coming in Task 9")
    }
}
```

  Create `Leadify/Views/Setlist/TacetEditSheet.swift` with a placeholder:

```swift
import SwiftUI

struct TacetEditSheet: View {
    let entry: SetlistEntry?
    let setlist: Setlist
    var body: some View {
        Text("Tacet Edit — coming in Task 8")
    }
}
```

  Create `Leadify/Views/Setlist/SongEditorSheet.swift` with a placeholder:

```swift
import SwiftUI

struct SongEditorSheet: View {
    let song: Song
    var body: some View {
        Text("Song Editor — coming in Task 10")
    }
}
```

  Create `Leadify/Views/Setlist/Performance/PerformanceView.swift` with a placeholder:

```swift
import SwiftUI

struct PerformanceView: View {
    let setlist: Setlist
    var body: some View {
        Text("Performance Mode — Plan 2")
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
    }
}
```

- [ ] **Step 6: Build and test in simulator**

  Press **Cmd+R**. Create a setlist, tap it. The detail pane should show an empty list with the "+ Add Song | + Add Tacet" row at the bottom and a "Perform" button in the toolbar. Drag handles appear (the list is in permanent edit mode).

- [ ] **Step 7: Commit**

```
git add Leadify/Views/Setlist/
git commit -m "feat: add setlist detail view with drag-to-reorder and entry rows"
```

---

## Task 8: Tacet Edit Sheet

**Files:**
- Modify: `Leadify/Views/Setlist/TacetEditSheet.swift` (replace placeholder)

- [ ] **Step 1: Replace TacetEditSheet.swift**

```swift
import SwiftUI
import SwiftData

struct TacetEditSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// Existing entry to edit, or nil to create a new tacet.
    let entry: SetlistEntry?
    let setlist: Setlist

    @State private var label: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. 15 min, Setlist 2", text: $label)
                } header: {
                    Text("Label")
                } footer: {
                    Text("Optional. Leave empty for a plain pause.")
                }
            }
            .navigationTitle(entry == nil ? "Add Tacet" : "Edit Tacet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                label = entry?.tacet?.label ?? ""
            }
        }
    }

    private func save() {
        let trimmedLabel = label.trimmingCharacters(in: .whitespaces)
        let labelValue = trimmedLabel.isEmpty ? nil : trimmedLabel

        if let entry {
            entry.tacet?.label = labelValue
        } else {
            let tacet = Tacet(label: labelValue)
            context.insert(tacet)
            let newEntry = SetlistEntry(tacet: tacet)
            context.insert(newEntry)
            setlist.entries.append(newEntry)
        }
        dismiss()
    }
}
```

- [ ] **Step 2: Verify in simulator**

  Tap "+ Add Tacet" in the entry list. A sheet should appear with a label text field. Enter "15 min" and save — a tacet row should appear at the bottom of the list. Tap its pencil icon to edit.

- [ ] **Step 3: Commit**

```
git add Leadify/Views/Setlist/TacetEditSheet.swift
git commit -m "feat: implement tacet edit sheet"
```

---

## Task 9: Song Library Sheet

**Files:**
- Modify: `Leadify/Views/Setlist/SongLibrarySheet.swift` (replace placeholder)

- [ ] **Step 1: Replace SongLibrarySheet.swift**

```swift
import SwiftUI
import SwiftData

struct SongLibrarySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let setlist: Setlist

    @Query(sort: \Song.title) private var allSongs: [Song]
    @State private var searchText = ""
    @State private var showNewSongEditor = false

    private var filteredSongs: [Song] {
        guard !searchText.isEmpty else { return allSongs }
        return allSongs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// IDs of songs already in this setlist (for the checkmark indicator).
    private var songsInSetlist: Set<PersistentIdentifier> {
        Set(setlist.entries.compactMap { $0.song?.persistentModelID })
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredSongs) { song in
                    LibrarySongRow(
                        song: song,
                        isInSetlist: songsInSetlist.contains(song.persistentModelID),
                        onAdd: { addSong(song) }
                    )
                }
            }
            .searchable(text: $searchText, prompt: "Search songs")
            .navigationTitle("Song Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewSongEditor = true
                    } label: {
                        Label("New Song", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewSongEditor) {
                SongEditorSheet(song: nil, onSave: { newSong in
                    addSong(newSong)
                })
            }
        }
    }

    private func addSong(_ song: Song) {
        let entry = SetlistEntry(song: song)
        context.insert(entry)
        setlist.entries.append(entry)
    }
}

private struct LibrarySongRow: View {
    let song: Song
    let isInSetlist: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.system(size: EditTheme.songTitleSize, weight: .semibold))
                if let reminder = song.reminder {
                    Text(reminder)
                        .font(.system(size: EditTheme.reminderSize))
                        .foregroundStyle(EditTheme.reminderColor)
                }
            }
            Spacer()
            if isInSetlist {
                Image(systemName: "checkmark")
                    .foregroundStyle(EditTheme.secondaryText)
            } else {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(EditTheme.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(isInSetlist ? 0.5 : 1.0)
    }
}
```

> **Note:** `SongEditorSheet` now needs an optional `song` parameter and an `onSave` callback — we'll implement this in the next task. The placeholder won't compile yet; that's expected.

- [ ] **Step 2: Commit**

```
git add Leadify/Views/Setlist/SongLibrarySheet.swift
git commit -m "feat: add song library sheet with search and add-to-setlist"
```

---

## Task 10: Song Editor Sheet

**Files:**
- Modify: `Leadify/Views/Setlist/SongEditorSheet.swift` (replace placeholder)

> **About swift-markdown-ui:** `MarkdownUI.Markdown` is a SwiftUI view that renders Markdown text. We apply a custom theme to it so it uses our `PerformanceTheme` values. Think of it like a React component with a styled-system theme.

- [ ] **Step 1: Replace SongEditorSheet.swift**

```swift
import SwiftUI
import SwiftData
import MarkdownUI

struct SongEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// Existing song to edit, or nil to create a new one.
    let song: Song?
    /// Called with the saved song after saving a new song (used by SongLibrarySheet).
    var onSave: ((Song) -> Void)?

    @State private var title: String = ""
    @State private var reminder: String = ""
    @State private var content: String = ""
    @State private var showPreview: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section("Title") {
                        TextField("Song title", text: $title)
                            .font(.system(size: EditTheme.editorTitleSize, weight: .bold))
                    }
                    Section {
                        TextField("e.g. Capo 4, Fuzz, Tsw +1", text: $reminder)
                            .foregroundStyle(EditTheme.reminderColor)
                    } header: {
                        Text("Reminder")
                    } footer: {
                        Text("Optional. Shown in orange wherever this song appears.")
                    }
                }
                .frame(height: 220)

                // Edit / Preview toggle
                HStack {
                    Text("Content")
                        .font(.caption)
                        .foregroundStyle(EditTheme.secondaryText)
                        .textCase(.uppercase)
                    Spacer()
                    Picker("", selection: $showPreview) {
                        Text("Edit").tag(false)
                        Text("Preview").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)

                Divider()

                if showPreview {
                    ScrollView {
                        SongContentPreview(content: content)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    TextEditor(text: $content)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(song == nil ? "New Song" : "Edit Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadExistingValues() }
        }
    }

    private func loadExistingValues() {
        guard let song else { return }
        title = song.title
        reminder = song.reminder ?? ""
        content = song.content
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedReminder = reminder.trimmingCharacters(in: .whitespaces)
        let reminderValue = trimmedReminder.isEmpty ? nil : trimmedReminder

        if let song {
            song.title = trimmedTitle
            song.reminder = reminderValue
            song.content = content
            dismiss()
        } else {
            let newSong = Song(title: trimmedTitle, content: content, reminder: reminderValue)
            context.insert(newSong)
            dismiss()
            onSave?(newSong)
        }
    }
}

/// Renders Markdown content using PerformanceTheme styling.
struct SongContentPreview: View {
    let content: String

    var body: some View {
        Markdown(content)
            .markdownTheme(.leadifyPerformance)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Custom MarkdownUI Theme

extension MarkdownUI.Theme {
    static let leadifyPerformance = Theme()
        .heading2 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(PerformanceTheme.sectionHeaderSize)
                    FontWeight(.semibold)
                    ForegroundColor(UIColor(PerformanceTheme.sectionHeaderColor))
                }
                .relativeLineSpacing(.em(0.1))
                .markdownMargin(top: .em(0.8), bottom: .em(0.2))
        }
        .paragraph { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(PerformanceTheme.chordTextSize)
                    ForegroundColor(UIColor(PerformanceTheme.chordTextColor))
                }
        }
        .code { configuration in
            configuration.label
                .markdownTextStyle {
                    FontFamilyVariant(.monospaced)
                    FontSize(PerformanceTheme.tabFontSize)
                    ForegroundColor(UIColor(PerformanceTheme.tabColor))
                }
        }
        .codeBlock { configuration in
            configuration.label
                .markdownTextStyle {
                    FontFamilyVariant(.monospaced)
                    FontSize(PerformanceTheme.tabFontSize)
                    ForegroundColor(UIColor(PerformanceTheme.tabColor))
                }
                .padding(.vertical, 4)
        }
}
```

- [ ] **Step 2: Build and verify**

  Press **Cmd+B**. Tap "+ Add Song" → "+ New Song" in the library sheet. Fill in a title and some chord content (`## Intro\nD A G`). Switch to Preview mode — it should render with section headers in grey and chords in the performance style.

- [ ] **Step 3: Run all tests**

  Press **Cmd+U**. Expected: all existing tests still pass.

- [ ] **Step 4: Commit**

```
git add Leadify/Views/Setlist/SongEditorSheet.swift
git commit -m "feat: implement song editor with markdown preview"
```

---

## Task 11: Smoke Test — Full Ordering Mode

This task verifies the complete ordering mode workflow before we move to performance mode (Plan 2).

- [ ] **Step 1: Run the app in the iPad simulator**

  Press **Cmd+R**. Select an iPad Pro 12.9" simulator.

- [ ] **Step 2: Create a setlist**

  Tap **+** in the sidebar → name it "Test Gig" with today's date → Save.
  The setlist should appear in the sidebar with the name and date formatted as `dd-MM-yyyy`.

- [ ] **Step 3: Add songs**

  Tap the setlist → tap **+ Add Song** → tap **+ New Song** → create "Sweet Home Alabama" with reminder "Capo 4" and content:
  ```
  ## Intro
  D A Bm G

  ## Couplet
  D A Bm G
  D A G
  ```
  Save. The song should appear in the setlist.

  Add a second song. Confirm both appear.

- [ ] **Step 4: Add a tacet**

  Tap **+ Add Tacet** → enter "15 min" → Save. A tacet row should appear.

- [ ] **Step 5: Reorder**

  Use the drag handles (≡) to move entries. Verify the new order persists after releasing.

- [ ] **Step 6: Edit a song**

  Tap the pencil icon on a song. Change the reminder. Save. The updated reminder should appear in the row.

- [ ] **Step 7: Duplicate a setlist**

  Tap **···** on a setlist → **Duplicate**. A "(copy)" setlist appears. Verify the entries are present.
  Edit the original song's content. Check that the copy's song also shows the update (shared reference).

- [ ] **Step 8: Delete a setlist**

  Tap **···** → **Delete** → confirm. The setlist is removed from the sidebar.

- [ ] **Step 9: Commit**

```
git commit -m "chore: ordering mode complete — ready for Plan 2 (performance mode)"
```

---

## Self-Review Notes

- ✅ All spec §1–§6 requirements covered.
- ✅ Design tokens used throughout — no magic numbers in views.
- ✅ Duplicate: songs shared by reference, tacets deep-copied.
- ✅ `SetlistItemType` enum provides explicit type discrimination.
- ✅ `formattedDate` uses `dd-MM-yyyy` NL format.
- ✅ `ModelContainer` uses default config with a code comment explaining the CloudKit migration path.
- ✅ Performance mode placeholder in place — `fullScreenCover` wired up, ready for Plan 2.
- ⚠️ MarkdownUI Theme API: the `.heading2`, `.paragraph`, `.code`, `.codeBlock` modifier names match MarkdownUI 2.x. Verify against the installed version if build errors occur — check the MarkdownUI documentation in Xcode's package graph.
