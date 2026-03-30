# Markdown Song Import — Design Spec

## Goal

Allow users to import `.md` files (with YAML frontmatter) as songs into Leadify. Two entry points: "Open with Leadify" from the Files app, and an import button inside the app's Song Library sidebar.

## Code quality principle

Prefer simple, readable code throughout. Avoid over-abstraction, unnecessary generics, or clever patterns. Each piece should be easy to read and understand at a glance.

## Markdown format

```markdown
---
title: Song Title
reminder: optional reminder text
---
## Section
Chords and lyrics here...
```

- Frontmatter is delimited by `---` on its own line (first and second occurrence).
- `title` is required. `reminder` is optional.
- Everything after the closing `---` is the song body (stored as-is in `Song.content`).
- Body may contain headings, code fences (tablature), and any other markdown.

## Components

### 1. `MarkdownSongParser` (new file: `Leadify/Models/MarkdownSongParser.swift`)

A simple struct with a single static method:

```swift
struct MarkdownSongParser {
    struct ParsedSong {
        let title: String
        let reminder: String?
        let content: String
    }

    enum ParseError: LocalizedError {
        case noFrontmatter
        case missingTitle
    }

    static func parse(_ text: String) throws -> ParsedSong
}
```

**Parsing logic:**
1. Find the first line that is exactly `---` (trimmed). This starts the frontmatter.
2. Find the next `---` line. Everything between is frontmatter.
3. Parse frontmatter line-by-line: split each line on the first `:` to get key-value pairs. Trim whitespace from both key and value.
4. Extract `title` (required — throw `missingTitle` if absent) and `reminder` (optional).
5. Everything after the closing `---` is the body. Trim leading/trailing whitespace.
6. Return `ParsedSong`.

No external YAML library needed — the frontmatter is just simple `key: value` lines.

### 2. `SongImporter` (new file: `Leadify/Models/SongImporter.swift`)

An `@Observable` class that manages the import flow including duplicate detection.

```swift
@Observable
class SongImporter {
    var conflictSong: ParsedSong?     // non-nil when showing the conflict dialog
    var existingSong: Song?           // the song that conflicts
    var showConflictDialog = false
    var showErrorAlert = false
    var errorMessage = ""

    func importFile(url: URL, context: ModelContext)
    func resolveConflict(_ resolution: ConflictResolution, context: ModelContext)
}

enum ConflictResolution {
    case overwrite
    case skip
    case keepBoth
}
```

**Import flow:**
1. Read file contents from URL (using `url.startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()` for sandboxed access).
2. Call `MarkdownSongParser.parse(_:)`.
3. Query `ModelContext` for existing song with same title (case-insensitive).
4. If no duplicate: create new `Song` and insert.
5. If duplicate found: set `conflictSong`, `existingSong`, and `showConflictDialog = true`. Wait for user resolution.

**Conflict resolution:**
- **Overwrite**: Update `existingSong.content` and `existingSong.reminder` with the imported values.
- **Skip**: Do nothing.
- **Keep Both**: Create new `Song` with title suffixed ` (2)`. If ` (2)` also exists, try ` (3)`, etc.

### 3. App registration for `.md` files

In `Info.plist` (via Xcode target settings), add:

- **`CFBundleDocumentTypes`**: Declare that the app can open files with UTType `net.daringfireball.markdown` (the standard markdown UTType) and/or `public.plain-text`.
- **`LSItemContentTypes`**: `["net.daringfireball.markdown"]`
- Set role to "Viewer" (we import but don't edit the file in place).

Alternatively, handle this via the `UTType` extension approach if the project uses `Exported/Imported Type Identifiers`.

### 4. Integration in `LeadifyApp.swift`

Add `.onOpenURL` to the `WindowGroup`:

```swift
WindowGroup {
    ContentView()
        .environment(songImporter)
}
.modelContainer(container)
.onOpenURL { url in
    // Trigger import flow
}
```

The `SongImporter` instance lives as `@State` in `LeadifyApp` and is passed via `.environment()` so both the app-level `onOpenURL` and the sidebar import button can use the same importer.

### 5. Integration in `SongLibrarySidebarView.swift`

Add an import button to the toolbar (alongside the existing `+` button):

```swift
ToolbarItem(placement: .topBarTrailing) {
    Button {
        showFileImporter = true
    } label: {
        Image(systemName: "square.and.arrow.down")
    }
}
```

Attach `.fileImporter(isPresented:allowedContentTypes:onCompletion:)` to the view. On completion, call `songImporter.importFile(url:context:)`.

### 6. Conflict dialog

A `.confirmationDialog` presented when `songImporter.showConflictDialog` is true:

```
"Song Already Exists"
"A song titled '{title}' already exists."

[Overwrite]  — replaces content and reminder
[Keep Both]  — imports with a suffix
[Skip]       — cancels the import
```

This dialog can live on `ContentView` (since it needs to be visible regardless of which sidebar mode is active — the import can come from Files app via `onOpenURL`).

## Files to create

| File | Purpose |
|------|---------|
| `Leadify/Models/MarkdownSongParser.swift` | Parse frontmatter + body |
| `Leadify/Models/SongImporter.swift` | Import flow + duplicate detection |

## Files to modify

| File | Change |
|------|--------|
| `Leadify/LeadifyApp.swift` | Add `SongImporter` state, `.environment()`, `.onOpenURL` |
| `Leadify/ContentView.swift` | Add conflict dialog, receive `SongImporter` from environment |
| `Leadify/Views/Sidebar/SongLibrarySidebarView.swift` | Add import button + `.fileImporter` |
| `Leadify/Info.plist` (or target settings) | `CFBundleDocumentTypes` for markdown |

## Testing

- Unit tests for `MarkdownSongParser`: valid input, missing frontmatter, missing title, code fences in body, special characters in title.
- Unit tests for `SongImporter`: new song, duplicate with each resolution.

## Out of scope

- Export / sharing songs as markdown
- Batch import of multiple files
- Changes to setlist system
- CloudKit sync
