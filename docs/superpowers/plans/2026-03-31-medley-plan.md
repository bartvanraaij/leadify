# Medley Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add medleys (fixed groups of songs) as a first-class concept — manageable in the sidebar, addable to setlists, and rendered in performance mode with position indicators.

**Architecture:** Two new SwiftData models (`Medley`, `MedleyEntry`) following the same ordering pattern as `Setlist`/`SetlistEntry`. A new `.medley` case on `SetlistEntry` links a medley into a setlist. UI follows existing patterns: sidebar section, detail view, library sheet, and performance block.

**Tech Stack:** SwiftUI, SwiftData, MarkdownUI

---

### Task 0: Update outdated documentation

**Files:**
- Modify: `CLAUDE.md`
- Modify: `docs/superpowers/specs/2026-03-28-leadify-design.md`

- [ ] **Step 1: Fix CLAUDE.md — remove "Up next" references and fix SongSetlistRow description**

In `CLAUDE.md`, the "Known UI issues / next refinements" section mentions "Up next" which has been removed. The design spec section 7 describes `SongSetlistRow` as showing reminder + first line preview, but it only shows song title.

Update the relevant sections in CLAUDE.md:
- Remove any "Up next" references from "Known UI issues"
- Add note that `SongSetlistRow` displays song title only (no reminder, no preview)

- [ ] **Step 2: Fix design spec section 7 and 8**

In `docs/superpowers/specs/2026-03-28-leadify-design.md`:
- Section 7 (line ~193): Change song row description from "title (primary, larger) + reminder (reminder color, same size) + first line of content as preview (secondary, smaller) + edit pencil (right)" to just "title"
- Section 8 (line ~222): Remove the "Up next" label paragraph entirely

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md docs/superpowers/specs/2026-03-28-leadify-design.md
git commit -m "docs: fix outdated SongSetlistRow description and remove Up next references"
```

---

### Task 1: Medley and MedleyEntry models + tests

**Files:**
- Create: `Leadify/Models/Medley.swift`
- Create: `Leadify/Models/MedleyEntry.swift`
- Modify: `Leadify/LeadifyApp.swift` (add to ModelContainer)
- Modify: `LeadifyTests/TestHelpers.swift` (add to test container)
- Create: `LeadifyTests/MedleyTests.swift`

- [ ] **Step 1: Write failing tests for Medley model**

Create `LeadifyTests/MedleyTests.swift`:

```swift
import XCTest
import SwiftData
@testable import Leadify

@MainActor
final class MedleyTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        container = try makeTestContainer()
        context = ModelContext(container)
    }

    // MARK: - Creation

    func test_medley_createdWithName() throws {
        let medley = Medley(name: "Rock 1")
        context.insert(medley)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Medley>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].name, "Rock 1")
    }

    // MARK: - Ordering

    func test_medley_preservesEntryOrder() throws {
        let medley = Medley(name: "Rock 1")
        context.insert(medley)

        let songs = ["Girl", "Zombie", "Smells Like Teen Spirit"].map { Song(title: $0) }
        songs.forEach { context.insert($0) }

        for song in songs {
            let entry = MedleyEntry(song: song)
            context.insert(entry)
            medley.addEntry(entry)
        }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Medley>()).first!
        XCTAssertEqual(fetched.sortedEntries.map { $0.song.title },
                       ["Girl", "Zombie", "Smells Like Teen Spirit"])
    }

    // MARK: - Duplicate

    func test_duplicate_createsSeparateMedley() throws {
        let medley = Medley(name: "Rock 1")
        context.insert(medley)
        let song = Song(title: "Girl")
        context.insert(song)
        let entry = MedleyEntry(song: song)
        context.insert(entry)
        medley.addEntry(entry)
        try context.save()

        let copy = medley.duplicate(in: context)
        try context.save()

        let medleys = try context.fetch(FetchDescriptor<Medley>())
        XCTAssertEqual(medleys.count, 2)
        XCTAssertEqual(copy.name, "Rock 1 (copy)")
    }

    func test_duplicate_sharesSongReferences() throws {
        let medley = Medley(name: "Rock 1")
        context.insert(medley)
        let song = Song(title: "Girl")
        context.insert(song)
        let entry = MedleyEntry(song: song)
        context.insert(entry)
        medley.addEntry(entry)
        try context.save()

        let copy = medley.duplicate(in: context)
        try context.save()

        XCTAssertEqual(medley.sortedEntries[0].song.persistentModelID,
                       copy.sortedEntries[0].song.persistentModelID)
    }

    func test_duplicate_preservesEntryOrder() throws {
        let medley = Medley(name: "Rock 1")
        context.insert(medley)
        let songs = ["Girl", "Zombie", "Teen Spirit"].map { Song(title: $0) }
        songs.forEach { context.insert($0) }
        for song in songs {
            let entry = MedleyEntry(song: song)
            context.insert(entry)
            medley.addEntry(entry)
        }
        try context.save()

        let copy = medley.duplicate(in: context)
        try context.save()

        XCTAssertEqual(copy.sortedEntries.map { $0.song.title },
                       ["Girl", "Zombie", "Teen Spirit"])
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' \
  -only-testing:LeadifyTests/MedleyTests 2>&1 | tail -20
```

Expected: Compilation errors — `Medley`, `MedleyEntry` not defined.

- [ ] **Step 3: Create Medley model**

Create `Leadify/Models/Medley.swift`:

```swift
import SwiftData
import Foundation

@Model
final class Medley {
    var name: String
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade) var entries: [MedleyEntry]

    init(name: String) {
        self.name = name
        self.entries = []
    }

    /// Entries sorted by their explicit order index. Always use this for display and iteration.
    var sortedEntries: [MedleyEntry] {
        entries.sorted { $0.order < $1.order }
    }

    /// Appends an entry and assigns its order after the current last entry.
    func addEntry(_ entry: MedleyEntry) {
        entry.order = (entries.max(by: { $0.order < $1.order })?.order ?? -1) + 1
        entries.append(entry)
    }

    /// Creates a copy of this medley. Songs are shared by reference (same as setlist duplication).
    func duplicate(in context: ModelContext) -> Medley {
        let copy = Medley(name: "\(name) (copy)")
        context.insert(copy)
        for (index, entry) in sortedEntries.enumerated() {
            let entryCopy = MedleyEntry(song: entry.song)
            entryCopy.order = index
            context.insert(entryCopy)
            copy.entries.append(entryCopy)
        }
        return copy
    }
}
```

- [ ] **Step 4: Create MedleyEntry model**

Create `Leadify/Models/MedleyEntry.swift`:

```swift
import SwiftData
import Foundation

