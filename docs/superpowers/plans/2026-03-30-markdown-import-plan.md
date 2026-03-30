# Markdown Song Import — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Import `.md` files with YAML frontmatter as songs, via Files app ("Open with") and an in-app import button.

**Architecture:** A `MarkdownSongParser` struct handles parsing. A `SongImporter` observable class manages the import flow and duplicate detection. The importer is shared via SwiftUI environment from `LeadifyApp` down to views. Info.plist declares the app can open markdown files.

**Tech Stack:** Swift, SwiftUI, SwiftData, UniformTypeIdentifiers

**Code quality:** Prefer simple, readable code. No over-abstraction, no clever patterns. Each piece should be easy to read and understand at a glance.

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `Leadify/Models/MarkdownSongParser.swift` | Create | Parse YAML frontmatter + markdown body |
| `Leadify/Models/SongImporter.swift` | Create | Import flow, duplicate detection, conflict resolution |
| `Leadify/LeadifyApp.swift` | Modify | Add `SongImporter` state, `.environment()`, `.onOpenURL` |
| `Leadify/ContentView.swift` | Modify | Receive `SongImporter`, show conflict + error dialogs |
| `Leadify/Views/Sidebar/SongLibrarySidebarView.swift` | Modify | Add import button + `.fileImporter` |
| `LeadifyTests/MarkdownSongParserTests.swift` | Create | Parser unit tests |
| `LeadifyTests/SongImporterTests.swift` | Create | Importer unit tests |

---

### Task 1: MarkdownSongParser — tests and implementation

**Files:**
- Create: `LeadifyTests/MarkdownSongParserTests.swift`
- Create: `Leadify/Models/MarkdownSongParser.swift`

- [ ] **Step 1: Write parser tests**

Create `LeadifyTests/MarkdownSongParserTests.swift`:

