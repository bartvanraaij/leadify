# Song Library UI — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Song Library sidebar mode with sortable song list and full-pane side-by-side editor, backed by `createdAt` timestamps on all models.

**Architecture:** A `SidebarMode` enum in `ContentView` drives which sidebar view renders and which detail view shows. A cascade `@Relationship` on `Song` ensures deleting a song also removes all `SetlistEntry` rows that reference it. The new `SongEditorDetailView` uses `@Bindable` for live SwiftData writes with no explicit Save button.

**Tech Stack:** SwiftUI, SwiftData (lightweight migration handles `createdAt` default), MarkdownUI (existing `.leadifyPerformance` theme and `SongContentPreview` struct reused from `SongEditorSheet.swift`)

---

## File Map

| File | Action | Purpose |
|------|--------|---------|
| `Leadify/Models/Song.swift` | Modify | Add `createdAt`, add cascade `entries` relationship |
| `Leadify/Models/Setlist.swift` | Modify | Add `createdAt` |
| `Leadify/Models/SetlistEntry.swift` | Modify | Add `createdAt` |
| `Leadify/ContentView.swift` | Modify | Add `SidebarMode`, `sidebarMode`, `selectedSong`, segmented picker, conditional rendering |
| `Leadify/Views/Sidebar/SongLibrarySidebarView.swift` | Create | Song list with sort and swipe-to-delete |
| `Leadify/Views/Setlist/SongEditorDetailView.swift` | Create | Full-pane side-by-side editor + preview |
| `LeadifyTests/SongTests.swift` | Modify | Tests for `createdAt` and cascade delete |

---

## Task 1: Update data models

**Files:**
- Modify: `Leadify/Models/Song.swift`
- Modify: `Leadify/Models/Setlist.swift`
- Modify: `Leadify/Models/SetlistEntry.swift`
- Modify: `LeadifyTests/SongTests.swift`

- [ ] **Step 1: Write failing tests**

Add to `LeadifyTests/SongTests.swift` inside the `SongTests` class:

```swift
func test_song_hasCreatedAt() throws {
    let before = Date()
    let song = Song(title: "Test", content: "")
    context.insert(song)
    try context.save()

    let songs = try context.fetch(FetchDescriptor<Song>())
    XCTAssertGreaterThanOrEqual(songs[0].createdAt, before)
}

func test_deletingSong_cascadesToSetlistEntries() throws {
    let song = Song(title: "Cascade Test", content: "")
    context.insert(song)
    let setlist = Setlist(name: "Test Setlist")
    context.insert(setlist)
    let entry = SetlistEntry(song: song)
    context.insert(entry)
    setlist.addEntry(entry)
    try context.save()

    context.delete(song)
    try context.save()

    let entries = try context.fetch(FetchDescriptor<SetlistEntry>())
    XCTAssertTrue(entries.isEmpty, "SetlistEntry should be deleted when its song is deleted")
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=2EB88329-DA02-4D84-ABFD-8E49B53AF6B8' \
  -only-testing:LeadifyTests/SongTests/test_song_hasCreatedAt \
  2>&1 | grep -E "(FAIL|PASS|error:)"
```

Expected: FAIL — `Song` has no `createdAt` property (compile error or assertion failure).

- [ ] **Step 3: Replace `Leadify/Models/Song.swift`**

```swift
import SwiftData
import Foundation

@Model
final class Song {
    var title: String
    var content: String
    var reminder: String?
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \SetlistEntry.song)
    var entries: [SetlistEntry] = []

    init(title: String, content: String = "", reminder: String? = nil) {
        self.title = title
        self.content = content
        self.reminder = reminder
    }
}
```

- [ ] **Step 4: Add `createdAt` to `Leadify/Models/Setlist.swift`**

Add one line after `var date: Date?`:

```swift
var date: Date?
var createdAt: Date = Date()
```

- [ ] **Step 5: Add `createdAt` to `Leadify/Models/SetlistEntry.swift`**

Add one line after `var order: Int = 0`:

```swift
var order: Int = 0
var createdAt: Date = Date()
```

- [ ] **Step 6: Run all tests to verify they pass**

```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=2EB88329-DA02-4D84-ABFD-8E49B53AF6B8' \
  2>&1 | grep -E "(FAIL|PASS|Test Suite)"
```

Expected: All tests pass, including the two new ones.

- [ ] **Step 7: Commit**