@Model
final class MedleyEntry {
    var song: Song
    var order: Int = 0
    var createdAt: Date = Date()

    init(song: Song) {
        self.song = song
    }
}
```

- [ ] **Step 5: Add Medley and MedleyEntry to ModelContainer**

In `Leadify/LeadifyApp.swift`, change line 14 from:

```swift
container = try ModelContainer(for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self)
```

to:

```swift
container = try ModelContainer(for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self, Medley.self, MedleyEntry.self)
```

- [ ] **Step 6: Add Medley and MedleyEntry to test container**

In `LeadifyTests/TestHelpers.swift`, change line 9 from:

```swift
for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self,
```

to:

```swift
for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self, Medley.self, MedleyEntry.self,
```

- [ ] **Step 7: Add new files to Xcode target, then run tests**

Tell the user to add the new files to the Xcode target:
- `Leadify/Models/Medley.swift`
- `Leadify/Models/MedleyEntry.swift`
- `LeadifyTests/MedleyTests.swift`

Then run:

```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' 2>&1 | tail -30
```

Expected: All tests pass (existing + new MedleyTests).

- [ ] **Step 8: Commit**

```bash
git add Leadify/Models/Medley.swift Leadify/Models/MedleyEntry.swift \
  Leadify/LeadifyApp.swift LeadifyTests/TestHelpers.swift LeadifyTests/MedleyTests.swift
git commit -m "feat: add Medley and MedleyEntry models with ordering and duplication"
```

---

### Task 2: Extend SetlistEntry to support medleys + tests

**Files:**
- Modify: `Leadify/Models/SetlistEntry.swift`
- Modify: `Leadify/Models/Setlist.swift` (update duplicate to handle medley entries)
- Modify: `LeadifyTests/SetlistTests.swift` (add medley-related tests)

- [ ] **Step 1: Write failing tests for medley entries in setlists**

Add to `LeadifyTests/SetlistTests.swift`:

```swift
// MARK: - Medley entries

func test_medleyEntry_hasCorrectItemType() throws {
    let medley = Medley(name: "Rock 1")
    context.insert(medley)
    let entry = SetlistEntry(medley: medley)
    context.insert(entry)
    XCTAssertEqual(entry.itemType, .medley)
}