```swift
import XCTest
@testable import Leadify

final class MarkdownSongParserTests: XCTestCase {

    func test_parsesBasicSong() throws {
        let input = """
        ---
        title: It's My Life
        reminder: direct op Cm
        ---
        ## Couplet
        Cm Cm Cm
        """
        let result = try MarkdownSongParser.parse(input)
        XCTAssertEqual(result.title, "It's My Life")
        XCTAssertEqual(result.reminder, "direct op Cm")
        XCTAssertTrue(result.content.contains("## Couplet"))
        XCTAssertTrue(result.content.contains("Cm Cm Cm"))
    }

    func test_parsesWithoutReminder() throws {
        let input = """
        ---
        title: Du
        ---
        ## Intro
        B F# B
        """
        let result = try MarkdownSongParser.parse(input)
        XCTAssertEqual(result.title, "Du")
        XCTAssertNil(result.reminder)
        XCTAssertTrue(result.content.contains("## Intro"))
    }

    func test_preservesCodeFences() throws {
        let input = """
        ---
        title: Tab Song
        ---
        ## Intro

        ```
        e|---------|
        B|--2------|
        ```
        """
        let result = try MarkdownSongParser.parse(input)
        XCTAssertTrue(result.content.contains("```"))
        XCTAssertTrue(result.content.contains("e|---------|"))
    }

    func test_throwsOnMissingFrontmatter() {
        let input = "Just some text without frontmatter"
        XCTAssertThrowsError(try MarkdownSongParser.parse(input)) { error in
            XCTAssertTrue(error is MarkdownSongParser.ParseError)
        }
    }

    func test_throwsOnMissingTitle() {
        let input = """
        ---
        reminder: some reminder
        ---
        Body text
        """
        XCTAssertThrowsError(try MarkdownSongParser.parse(input)) { error in
            XCTAssertTrue(error is MarkdownSongParser.ParseError)
        }
    }

    func test_trimsLeadingAndTrailingWhitespace() throws {
        let input = """
        ---
        title: Trimmed
        ---

        ## Section
        Content

        """
        let result = try MarkdownSongParser.parse(input)
        XCTAssertFalse(result.content.hasPrefix("\n"))
        XCTAssertFalse(result.content.hasSuffix("\n"))
    }

    func test_handlesSpecialCharactersInTitle() throws {
        let input = """
        ---
        title: Bohemian Rhapsody (Live) — 2024
        ---
        Is this the real life?
        """
        let result = try MarkdownSongParser.parse(input)
        XCTAssertEqual(result.title, "Bohemian Rhapsody (Live) — 2024")
    }

    func test_handlesColonInValue() throws {
        let input = """
        ---
        title: Song: The Remix
        reminder: key: Cm
        ---
        Body
        """
        let result = try MarkdownSongParser.parse(input)
        XCTAssertEqual(result.title, "Song: The Remix")
        XCTAssertEqual(result.reminder, "key: Cm")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' \
  -only-testing:LeadifyTests/MarkdownSongParserTests 2>&1 | tail -20
```
Expected: Build error — `MarkdownSongParser` does not exist yet.

- [ ] **Step 3: Implement MarkdownSongParser**

Create `Leadify/Models/MarkdownSongParser.swift`:

```swift
import Foundation

struct MarkdownSongParser {

    struct ParsedSong {
        let title: String
        let reminder: String?
        let content: String
    }

    enum ParseError: LocalizedError {
        case noFrontmatter
        case missingTitle

        var errorDescription: String? {
            switch self {
            case .noFrontmatter: "File does not contain valid frontmatter (expected --- delimiters)."
            case .missingTitle: "Frontmatter is missing a 'title' field."
            }
        }
    }

    static func parse(_ text: String) throws -> ParsedSong {
        let lines = text.components(separatedBy: .newlines)

        // Find the two --- delimiters
        var delimiterIndices: [Int] = []
        for (index, line) in lines.enumerated() {
            if line.trimmingCharacters(in: .whitespace) == "---" {
                delimiterIndices.append(index)
                if delimiterIndices.count == 2 { break }
            }
        }

        guard delimiterIndices.count == 2 else {
            throw ParseError.noFrontmatter
        }

        // Parse frontmatter key-value pairs
        let frontmatterLines = lines[(delimiterIndices[0] + 1)..<delimiterIndices[1]]
        var fields: [String: String] = [:]
        for line in frontmatterLines {
            guard let colonIndex = line.firstIndex(of: ":") else { continue }
            let key = line[line.startIndex..<colonIndex].trimmingCharacters(in: .whitespace)
            let value = line[line.index(after: colonIndex)...].trimmingCharacters(in: .whitespace)
            if !key.isEmpty {
                fields[key] = value
            }
        }

        guard let title = fields["title"], !title.isEmpty else {
            throw ParseError.missingTitle
        }

        // Everything after the second delimiter is the body
        let bodyLines = lines[(delimiterIndices[1] + 1)...]
        let content = bodyLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        return ParsedSong(
            title: title,
            reminder: fields["reminder"],
            content: content
        )
    }
}
```

- [ ] **Step 4: Add new files to Xcode project**

Tell user: Right-click the `Models` group in Xcode → **Add Files to "Leadify"** → select `MarkdownSongParser.swift`. Also add `MarkdownSongParserTests.swift` to the `LeadifyTests` target. Then **Cmd+Shift+K** (Clean Build).

- [ ] **Step 5: Run tests to verify they pass**

Run:
```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' \
  -only-testing:LeadifyTests/MarkdownSongParserTests 2>&1 | tail -20
```
Expected: All 8 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add Leadify/Models/MarkdownSongParser.swift LeadifyTests/MarkdownSongParserTests.swift
git commit -m "feat: add MarkdownSongParser with tests"
```

---

### Task 2: SongImporter — tests and implementation

**Files:**
- Create: `LeadifyTests/SongImporterTests.swift`
- Create: `Leadify/Models/SongImporter.swift`

- [ ] **Step 1: Write importer tests**

Create `LeadifyTests/SongImporterTests.swift`:

```swift
import XCTest
import SwiftData
@testable import Leadify

@MainActor
final class SongImporterTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var importer: SongImporter!

    override func setUp() async throws {
        container = try makeTestContainer()
        context = ModelContext(container)
        importer = SongImporter()
    }

    // MARK: - importSong (direct parsed song import, bypasses file I/O)

    func test_importNewSong_insertsSong() throws {
        let parsed = MarkdownSongParser.ParsedSong(
            title: "New Song", reminder: "Capo 2", content: "Am G C"
        )
        importer.importParsedSong(parsed, context: context)

        XCTAssertFalse(importer.showConflictDialog)
        let songs = try context.fetch(FetchDescriptor<Song>())
        XCTAssertEqual(songs.count, 1)
        XCTAssertEqual(songs[0].title, "New Song")
        XCTAssertEqual(songs[0].content, "Am G C")
        XCTAssertEqual(songs[0].reminder, "Capo 2")
    }

    func test_importDuplicateSong_showsConflictDialog() throws {
        let existing = Song(title: "Duplicate", content: "old content")
        context.insert(existing)
        try context.save()

        let parsed = MarkdownSongParser.ParsedSong(
            title: "Duplicate", reminder: nil, content: "new content"
        )
        importer.importParsedSong(parsed, context: context)

        XCTAssertTrue(importer.showConflictDialog)
        // Song should NOT be inserted yet
        let songs = try context.fetch(FetchDescriptor<Song>())
        XCTAssertEqual(songs.count, 1)
        XCTAssertEqual(songs[0].content, "old content")
    }

    func test_importDuplicateCaseInsensitive_showsConflictDialog() throws {
        let existing = Song(title: "my song", content: "old")
        context.insert(existing)
        try context.save()

        let parsed = MarkdownSongParser.ParsedSong(
            title: "My Song", reminder: nil, content: "new"
        )
        importer.importParsedSong(parsed, context: context)

        XCTAssertTrue(importer.showConflictDialog)
    }

    func test_resolveOverwrite_updatesExistingSong() throws {
        let existing = Song(title: "Overwrite Me", content: "old", reminder: "old reminder")
        context.insert(existing)
        try context.save()

        let parsed = MarkdownSongParser.ParsedSong(
            title: "Overwrite Me", reminder: "new reminder", content: "new content"
        )
        importer.importParsedSong(parsed, context: context)
        importer.resolveConflict(.overwrite, context: context)

        let songs = try context.fetch(FetchDescriptor<Song>())
        XCTAssertEqual(songs.count, 1)
        XCTAssertEqual(songs[0].content, "new content")
        XCTAssertEqual(songs[0].reminder, "new reminder")
        XCTAssertFalse(importer.showConflictDialog)
    }

    func test_resolveSkip_doesNothing() throws {
        let existing = Song(title: "Keep Me", content: "original")
        context.insert(existing)
        try context.save()

        let parsed = MarkdownSongParser.ParsedSong(
            title: "Keep Me", reminder: nil, content: "different"
        )
        importer.importParsedSong(parsed, context: context)
        importer.resolveConflict(.skip, context: context)

        let songs = try context.fetch(FetchDescriptor<Song>())
        XCTAssertEqual(songs.count, 1)
        XCTAssertEqual(songs[0].content, "original")
        XCTAssertFalse(importer.showConflictDialog)
    }

    func test_resolveKeepBoth_addsSuffixedSong() throws {
        let existing = Song(title: "Both", content: "original")
        context.insert(existing)
        try context.save()

        let parsed = MarkdownSongParser.ParsedSong(
            title: "Both", reminder: nil, content: "imported"
        )
        importer.importParsedSong(parsed, context: context)
        importer.resolveConflict(.keepBoth, context: context)

        let songs = try context.fetch(FetchDescriptor<Song>())
        XCTAssertEqual(songs.count, 2)
        let titles = songs.map(\.title).sorted()
        XCTAssertEqual(titles, ["Both", "Both (2)"])
        XCTAssertFalse(importer.showConflictDialog)
    }

    func test_resolveKeepBoth_incrementsSuffix() throws {
        context.insert(Song(title: "Song", content: ""))
        context.insert(Song(title: "Song (2)", content: ""))
        try context.save()

        let parsed = MarkdownSongParser.ParsedSong(
            title: "Song", reminder: nil, content: "new"
        )
        importer.importParsedSong(parsed, context: context)
        importer.resolveConflict(.keepBoth, context: context)

        let songs = try context.fetch(FetchDescriptor<Song>())
        XCTAssertEqual(songs.count, 3)
        let titles = songs.map(\.title)
        XCTAssertTrue(titles.contains("Song (3)"))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' \
  -only-testing:LeadifyTests/SongImporterTests 2>&1 | tail -20
```
Expected: Build error — `SongImporter` does not exist yet.

- [ ] **Step 3: Implement SongImporter**

Create `Leadify/Models/SongImporter.swift`:

```swift
import SwiftUI
import SwiftData

enum ConflictResolution {
    case overwrite
    case skip
    case keepBoth
}

@Observable
class SongImporter {
    var showConflictDialog = false
    var showErrorAlert = false
    var errorMessage = ""

    // Stored during conflict so resolveConflict can act on them
    private(set) var conflictParsedSong: MarkdownSongParser.ParsedSong?
    private(set) var conflictExistingSong: Song?

    /// Import a markdown file from a URL. Handles security-scoped access.
    func importFile(url: URL, context: ModelContext) {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            let parsed = try MarkdownSongParser.parse(text)
            importParsedSong(parsed, context: context)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    /// Import a parsed song, checking for duplicates.
    func importParsedSong(_ parsed: MarkdownSongParser.ParsedSong, context: ModelContext) {
        let existingSong = findExistingSong(title: parsed.title, context: context)

        if let existingSong {
            conflictParsedSong = parsed
            conflictExistingSong = existingSong
            showConflictDialog = true
        } else {
            let song = Song(title: parsed.title, content: parsed.content, reminder: parsed.reminder)
            context.insert(song)
        }
    }

    /// Resolve a duplicate conflict.
    func resolveConflict(_ resolution: ConflictResolution, context: ModelContext) {
        defer {
            conflictParsedSong = nil
            conflictExistingSong = nil
            showConflictDialog = false
        }

        guard let parsed = conflictParsedSong else { return }

        switch resolution {
        case .overwrite:
            if let existing = conflictExistingSong {
                existing.content = parsed.content
                existing.reminder = parsed.reminder
            }
        case .skip:
            break
        case .keepBoth:
            let uniqueTitle = findUniqueTitle(parsed.title, context: context)
            let song = Song(title: uniqueTitle, content: parsed.content, reminder: parsed.reminder)
            context.insert(song)
        }
    }

    // MARK: - Private helpers

    private func findExistingSong(title: String, context: ModelContext) -> Song? {
        let descriptor = FetchDescriptor<Song>()
        guard let songs = try? context.fetch(descriptor) else { return nil }
        return songs.first { $0.title.caseInsensitiveCompare(title) == .orderedSame }
    }

    private func findUniqueTitle(_ baseTitle: String, context: ModelContext) -> String {
        let descriptor = FetchDescriptor<Song>()
        guard let songs = try? context.fetch(descriptor) else { return "\(baseTitle) (2)" }
        let existingTitles = Set(songs.map { $0.title.lowercased() })

        var counter = 2
        while true {
            let candidate = "\(baseTitle) (\(counter))"
            if !existingTitles.contains(candidate.lowercased()) {
                return candidate
            }
            counter += 1
        }
    }
}
```

- [ ] **Step 4: Add new files to Xcode project**

Tell user: Right-click `Models` group → **Add Files to "Leadify"** → select `SongImporter.swift`. Also add `SongImporterTests.swift` to `LeadifyTests` target. **Cmd+Shift+K** (Clean Build).

- [ ] **Step 5: Run tests to verify they pass**

Run:
```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' \
  -only-testing:LeadifyTests/SongImporterTests 2>&1 | tail -20
```
Expected: All 7 tests PASS.

- [ ] **Step 6: Run all tests to confirm nothing is broken**

Run:
```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' 2>&1 | tail -20
```
Expected: All tests PASS (existing 10 + new 15).

- [ ] **Step 7: Commit**

```bash
git add Leadify/Models/SongImporter.swift LeadifyTests/SongImporterTests.swift
git commit -m "feat: add SongImporter with duplicate detection and tests"
```

---

### Task 3: Wire up the UI — LeadifyApp, ContentView, SongLibrarySidebarView

**Files:**
- Modify: `Leadify/LeadifyApp.swift`
- Modify: `Leadify/ContentView.swift`
- Modify: `Leadify/Views/Sidebar/SongLibrarySidebarView.swift`

- [ ] **Step 1: Update LeadifyApp.swift**

Replace the full body of `LeadifyApp.swift` with:

```swift
import SwiftUI
import SwiftData

@main
struct LeadifyApp: App {
    let container: ModelContainer
    @State private var songImporter = SongImporter()

    init() {
        do {
            container = try ModelContainer(for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(songImporter)
        }
        .modelContainer(container)
        .onOpenURL { url in
            songImporter.importFile(url: url, context: container.mainContext)
        }
    }
}
```

Note: `onOpenURL` is on the `WindowGroup` scene, not on `ContentView`, because it needs to be at the scene level to receive file open events.

- [ ] **Step 2: Update ContentView.swift — add conflict and error dialogs**

Add to `ContentView`:

1. An `@Environment(SongImporter.self)` property.
2. A `.confirmationDialog` for the duplicate conflict.
3. An `.alert` for import errors.

Add this property at the top of `ContentView`:
```swift
@Environment(SongImporter.self) private var songImporter
```

Add these modifiers after `.navigationSplitViewStyle(.balanced)`:
```swift
.confirmationDialog(
    "Song Already Exists",
    isPresented: Bindable(songImporter).showConflictDialog,
    titleVisibility: .visible
) {
    Button("Overwrite") {
        songImporter.resolveConflict(.overwrite, context: modelContext)
    }
    Button("Keep Both") {
        songImporter.resolveConflict(.keepBoth, context: modelContext)
    }
    Button("Skip", role: .cancel) {
        songImporter.resolveConflict(.skip, context: modelContext)
    }
} message: {
    if let title = songImporter.conflictParsedSong?.title {
        Text("A song titled \"\(title)\" already exists.")
    }
}
.alert("Import Error", isPresented: Bindable(songImporter).showErrorAlert) {
    Button("OK", role: .cancel) {}
} message: {
    Text(songImporter.errorMessage)
}
```

Also add `@Environment(\.modelContext) private var modelContext` if not already present (it is not currently in ContentView).

Update the `#Preview` to include a `SongImporter` in the environment:
```swift
#Preview {
    ContentView()
        .modelContainer(for: [Song.self, Tacet.self, SetlistEntry.self, Setlist.self],
                        inMemory: true)
        .environment(SongImporter())
}
```

- [ ] **Step 3: Update SongLibrarySidebarView.swift — add import button + file importer**

Add these properties to `SongLibrarySidebarView`:
```swift
@Environment(SongImporter.self) private var songImporter
@State private var showFileImporter = false
```

Add a second `ToolbarItem` in the `.toolbar` block, before the existing `+` button:
```swift
ToolbarItem(placement: .topBarTrailing) {
    Button {
        showFileImporter = true
    } label: {
        Image(systemName: "square.and.arrow.down")
    }
}
```

Add a `.fileImporter` modifier to the `List` (after `.listStyle(.sidebar)`):
```swift
.fileImporter(
    isPresented: $showFileImporter,
    allowedContentTypes: [.plainText],
    allowsMultipleSelection: false
) { result in
    switch result {
    case .success(let urls):
        if let url = urls.first {
            songImporter.importFile(url: url, context: context)
        }
    case .failure(let error):
        songImporter.errorMessage = error.localizedDescription
        songImporter.showErrorAlert = true
    }
}
```

Note: We use `.plainText` as content type since `.md` files conform to `public.plain-text`. If we want to be more specific, we can also add `UTType("net.daringfireball.markdown")!` but `.plainText` is simpler and works.

- [ ] **Step 4: Build and run on simulator**

Run:
```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' 2>&1 | tail -20
```
Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Run all tests**

Run:
```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' 2>&1 | tail -20
```
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add Leadify/LeadifyApp.swift Leadify/ContentView.swift Leadify/Views/Sidebar/SongLibrarySidebarView.swift
git commit -m "feat: wire up markdown import UI with file importer and conflict dialog"
```

---

### Task 4: Register the app to open `.md` files from Files app

**Files:**
- Modify: Xcode project settings / Info.plist (via `Info` tab in Xcode target settings)

- [ ] **Step 1: Add Document Type in Xcode**

This must be done in the Xcode GUI. Tell user:

> 1. Open the project in Xcode.
> 2. Select the **Leadify** target → **Info** tab.
> 3. Under **Document Types**, click **+** to add a new type:
>    - **Name:** `Markdown`
>    - **Types:** `net.daringfireball.markdown`
>    - **Role:** `Viewer`
> 4. Optionally add a second type for broader compatibility:
>    - **Name:** `Plain Text`
>    - **Types:** `public.plain-text`
>    - **Role:** `Viewer`
> 5. Build and run (**Cmd+B**).

After this, when the user long-presses a `.md` file in the Files app and taps "Share" → "Open with", Leadify will appear as an option. The `.onOpenURL` handler in `LeadifyApp` will receive the file URL.

- [ ] **Step 2: Verify on simulator**

Copy a test `.md` file to the simulator's Files app and try "Open with Leadify". Verify the song gets imported (or the conflict dialog shows if it already exists).

- [ ] **Step 3: Commit any Xcode project file changes**

```bash
git add Leadify.xcodeproj/ Leadify/Info.plist
git commit -m "feat: register app to open markdown files from Files app"
```

---

### Task 5: Manual integration test

- [ ] **Step 1: Test import via file importer**

1. Open the app on the simulator.
2. Switch to "Songs" in the sidebar.
3. Tap the import button (down-arrow icon).
4. Select a `.md` file.
5. Verify the song appears in the song list with correct title, content, and reminder.

- [ ] **Step 2: Test duplicate conflict — Overwrite**

1. Import the same `.md` file again.
2. Verify the "Song Already Exists" dialog appears.
3. Tap "Overwrite".
4. Verify the song count hasn't changed and the content is updated.

- [ ] **Step 3: Test duplicate conflict — Keep Both**

1. Import the same `.md` file again.
2. Tap "Keep Both".
3. Verify a new song appears with the title suffix " (2)".

- [ ] **Step 4: Test duplicate conflict — Skip**

1. Import the same `.md` file again.
2. Tap "Skip".
3. Verify nothing changed.

- [ ] **Step 5: Test invalid file**

1. Import a `.md` file with no frontmatter.
2. Verify an error alert appears with a clear message.