```bash
git add Leadify/Models/Song.swift Leadify/Models/Setlist.swift \
  Leadify/Models/SetlistEntry.swift LeadifyTests/SongTests.swift
git commit -m "feat: add createdAt to all models and cascade delete Song→SetlistEntry"
```

---

## Task 2: Restructure ContentView for sidebar modes

**Files:**
- Modify: `Leadify/ContentView.swift`

Note: `SongLibrarySidebarView` and `SongEditorDetailView` don't exist yet — the build will fail after this task until Tasks 3 and 4 are done. That's expected.

- [ ] **Step 1: Replace `Leadify/ContentView.swift`**

```swift
import SwiftUI
import SwiftData

enum SidebarMode {
    case setlists, songs
}

struct ContentView: View {
    @Query private var allSetlists: [Setlist]
    @State private var sidebarMode: SidebarMode = .setlists
    @State private var selectedSetlist: Setlist?
    @State private var selectedSong: Song?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

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
        NavigationSplitView(columnVisibility: $columnVisibility) {
            Group {
                switch sidebarMode {
                case .setlists:
                    SetlistSidebarView(
                        setlists: sortedSetlists,
                        selectedSetlist: $selectedSetlist
                    )
                case .songs:
                    SongLibrarySidebarView(selectedSong: $selectedSong)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker("", selection: $sidebarMode) {
                        Text("Setlists").tag(SidebarMode.setlists)
                        Text("Songs").tag(SidebarMode.songs)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 190)
                }
            }
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        } detail: {
            switch sidebarMode {
            case .setlists:
                if let setlist = selectedSetlist {
                    SetlistDetailView(setlist: setlist)
                } else {
                    ContentUnavailableView(
                        "No Setlist Selected",
                        systemImage: "music.note.list",
                        description: Text("Select a setlist from the sidebar or create a new one.")
                    )
                }
            case .songs:
                if let song = selectedSong {
                    SongEditorDetailView(song: song, selectedSong: $selectedSong)
                } else {
                    ContentUnavailableView(
                        "No Song Selected",
                        systemImage: "music.note",
                        description: Text("Select a song from the library to edit it.")
                    )
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Song.self, Tacet.self, SetlistEntry.self, Setlist.self],
                        inMemory: true)
}
```

- [ ] **Step 2: Commit**

```bash
git add Leadify/ContentView.swift
git commit -m "feat: add SidebarMode and dual-selection state to ContentView"
```

---

## Task 3: Build SongLibrarySidebarView

**Files:**
- Create: `Leadify/Views/Sidebar/SongLibrarySidebarView.swift`

> **After creating this file:** Right-click the `Sidebar` group in Xcode's file navigator → **Add Files to "Leadify"** → select `SongLibrarySidebarView.swift`. Then **Cmd+Shift+K** → **Cmd+B**.

- [ ] **Step 1: Create `Leadify/Views/Sidebar/SongLibrarySidebarView.swift`**

```swift
import SwiftUI
import SwiftData

enum SongSortOrder {
    case alphabetical
    case dateAdded
}

struct SongLibrarySidebarView: View {
    @Query private var allSongs: [Song]
    @Binding var selectedSong: Song?
    @Environment(\.modelContext) private var context

    @State private var sortOrder: SongSortOrder = .alphabetical
    @State private var songToDelete: Song?
    @State private var showDeleteConfirmation = false

    var sortedSongs: [Song] {
        switch sortOrder {
        case .alphabetical:
            return allSongs.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        case .dateAdded:
            return allSongs.sorted { $0.createdAt > $1.createdAt }
        }
    }

    var body: some View {
        List(selection: $selectedSong) {
            ForEach(sortedSongs) { song in
                SongLibraryRow(song: song)
                    .tag(song)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            songToDelete = song
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Songs")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort", selection: $sortOrder) {
                        Text("A → Z").tag(SongSortOrder.alphabetical)
                        Text("Date Added").tag(SongSortOrder.dateAdded)
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
        .alert("Delete Song", isPresented: $showDeleteConfirmation, presenting: songToDelete) { song in
            Button("Delete \"\(song.title)\"", role: .destructive) {
                if selectedSong == song { selectedSong = nil }
                context.delete(song)
            }
            Button("Cancel", role: .cancel) {}
        } message: { song in
            Text("This will remove \"\(song.title)\" from all setlists. This cannot be undone.")
        }
    }
}

private struct SongLibraryRow: View {
    let song: Song

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(song.title)
                .font(.system(size: EditTheme.songTitleSize))
                .foregroundStyle(EditTheme.primaryText)
            Text(song.createdAt, style: .date)
                .font(.system(size: EditTheme.songPreviewSize))
                .foregroundStyle(EditTheme.secondaryText)
        }
        .padding(.vertical, 2)
    }
}
```