func test_duplicate_sharesMedleyReferences() throws {
    let medley = Medley(name: "Rock 1")
    context.insert(medley)
    let original = Setlist(name: "Gig A")
    context.insert(original)
    let entry = SetlistEntry(medley: medley)
    context.insert(entry)
    original.addEntry(entry)
    try context.save()

    let copy = original.duplicate(in: context)
    try context.save()

    XCTAssertEqual(copy.sortedEntries[0].medley?.persistentModelID,
                   medley.persistentModelID)
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' \
  -only-testing:LeadifyTests/SetlistTests 2>&1 | tail -20
```

Expected: Compilation errors — no `SetlistEntry(medley:)` initializer, no `.medley` case.

- [ ] **Step 3: Extend SetlistItemType and SetlistEntry**

Replace the full contents of `Leadify/Models/SetlistEntry.swift`:

```swift
import SwiftData
import Foundation

enum SetlistItemType {
    case song
    case tacet
    case medley
}

@Model
final class SetlistEntry {
    var song: Song?
    @Relationship(deleteRule: .cascade) var tacet: Tacet?
    var medley: Medley?
    var order: Int = 0
    var createdAt: Date = Date()

    /// Derived from which optional is non-nil. Extend this enum to add new item types.
    var itemType: SetlistItemType {
        if medley != nil { return .medley }
        if song != nil { return .song }
        return .tacet
    }

    init(song: Song) {
        self.song = song
        self.tacet = nil
        self.medley = nil
    }

    init(tacet: Tacet) {
        self.song = nil
        self.tacet = tacet
        self.medley = nil
    }

    init(medley: Medley) {
        self.song = nil
        self.tacet = nil
        self.medley = medley
    }
}
```

- [ ] **Step 4: Update Setlist.duplicate to handle medley entries**

In `Leadify/Models/Setlist.swift`, replace the `duplicate(in:)` method (lines 40-60) with:

```swift
/// Creates a copy of this setlist with a new name.
/// - Songs are shared by reference (editing a song updates all setlists).
/// - Tacets are deep-copied (they are owned by their entry).
/// - Medleys are shared by reference (same as songs).
func duplicate(in context: ModelContext) -> Setlist {
    let copy = Setlist(name: "\(name) (copy)", date: date)
    context.insert(copy)
    for (index, entry) in sortedEntries.enumerated() {
        let entryCopy: SetlistEntry
        switch entry.itemType {
        case .song:
            entryCopy = SetlistEntry(song: entry.song!)
        case .tacet:
            let tacetCopy = Tacet(label: entry.tacet?.label)
            context.insert(tacetCopy)
            entryCopy = SetlistEntry(tacet: tacetCopy)
        case .medley:
            entryCopy = SetlistEntry(medley: entry.medley!)
        }
        entryCopy.order = index
        context.insert(entryCopy)
        copy.entries.append(entryCopy)
    }
    return copy
}
```

- [ ] **Step 5: Run all tests**

```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' 2>&1 | tail -30
```

Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add Leadify/Models/SetlistEntry.swift Leadify/Models/Setlist.swift \
  LeadifyTests/SetlistTests.swift
git commit -m "feat: extend SetlistEntry with medley support"
```

---

### Task 3: Theme tokens for medley UI

**Files:**
- Modify: `Leadify/Theme/EditTheme.swift`
- Modify: `Leadify/Theme/PerformanceTheme.swift`

- [ ] **Step 1: Add EditTheme tokens for medley group display**

In `Leadify/Theme/EditTheme.swift`, add after `static let destructiveColor = Color.red` (line 22):

```swift
// Medley
static let medleyHeaderColor = Color.accentColor
static let medleyGroupBackground = Color(light: Color.accentColor.opacity(0.06), dark: Color.accentColor.opacity(0.1))
```

Note: `EditTheme` needs the `Color(light:dark:)` initializer. Since it's already defined in `PerformanceTheme.swift` as an extension on `Color`, it's available here.

- [ ] **Step 2: Add PerformanceTheme tokens for medley indicator**

In `Leadify/Theme/PerformanceTheme.swift`, add after `static let closeButtonColor` (line 31):

```swift
// Medley indicator
static let medleyIndicatorSize: CGFloat = 14
static let medleyIndicatorColor = Color(light: Color(white: 0.5), dark: Color(white: 0.5))
```

- [ ] **Step 3: Build to verify**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add Leadify/Theme/EditTheme.swift Leadify/Theme/PerformanceTheme.swift
git commit -m "feat: add theme tokens for medley UI"
```

---

### Task 4: Sidebar — add Medleys section to navigation

**Files:**
- Modify: `Leadify/ContentView.swift`

- [ ] **Step 1: Add `.medleys` case to `SidebarItem`**

In `Leadify/ContentView.swift`, update the `SidebarItem` enum (lines 4-23) to:

```swift
enum SidebarItem: String, CaseIterable, Identifiable {
    case setlists
    case songs
    case medleys

    var id: String { rawValue }

    var title: String {
        switch self {
        case .setlists: "Setlists"
        case .songs: "Songs"
        case .medleys: "Medleys"
        }
    }

    var icon: String {
        switch self {
        case .setlists: "music.note.list"
        case .songs: "music.note"
        case .medleys: "rectangle.stack.fill"
        }
    }
}
```

- [ ] **Step 2: Add medley state and query to ContentView**

In `Leadify/ContentView.swift`, add after the existing `@State` properties (after line 34):

```swift
@State private var selectedMedley: Medley?
@Query private var allMedleys: [Medley]
```

- [ ] **Step 3: Add medleys content column**

In `Leadify/ContentView.swift`, inside the `content:` closure of `NavigationSplitView` (around line 55-72), add the `.medleys` case to the switch. Replace the `Group { switch ... }` block with:

```swift
Group {
    switch selectedSidebarItem {
    case .setlists:
        SetlistSidebarView(
            setlists: sortedSetlists,
            selectedSetlist: $selectedSetlist
        )
    case .songs:
        SongLibrarySidebarView(selectedSong: $selectedSong)
    case .medleys:
        MedleySidebarView(selectedMedley: $selectedMedley)
    case nil:
        ContentUnavailableView(
            "Select a Category",
            systemImage: "sidebar.left",
            description: Text("Choose Setlists, Songs, or Medleys from the sidebar.")
        )
    }
}
```

- [ ] **Step 4: Add medleys detail column**

In the `detail:` column's switch (around line 77-107), add the `.medleys` case. Replace the full switch with:

```swift
switch selectedSidebarItem {
case .setlists:
    if let setlist = selectedSetlist {
        SetlistDetailView(setlist: setlist, selectedSetlist: $selectedSetlist)
    } else {
        ContentUnavailableView(
            "No Setlist Selected",
            systemImage: "music.note.list",
            description: Text("Select a setlist or create a new one.")
        )
    }
case .songs:
    if let song = selectedSong {
        if isEditingSong {
            SongEditorDetailView(song: song, selectedSong: $selectedSong, isEditing: $isEditingSong)
                .id("\(song.persistentModelID)-edit")
        } else {
            SongDisplayView(song: song, selectedSong: $selectedSong, isEditing: $isEditingSong)
                .id(song.persistentModelID)
        }
    } else {
        ContentUnavailableView(
            "No Song Selected",
            systemImage: "music.note",
            description: Text("Select a song from the library to edit it.")
        )
    }
case .medleys:
    if let medley = selectedMedley {
        MedleyDetailView(medley: medley, selectedMedley: $selectedMedley)
    } else {
        ContentUnavailableView(
            "No Medley Selected",
            systemImage: "rectangle.stack.fill",
            description: Text("Select a medley or create a new one.")
        )
    }
case nil:
    Color.clear
}
```

- [ ] **Step 5: Update Preview**

In `ContentView.swift`, update the `#Preview` to include the new model types:

```swift
#Preview {
    ContentView()
        .modelContainer(for: [Song.self, Tacet.self, SetlistEntry.self, Setlist.self, Medley.self, MedleyEntry.self],
                        inMemory: true)
        .environment(SongImporter())
}
```

- [ ] **Step 6: Build (will fail — MedleySidebarView and MedleyDetailView don't exist yet)**

This is expected. These views are created in the next tasks. Build should produce only "cannot find 'MedleySidebarView'" and "cannot find 'MedleyDetailView'" errors.

- [ ] **Step 7: Commit (partial — compiles after tasks 5 and 6)**

Don't commit yet — wait until MedleySidebarView and MedleyDetailView exist so the build passes. Commit together with Task 5 or after Task 6.

---

### Task 5: MedleySidebarView + MedleySidebarRow + MedleyEditSheet

**Files:**
- Create: `Leadify/Views/Medley/MedleySidebarView.swift`
- Create: `Leadify/Views/Medley/MedleySidebarRow.swift`
- Create: `Leadify/Views/Medley/MedleyEditSheet.swift`

- [ ] **Step 1: Create MedleyEditSheet**

Create `Leadify/Views/Medley/MedleyEditSheet.swift`:

```swift
import SwiftUI
import SwiftData

struct MedleyEditSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var medley: Medley?

    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Medley name", text: $name)
                }
            }
            .navigationTitle(medley == nil ? "New Medley" : "Edit Medley")
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
        guard let medley else { return }
        name = medley.name
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if let medley {
            medley.name = trimmedName
        } else {
            let newMedley = Medley(name: trimmedName)
            context.insert(newMedley)
        }
        dismiss()
    }
}
```

- [ ] **Step 2: Create MedleySidebarRow**

Create `Leadify/Views/Medley/MedleySidebarRow.swift`:

```swift
import SwiftUI
import SwiftData

struct MedleySidebarRow: View {
    let medley: Medley
    @Binding var selectedMedley: Medley?
    @Environment(\.modelContext) private var context
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false

    private var isSelected: Bool {
        selectedMedley?.persistentModelID == medley.persistentModelID
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(medley.name)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? Color.white : Color.primary)

            Text("\(medley.entries.count) song\(medley.entries.count == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.secondary)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                duplicateMedley()
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            .tint(.blue)

            Button {
                showEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.orange)
        }
        .contextMenu {
            Button {
                showEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button {
                duplicateMedley()
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }

            Divider()

            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showEditSheet) {
            MedleyEditSheet(medley: medley)
        }
        .alert("Delete \"\(medley.name)\"?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { deleteMedley() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the medley. Songs in your library are not affected.")
        }
    }

    private func duplicateMedley() {
        let copy = medley.duplicate(in: context)
        selectedMedley = copy
    }

    private func deleteMedley() {
        if selectedMedley?.persistentModelID == medley.persistentModelID {
            selectedMedley = nil
        }
        context.delete(medley)
    }
}
```

- [ ] **Step 3: Create MedleySidebarView**

Create `Leadify/Views/Medley/MedleySidebarView.swift`:

```swift
import SwiftUI
import SwiftData

struct MedleySidebarView: View {
    @Query private var allMedleys: [Medley]
    @Binding var selectedMedley: Medley?
    @State private var showNewMedleySheet = false

    var sortedMedleys: [Medley] {
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
            MedleyEditSheet(medley: nil)
        }
    }
}
```

- [ ] **Step 4: Add new files to Xcode target, build, and run**

Tell the user to add files to Xcode target:
- `Leadify/Views/Medley/MedleySidebarView.swift`
- `Leadify/Views/Medley/MedleySidebarRow.swift`
- `Leadify/Views/Medley/MedleyEditSheet.swift`

Build and run:

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' 2>&1 | tail -10
```

Expected: Will still fail because `MedleyDetailView` doesn't exist yet (referenced in ContentView Task 4). Proceed to Task 6.

---

### Task 6: MedleyDetailView

**Files:**
- Create: `Leadify/Views/Medley/MedleyDetailView.swift`

- [ ] **Step 1: Create MedleyDetailView**

Create `Leadify/Views/Medley/MedleyDetailView.swift`:

```swift
import SwiftUI
import SwiftData

struct MedleyDetailView: View {
    @Bindable var medley: Medley
    @Binding var selectedMedley: Medley?
    @Environment(\.modelContext) private var context

    @State private var showSongLibrary = false
    @State private var editingEntry: MedleyEntry?
    @State private var showPerformance = false
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false

    var body: some View {
        List {
            if medley.sortedEntries.isEmpty {
                emptyStateView
            } else {
                entriesSection
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(medley.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                medleyMenu
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showSongLibrary = true
                } label: {
                    Label("Add Song", systemImage: "plus")
                }

                performButton
            }
        }
        .sheet(isPresented: $showSongLibrary) {
            MedleySongLibrarySheet(medley: medley)
        }
        .sheet(item: $editingEntry) { entry in
            SongEditorSheet(song: entry.song)
        }
        .fullScreenCover(isPresented: $showPerformance) {
            MedleyPerformanceView(medley: medley)
        }
        .sheet(isPresented: $showEditSheet) {
            MedleyEditSheet(medley: medley)
        }
        .alert("Delete \"\(medley.name)\"?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { deleteMedley() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the medley. Songs in your library are not affected.")
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "rectangle.stack")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("No songs yet")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("A medley is a fixed group of songs played in order. Add songs to build your medley.")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }

    private var entriesSection: some View {
        Section {
            ForEach(Array(medley.sortedEntries.enumerated()), id: \.element.persistentModelID) { index, entry in
                MedleySongRow(entry: entry, position: index + 1) {
                    editingEntry = entry
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteEntry(entry)
                    } label: {
                        Label("", systemImage: "trash")
                    }
                }
            }
            .onMove(perform: moveEntries)
            .onDelete(perform: deleteEntries)
        }
    }

    private var medleyMenu: some View {
        Menu {
            Button {
                showEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button {
                duplicateMedley()
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }

            Divider()

            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Label("Options", systemImage: "ellipsis.circle")
                .labelStyle(.iconOnly)
        }
    }

    private var performButton: some View {
        Button {
            showPerformance = true
        } label: {
            Label("Perform", systemImage: "play.circle.fill")
                .labelStyle(.iconOnly)
                .font(.system(size: 20))
        }
        .disabled(medley.sortedEntries.isEmpty)
    }

    // MARK: - Actions

    private func moveEntries(from source: IndexSet, to destination: Int) {
        var sorted = medley.sortedEntries
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, entry) in sorted.enumerated() {
            entry.order = index
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            let entry = medley.sortedEntries[index]
            deleteEntry(entry)
        }
    }

    private func duplicateMedley() {
        let copy = medley.duplicate(in: context)
        selectedMedley = copy
    }

    private func deleteMedley() {
        selectedMedley = nil
        context.delete(medley)
    }

    private func deleteEntry(_ entry: MedleyEntry) {
        withAnimation {
            medley.entries.removeAll { $0.persistentModelID == entry.persistentModelID }
            context.delete(entry)
        }
    }
}
```

- [ ] **Step 2: Create MedleySongRow**

This is a simple row that shows just the song title (same as `SongSetlistRow` pattern). Add it to the same file or create separately. Add at the bottom of `MedleyDetailView.swift`:

Actually, create a separate file `Leadify/Views/Medley/MedleySongRow.swift`:

```swift
import SwiftUI