- [ ] **Step 2: Build to verify no errors in the new file**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=2EB88329-DA02-4D84-ABFD-8E49B53AF6B8' \
  2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Expected: BUILD FAILED only due to missing `SongEditorDetailView` — no errors in `SongLibrarySidebarView.swift` itself. If there are errors in `SongLibrarySidebarView.swift`, fix them before continuing.

- [ ] **Step 3: Commit**

```bash
git add Leadify/Views/Sidebar/SongLibrarySidebarView.swift
git commit -m "feat: add SongLibrarySidebarView with sort and swipe-to-delete"
```

---

## Task 4: Build SongEditorDetailView

**Files:**
- Create: `Leadify/Views/Setlist/SongEditorDetailView.swift`

> **After creating this file:** Right-click the `Setlist` group in Xcode's file navigator → **Add Files to "Leadify"** → select `SongEditorDetailView.swift`. Then **Cmd+Shift+K** → **Cmd+B**.

`SongContentPreview` (the MarkdownUI renderer) is already defined in `SongEditorSheet.swift` as a non-private struct — it's reusable directly.

- [ ] **Step 1: Create `Leadify/Views/Setlist/SongEditorDetailView.swift`**

```swift
import SwiftUI
import SwiftData
import MarkdownUI

struct SongEditorDetailView: View {
    @Bindable var song: Song
    @Binding var selectedSong: Song?
    @Environment(\.modelContext) private var context

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left: Editor
            VStack(alignment: .leading, spacing: 12) {
                TextField("Title", text: $song.title)
                    .font(.system(size: 24, weight: .bold))
                    .textFieldStyle(.plain)

                TextField("Reminder (optional)", text: Binding(
                    get: { song.reminder ?? "" },
                    set: { song.reminder = $0.isEmpty ? nil : $0 }
                ))
                .font(.system(size: EditTheme.reminderSize + 3))
                .foregroundStyle(EditTheme.reminderColor)
                .textFieldStyle(.plain)

                Divider()

                TextEditor(text: $song.content)
                    .font(.system(size: 15, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // MARK: - Right: Live preview
            ScrollView {
                SongContentPreview(content: song.content)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PerformanceTheme.background)
        }
        .navigationTitle(song.title.isEmpty ? "Untitled" : song.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(EditTheme.destructiveColor)
                }
            }
        }
        .alert("Delete Song", isPresented: $showDeleteConfirmation) {
            Button("Delete \"\(song.title)\"", role: .destructive) {
                selectedSong = nil
                context.delete(song)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove \"\(song.title)\" from all setlists. This cannot be undone.")
        }
    }
}
```

- [ ] **Step 2: Build to verify the project compiles cleanly**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=2EB88329-DA02-4D84-ABFD-8E49B53AF6B8' \
  2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Run all tests**

```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=2EB88329-DA02-4D84-ABFD-8E49B53AF6B8' \
  2>&1 | grep -E "(FAIL|PASS|Test Suite)"
```

Expected: All tests pass (12 total: 10 existing + 2 new from Task 1).

- [ ] **Step 4: Commit**

```bash
git add Leadify/Views/Setlist/SongEditorDetailView.swift
git commit -m "feat: add SongEditorDetailView with side-by-side editor and live preview"
```

---

## Pause for simulator review

Launch on the iPad Pro 13-inch simulator (`2EB88329-DA02-4D84-ABFD-8E49B53AF6B8`) and verify:

- [ ] Segmented control ("Setlists" / "Songs") appears in the sidebar toolbar
- [ ] Switching to "Songs" shows the song library list
- [ ] Sort menu (↑↓ icon) switches between A→Z and Date Added correctly
- [ ] Tapping a song opens the side-by-side editor in the detail pane
- [ ] Left pane: title, reminder, and markdown source are editable
- [ ] Right pane: rendered preview updates live as you type
- [ ] Swipe left on a song row shows a red Delete button and confirmation alert
- [ ] Delete from swipe: song is removed; if it was selected, detail pane shows "No Song Selected"
- [ ] Delete from toolbar (trash icon): confirmation alert, then song removed, detail pane resets
- [ ] Switching back to "Setlists" restores the previously selected setlist
- [ ] All existing setlist functionality (ordering, performance mode, etc.) works unchanged