struct MedleySongRow: View {
    let entry: MedleyEntry
    let position: Int
    let onEdit: () -> Void

    var body: some View {
        Text(entry.song.title)
            .font(.body)
            .fontWeight(.regular)
            .foregroundStyle(.primary)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onEdit)
    }
}
```

- [ ] **Step 3: Create MedleySongLibrarySheet**

Create `Leadify/Views/Medley/MedleySongLibrarySheet.swift`:

```swift
import SwiftUI
import SwiftData

struct MedleySongLibrarySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let medley: Medley

    @Query(sort: \Song.title) private var allSongs: [Song]
    @State private var searchText = ""
    @State private var showNewSongEditor = false

    private var filteredSongs: [Song] {
        guard !searchText.isEmpty else { return allSongs }
        return allSongs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var songsInMedley: Set<PersistentIdentifier> {
        Set(medley.entries.map { $0.song.persistentModelID })
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(filteredSongs) { song in
                        HStack {
                            Text(song.title)
                                .font(.body)
                                .fontWeight(.regular)
                            Spacer()
                            if songsInMedley.contains(song.persistentModelID) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.secondary)
                            } else {
                                Button {
                                    addSong(song)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .opacity(songsInMedley.contains(song.persistentModelID) ? 0.5 : 1.0)
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search songs")
            .navigationTitle("Add Song to Medley")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
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
        let entry = MedleyEntry(song: song)
        context.insert(entry)
        medley.addEntry(entry)
    }
}
```

- [ ] **Step 4: Create MedleyPerformanceView (stub — uses existing PerformanceView pattern)**

Create `Leadify/Views/Medley/MedleyPerformanceView.swift`:

```swift
import SwiftUI

struct MedleyPerformanceView: View {
    let medley: Medley
    @Environment(\.dismiss) private var dismiss

    @State private var scrollPosition = ScrollPosition()
    @State private var scrollOffset: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                PerformanceTheme.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(medley.sortedEntries.enumerated()), id: \.element.persistentModelID) { index, entry in
                            SongPerformanceBlock(
                                song: entry.song,
                                medleyName: medley.name,
                                medleyPosition: index + 1,
                                medleyTotal: medley.entries.count
                            )
                            .padding(.horizontal, 32)
                        }
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 80)
                    .background(GeometryReader { contentGeo in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: -contentGeo.frame(in: .named("scrollContainer")).minY
                        )
                    })
                }
                .coordinateSpace(name: "scrollContainer")
                .scrollPosition($scrollPosition)
                .onPreferenceChange(ScrollOffsetKey.self) { scrollOffset = $0 }
                .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentOffset.y }) { _, y in
                    scrollOffset = y
                }
                .overlay(alignment: .top) {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: geo.size.height * 0.2)
                        .contentShape(Rectangle())
                        .simultaneousGesture(TapGesture().onEnded { scrollUp() })
                }
                .overlay(alignment: .bottom) {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: geo.size.height * 0.2)
                        .contentShape(Rectangle())
                        .padding(.bottom, 20)
                        .simultaneousGesture(TapGesture().onEnded { scrollDown() })
                }
            }
            .onAppear { viewportHeight = geo.size.height }
            .onChange(of: geo.size.height) { _, h in viewportHeight = h }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .padding(16)
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    private func scrollUp() {
        let target = max(0, scrollOffset - viewportHeight)
        scrollOffset = target
        withAnimation(.easeInOut(duration: 0.15)) {
            scrollPosition.scrollTo(y: target)
        }
    }

    private func scrollDown() {
        let target = scrollOffset + viewportHeight
        scrollOffset = target
        withAnimation(.easeInOut(duration: 0.15)) {
            scrollPosition.scrollTo(y: target)
        }
    }
}

// Reuse the same preference key pattern from PerformanceView
private struct ScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
```

Note: This references `SongPerformanceBlock` with new optional parameters `medleyName`, `medleyPosition`, `medleyTotal`. Those are added in Task 8.

- [ ] **Step 5: Add new files to Xcode target**

Tell the user to add files to Xcode target:
- `Leadify/Views/Medley/MedleyDetailView.swift`
- `Leadify/Views/Medley/MedleySongRow.swift`
- `Leadify/Views/Medley/MedleySongLibrarySheet.swift`
- `Leadify/Views/Medley/MedleyPerformanceView.swift`

- [ ] **Step 6: Build (will fail — SongPerformanceBlock changes not yet made)**

Expected: Errors about `SongPerformanceBlock` initializer — those are fixed in Task 8. All other code should be correct.

---

### Task 7: Medleys in setlist detail view

**Files:**
- Modify: `Leadify/Views/Setlist/SetlistDetailView.swift`
- Create: `Leadify/Views/Setlist/MedleySetlistGroup.swift`
- Create: `Leadify/Views/Setlist/MedleyLibrarySheet.swift`

- [ ] **Step 1: Create MedleySetlistGroup (the grouped medley block in setlist view)**

Create `Leadify/Views/Setlist/MedleySetlistGroup.swift`:

```swift
import SwiftUI

struct MedleySetlistGroup: View {
    let entry: SetlistEntry
    let onEditSong: (Song) -> Void

    private var medley: Medley { entry.medley! }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Medley header
            Text(medley.name)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(EditTheme.medleyHeaderColor)
                .padding(.vertical, 4)

            // Songs within the medley
            ForEach(medley.sortedEntries) { medleyEntry in
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(EditTheme.medleyHeaderColor.opacity(0.3))
                        .frame(width: 3)

                    Text(medleyEntry.song.title)
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    onEditSong(medleyEntry.song)
                }
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(EditTheme.medleyGroupBackground)
    }
}
```

- [ ] **Step 2: Create MedleyLibrarySheet**

Create `Leadify/Views/Setlist/MedleyLibrarySheet.swift`:

```swift
import SwiftUI
import SwiftData

struct MedleyLibrarySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let setlist: Setlist

    @Query(sort: \Medley.name) private var allMedleys: [Medley]

    private var medleysInSetlist: Set<PersistentIdentifier> {
        Set(setlist.entries.compactMap { $0.medley?.persistentModelID })
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(allMedleys) { medley in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(medley.name)
                                    .font(.body)
                                    .fontWeight(.regular)
                                Text("\(medley.entries.count) song\(medley.entries.count == 1 ? "" : "s")")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if medleysInSetlist.contains(medley.persistentModelID) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.secondary)
                            } else {
                                Button {
                                    addMedley(medley)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .opacity(medleysInSetlist.contains(medley.persistentModelID) ? 0.5 : 1.0)
                    }
                }
            }
            .navigationTitle("Add Medley to Setlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func addMedley(_ medley: Medley) {
        let entry = SetlistEntry(medley: medley)
        context.insert(entry)
        setlist.addEntry(entry)
    }
}
```

- [ ] **Step 3: Update SetlistDetailView to support medley entries**

In `Leadify/Views/Setlist/SetlistDetailView.swift`:

Add a new `@State` property after `showTacetEdit` (line 10):

```swift
@State private var showMedleyLibrary = false
```

Add a state for editing songs from medleys (after `editingEntry`):

```swift
@State private var editingSongFromMedley: Song?
```

In the toolbar `ToolbarItemGroup` (lines 32-45), add the medley button between the tacet and song buttons:

```swift
ToolbarItemGroup(placement: .topBarTrailing) {
    Button {
        showTacetEdit = true
    } label: {
        Label("Add Tacet", systemImage: "pause.circle")
    }
    Button {
        showMedleyLibrary = true
    } label: {
        Label("Add Medley", systemImage: "rectangle.stack")
    }
    Button {
        showSongLibrary = true
    } label: {
        Label("Add Song", systemImage: "plus")
    }

    performButton
}
```

Add the medley library sheet (after the tacet edit sheet, around line 50):

```swift
.sheet(isPresented: $showMedleyLibrary) {
    MedleyLibrarySheet(setlist: setlist)
}
```

Add a sheet for editing songs tapped from within a medley group:

```swift
.sheet(item: $editingSongFromMedley) { song in
    SongEditorSheet(song: song)
}
```

Update the `entryRow` function (lines 117-130) to handle the `.medley` case:

```swift
private func entryRow(entry: SetlistEntry, position: Int) -> some View {
    Group {
        switch entry.itemType {
        case .song:
            SongSetlistRow(entry: entry, position: position) {
                editingEntry = entry
            }
        case .tacet:
            TacetSetlistRow(entry: entry, position: position) {
                editingEntry = entry
            }
        case .medley:
            MedleySetlistGroup(entry: entry) { song in
                editingSongFromMedley = song
            }
        }
    }
}
```

- [ ] **Step 4: Add new files to Xcode target**

Tell user to add:
- `Leadify/Views/Setlist/MedleySetlistGroup.swift`
- `Leadify/Views/Setlist/MedleyLibrarySheet.swift`

- [ ] **Step 5: Build (will still fail on SongPerformanceBlock — that's Task 8)**

Expected: Only `SongPerformanceBlock` initializer errors remain.

---

### Task 8: Performance mode — medley indicator on SongPerformanceBlock

**Files:**
- Modify: `Leadify/Views/Performance/SongPerformanceBlock.swift`
- Modify: `Leadify/Views/Performance/PerformanceView.swift`

- [ ] **Step 1: Add optional medley parameters to SongPerformanceBlock**

Replace the full contents of `Leadify/Views/Performance/SongPerformanceBlock.swift`:

```swift
import SwiftUI
import MarkdownUI

struct SongPerformanceBlock: View {
    let song: Song
    var medleyName: String? = nil
    var medleyPosition: Int? = nil
    var medleyTotal: Int? = nil
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Medley indicator
            if let medleyName, let medleyPosition, let medleyTotal {
                Text("\(medleyName) — \(medleyPosition)/\(medleyTotal)")
                    .font(.system(size: PerformanceTheme.medleyIndicatorSize, weight: .medium))
                    .foregroundStyle(PerformanceTheme.medleyIndicatorColor)
                    .padding(.bottom, 8)
            }

            // Title and Reminder Header
            HStack(alignment: .center, spacing: 12) {
                // Title
                Text(song.title)
                    .font(.system(size: PerformanceTheme.songTitleSize, weight: .bold))
                    .foregroundStyle(PerformanceTheme.songTitleColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Reminder (if exists) - Pill style on the right
                if let reminder = song.reminder {
                    Text(reminder)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(EditTheme.accentColor)
                        )
                }
            }
            .padding(.bottom, 28)

            // Thin divider line
            Rectangle()
                .fill(PerformanceTheme.dividerColor)
                .frame(height: 1)
                .padding(.bottom, 28)

            // Content
            Markdown(song.content)
                .markdownTheme(.leadifyPerformance)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 32)
        .background(
            colorScheme == .dark ? Color(white: 0.09) : Color.white
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(
            color: colorScheme == .dark ? .black.opacity(0.4) : .black.opacity(0.12),
            radius: colorScheme == .dark ? 12 : 8,
            x: 0,
            y: colorScheme == .dark ? 6 : 4
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}
```

Because `medleyName`, `medleyPosition`, and `medleyTotal` all have default values of `nil`, existing call sites (`PerformanceView`, etc.) don't need changes — they'll continue to work without medley info.

- [ ] **Step 2: Update PerformanceView to pass medley info**

In `Leadify/Views/Performance/PerformanceView.swift`, update the `ForEach` body (lines 25-33) to pass medley context:

Replace:

```swift
ForEach(setlist.sortedEntries) { entry in
    Group {
        switch entry.itemType {
        case .song:
            SongPerformanceBlock(song: entry.song!)
        case .tacet:
            TacetPerformanceBlock(tacet: entry.tacet!)
        }
    }
    .padding(.horizontal, 32)
}
```

With:

```swift
ForEach(setlist.sortedEntries) { entry in
    Group {
        switch entry.itemType {
        case .song:
            SongPerformanceBlock(song: entry.song!)
        case .tacet:
            TacetPerformanceBlock(tacet: entry.tacet!)
        case .medley:
            if let medley = entry.medley {
                ForEach(Array(medley.sortedEntries.enumerated()), id: \.element.persistentModelID) { index, medleyEntry in
                    SongPerformanceBlock(
                        song: medleyEntry.song,
                        medleyName: medley.name,
                        medleyPosition: index + 1,
                        medleyTotal: medley.entries.count
                    )
                }
            }
        }
    }
    .padding(.horizontal, 32)
}
```

- [ ] **Step 3: Build and run on simulator**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED. The full app should now compile.

Run on simulator:

```bash
xcrun simctl terminate B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5 bartvanraaij.Leadify 2>/dev/null
xcrun simctl install B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5 \
  ~/Library/Developer/Xcode/DerivedData/Leadify-dcfskxmsfskcybdoxvrgstsbknvm/Build/Products/Debug-iphonesimulator/Leadify.app
xcrun simctl launch B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5 bartvanraaij.Leadify
```

- [ ] **Step 4: Run all tests**

```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' 2>&1 | tail -30
```

Expected: All tests pass.

- [ ] **Step 5: Commit all remaining uncommitted work**

```bash
git add -A
git commit -m "feat: complete medley feature — sidebar, detail, setlist integration, performance mode"
```

---

### Task 9: Update CLAUDE.md with medley information

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update project layout section**

Add medley files to the project layout tree in CLAUDE.md:

Under `Views/`:
```
│           ├── Medley/                  MedleySidebarView, MedleySidebarRow, MedleyEditSheet,
│           │                            MedleyDetailView, MedleySongRow, MedleySongLibrarySheet,
│           │                            MedleyPerformanceView
```

Under `Models/`:
```
│       ├── Models/                      Song, Tacet, SetlistEntry, Setlist, Medley, MedleyEntry
```

Under `Views/Setlist/`:
Add `MedleySetlistGroup, MedleyLibrarySheet` to the Setlist view list.

- [ ] **Step 2: Update data model key facts**

Add to the "Data model key facts" section:

```
- `Medley` — a fixed group of songs in a specific order. Shared across setlists by reference (like Song).
- `MedleyEntry` — join object holding a `Song` reference with an `order` field. Same ordering pattern as `SetlistEntry`.
- `SetlistEntry` — now has three item types: `.song`, `.tacet`, `.medley`. The `medley` relationship is shared (no cascade).
- Medley ordering uses the same `sortedEntries` / `addEntry` pattern as Setlist.
```

- [ ] **Step 3: Update sidebar description**

Update the "Current status" section to reflect the three-segment sidebar: Setlists / Songs / Medleys.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md with medley feature documentation"
```
