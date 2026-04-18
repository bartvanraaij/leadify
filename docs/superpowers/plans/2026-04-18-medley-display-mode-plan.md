# Medley Display Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a per-medley `displayMode` setting (separated/combined) that controls how medleys render and navigate in Performance mode.

**Architecture:** New `MedleyDisplayMode` enum on the `Medley` model. `Setlist.performanceItems` branches on the mode to emit either one `.medley` item (combined) or N `.song` items with a `medleyTitle` marker (separated). Views read the `medleyTitle` to show a header. No navigation logic changes needed.

**Tech Stack:** Swift, SwiftUI, SwiftData

---

### Task 1: Add `MedleyDisplayMode` enum and property to Medley model

**Files:**
- Modify: `Leadify/Models/Medley.swift`

- [ ] **Step 1: Add the enum and property**

Add the enum above the `@Model` class and the property inside it:

```swift
enum MedleyDisplayMode: String, Codable, CaseIterable {
    case separated
    case combined
}
```

Add to `Medley`:

```swift
var displayMode: MedleyDisplayMode = .separated
```

- [ ] **Step 2: Build to verify**

Run:
```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Leadify/Models/Medley.swift
git commit -m "feat: add displayMode property to Medley model"
```

---

### Task 2: Add `medleyTitle` to `PerformanceItem` and update `Setlist.performanceItems`

**Files:**
- Modify: `Leadify/Models/Performable.swift`

- [ ] **Step 1: Add `medleyTitle` field to `PerformanceItem`**

Add after the `medley` property:

```swift
let medleyTitle: String?
```

- [ ] **Step 2: Add `medleyTitle: nil` to all existing `PerformanceItem` initialisers**

There are four call sites in `Performable.swift` — the three in `Setlist.performanceItems` (song, tacet, medley cases) and the one in `SongCollection.performanceItems`, and the one in `Medley.performanceItems`. Add `medleyTitle: nil` to each.

- [ ] **Step 3: Update the `.medley` case in `Setlist.performanceItems` to branch on `displayMode`**

Replace the `.medley` case with:

```swift
case .medley:
    if let medley = entry.medley {
        switch medley.displayMode {
        case .separated:
            return medley.sortedEntries.enumerated().map { index, medleyEntry in
                PerformanceItem(
                    id: medleyEntry.persistentModelID.stableHash,
                    title: medleyEntry.song.title,
                    kind: .song,
                    song: medleyEntry.song,
                    tacet: nil,
                    medley: nil,
                    medleyTitle: index == 0 ? medley.name : nil
                )
            }
        case .combined:
            return [PerformanceItem(
                id: entry.persistentModelID.stableHash,
                title: medley.name,
                kind: .medley,
                song: nil,
                tacet: nil,
                medley: medley,
                medleyTitle: nil
            )]
        }
    }
    return []
```

Since `.separated` can emit multiple items, change `sortedEntries.map` to `sortedEntries.flatMap` — the closure now returns `[PerformanceItem]` for each entry:

```swift
var performanceItems: [PerformanceItem] {
    sortedEntries.flatMap { entry -> [PerformanceItem] in
        switch entry.itemType {
        case .song:
            return [PerformanceItem(
                id: entry.persistentModelID.stableHash,
                title: entry.song?.title ?? "Untitled",
                kind: .song,
                song: entry.song,
                tacet: nil,
                medley: nil,
                medleyTitle: nil
            )]
        case .tacet:
            return [PerformanceItem(
                id: entry.persistentModelID.stableHash,
                title: entry.tacet?.label ?? "Tacet",
                kind: .tacet,
                song: nil,
                tacet: entry.tacet,
                medley: nil,
                medleyTitle: nil
            )]
        case .medley:
            if let medley = entry.medley {
                switch medley.displayMode {
                case .separated:
                    return medley.sortedEntries.enumerated().map { index, medleyEntry in
                        PerformanceItem(
                            id: medleyEntry.persistentModelID.stableHash,
                            title: medleyEntry.song.title,
                            kind: .song,
                            song: medleyEntry.song,
                            tacet: nil,
                            medley: nil,
                            medleyTitle: index == 0 ? medley.name : nil
                        )
                    }
                case .combined:
                    return [PerformanceItem(
                        id: entry.persistentModelID.stableHash,
                        title: medley.name,
                        kind: .medley,
                        song: nil,
                        tacet: nil,
                        medley: medley,
                        medleyTitle: nil
                    )]
                }
            }
            return []
        }
    }
}
```

- [ ] **Step 4: Build to verify**

Run:
```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add Leadify/Models/Performable.swift
git commit -m "feat: emit separated song items for medleys with separated displayMode"
```

---

### Task 3: Write unit tests for `performanceItems` with both display modes

**Files:**
- Modify: `Tests/UnitTests/SetlistTests.swift`

- [ ] **Step 1: Add test for separated medley**

```swift
// MARK: - Medley display mode

func test_performanceItems_separatedMedley_emitsSongItems() throws {
    let s1 = Song(title: "Song A")
    let s2 = Song(title: "Song B")
    [s1, s2].forEach { context.insert($0) }

    let medley = Medley(name: "Rock Set")
    medley.displayMode = .separated
    context.insert(medley)
    let me1 = MedleyEntry(song: s1)
    let me2 = MedleyEntry(song: s2)
    [me1, me2].forEach { context.insert($0) }
    medley.addEntry(me1)
    medley.addEntry(me2)

    let setlist = Setlist(name: "Gig")
    context.insert(setlist)
    let entry = SetlistEntry(medley: medley)
    context.insert(entry)
    setlist.addEntry(entry)
    try context.save()

    let items = setlist.performanceItems
    XCTAssertEqual(items.count, 2)
    XCTAssertEqual(items[0].kind, .song)
    XCTAssertEqual(items[0].title, "Song A")
    XCTAssertEqual(items[0].medleyTitle, "Rock Set")
    XCTAssertEqual(items[1].kind, .song)
    XCTAssertEqual(items[1].title, "Song B")
    XCTAssertNil(items[1].medleyTitle)
}
```

- [ ] **Step 2: Add test for combined medley**

```swift
func test_performanceItems_combinedMedley_emitsSingleMedleyItem() throws {
    let s1 = Song(title: "Song A")
    let s2 = Song(title: "Song B")
    [s1, s2].forEach { context.insert($0) }

    let medley = Medley(name: "Rock Set")
    medley.displayMode = .combined
    context.insert(medley)
    let me1 = MedleyEntry(song: s1)
    let me2 = MedleyEntry(song: s2)
    [me1, me2].forEach { context.insert($0) }
    medley.addEntry(me1)
    medley.addEntry(me2)

    let setlist = Setlist(name: "Gig")
    context.insert(setlist)
    let entry = SetlistEntry(medley: medley)
    context.insert(entry)
    setlist.addEntry(entry)
    try context.save()

    let items = setlist.performanceItems
    XCTAssertEqual(items.count, 1)
    XCTAssertEqual(items[0].kind, .medley)
    XCTAssertEqual(items[0].title, "Rock Set")
    XCTAssertNil(items[0].medleyTitle)
}
```

- [ ] **Step 3: Add test for mixed setlist with separated medley**

```swift
func test_performanceItems_separatedMedleyInMixedSetlist() throws {
    let song = Song(title: "Standalone")
    let s1 = Song(title: "Medley A")
    let s2 = Song(title: "Medley B")
    [song, s1, s2].forEach { context.insert($0) }

    let medley = Medley(name: "Rock Set")
    medley.displayMode = .separated
    context.insert(medley)
    let me1 = MedleyEntry(song: s1)
    let me2 = MedleyEntry(song: s2)
    [me1, me2].forEach { context.insert($0) }
    medley.addEntry(me1)
    medley.addEntry(me2)

    let setlist = Setlist(name: "Gig")
    context.insert(setlist)
    let songEntry = SetlistEntry(song: song)
    context.insert(songEntry)
    setlist.addEntry(songEntry)
    let medleyEntry = SetlistEntry(medley: medley)
    context.insert(medleyEntry)
    setlist.addEntry(medleyEntry)
    try context.save()

    let items = setlist.performanceItems
    XCTAssertEqual(items.count, 3)
    XCTAssertEqual(items[0].title, "Standalone")
    XCTAssertNil(items[0].medleyTitle)
    XCTAssertEqual(items[1].title, "Medley A")
    XCTAssertEqual(items[1].medleyTitle, "Rock Set")
    XCTAssertEqual(items[2].title, "Medley B")
    XCTAssertNil(items[2].medleyTitle)
}
```

- [ ] **Step 4: Run tests**

Run:
```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' \
  -only-testing:LeadifyTests
```
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add Tests/UnitTests/SetlistTests.swift
git commit -m "test: add unit tests for medley display mode in performanceItems"
```

---

### Task 4: Show medley title header in `SongPerformanceBlock`

**Files:**
- Modify: `Leadify/Views/Performance/SongPerformanceBlock.swift`
- Modify: `Leadify/Views/Performance/PerformanceView.swift`

- [ ] **Step 1: Add `medleyTitle` parameter to `SongPerformanceBlock`**

```swift
struct SongPerformanceBlock: View {
    let song: Song
    var medleyTitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let medleyTitle {
                Text(medleyTitle)
                    .font(.system(size: PerformanceTheme.medleyTitleSize, weight: .semibold))
                    .foregroundStyle(PerformanceTheme.medleyIndicatorColor)
                    .padding(.top, PerformanceTheme.itemInnerVerticalPadding)
                    .padding(.bottom, PerformanceTheme.medleyTitleBottomPadding)
            }

            SongPerformanceContent(song: song)
                .padding(
                    .bottom,
                    (PerformanceTheme.itemInnerVerticalPadding
                        + PerformanceTheme.chordTextSize
                        - PerformanceTheme.chordRowHeight)
                )

            Rectangle().fill(PerformanceTheme.dividerColor).frame(height: 1)
        }
    }
}
```

- [ ] **Step 2: Pass `medleyTitle` in `PerformanceView.itemView()`**

Update the `.song` case:

```swift
case .song:
    if let song = item.song {
        SongPerformanceBlock(song: song, medleyTitle: item.medleyTitle)
    }
```

- [ ] **Step 3: Build to verify**

Run:
```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add Leadify/Views/Performance/SongPerformanceBlock.swift Leadify/Views/Performance/PerformanceView.swift
git commit -m "feat: show medley title header above first separated song in performance view"
```

---

### Task 5: Add dividers between songs in `MedleyPerformanceBlock` (combined mode)

**Files:**
- Modify: `Leadify/Views/Performance/SongPerformanceBlock.swift`

- [ ] **Step 1: Add divider between songs in the ForEach**

Update the `ForEach` in `MedleyPerformanceBlock` to insert a divider before every song except the first:

```swift
ForEach(
    Array(medley.sortedEntries.enumerated()),
    id: \.element.persistentModelID
) { index, entry in
    if index > 0 {
        Rectangle()
            .fill(PerformanceTheme.dividerColor)
            .frame(height: PerformanceTheme.dividerHeight)
    }

    SongPerformanceContent(
        song: entry.song,
        titleTopPadding: PerformanceTheme.medleyInnerSongTitleTopPadding,
        titleBottomPadding: 0
    )
}
```

- [ ] **Step 2: Build to verify**

Run:
```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Leadify/Views/Performance/SongPerformanceBlock.swift
git commit -m "feat: add dividers between songs in combined medley block"
```

---

### Task 6: Update `PerformanceSetlistSidebar` for separated medley songs

**Files:**
- Modify: `Leadify/Views/Performance/PerformanceSetlistSidebar.swift`

- [ ] **Step 1: Add medley label above the first separated song in the sidebar**

The sidebar iterates `items` (the flat `[PerformanceItem]` list). For separated medley songs, `item.medleyTitle` is non-nil only for the first song. Add the label in the `.song` case, before the button:

```swift
case .song:
    VStack(alignment: .leading, spacing: 0) {
        if let medleyTitle = item.medleyTitle {
            Text(medleyTitle)
                .font(.system(size: PerformanceTheme.sidebarMedleySongSize))
                .foregroundStyle(PerformanceTheme.medleyIndicatorColor)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, PerformanceTheme.sidebarRowHorizontalPadding)
                .padding(.bottom, PerformanceTheme.sidebarTightSpacing)
        }

        Button {
            onSelect(index)
        } label: {
            Text(item.title)
                .font(.system(size: PerformanceTheme.sidebarSongSize))
                .foregroundStyle(PerformanceTheme.sidebarTextColor)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PerformanceTheme.sidebarRowHorizontalPadding)
                .padding(.vertical, PerformanceTheme.sidebarRowVerticalPadding)
                .background(
                    RoundedRectangle(cornerRadius: PerformanceTheme.sidebarRowCornerRadius, style: .continuous)
                        .fill(
                            isActive
                                ? PerformanceTheme.sidebarActiveColor
                                : .clear
                        )
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
```

- [ ] **Step 2: Build to verify**

Run:
```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Leadify/Views/Performance/PerformanceSetlistSidebar.swift
git commit -m "feat: show medley label above first separated song in performance sidebar"
```

---

### Task 7: Add display mode picker to `MedleyEditSheet`

**Files:**
- Modify: `Leadify/Views/Medley/MedleyEditSheet.swift`

- [ ] **Step 1: Add state variable and picker**

Add a state variable:

```swift
@State private var displayMode: MedleyDisplayMode = .separated
```

Add a new section in the Form, after the "Name" section:

```swift
Section("Performance display") {
    Picker("Display as", selection: $displayMode) {
        ForEach(MedleyDisplayMode.allCases, id: \.self) { mode in
            Text(mode.label).tag(mode)
        }
    }
    .pickerStyle(.inline)
    .listRowSeparator(.hidden)

    Text(displayMode.explanation)
        .font(.footnote)
        .foregroundStyle(.secondary)
}
```

- [ ] **Step 2: Add `label` and `explanation` computed properties to `MedleyDisplayMode`**

Add to `Leadify/Models/Medley.swift`:

```swift
extension MedleyDisplayMode {
    var label: String {
        switch self {
        case .separated: "Separated"
        case .combined: "Combined"
        }
    }

    var explanation: String {
        switch self {
        case .separated: "Each song is displayed and navigated individually"
        case .combined: "Displayed and navigated as one item"
        }
    }
}
```

- [ ] **Step 3: Load existing value in `loadExistingValues()`**

```swift
private func loadExistingValues() {
    guard let medley else { return }
    name = medley.name
    displayMode = medley.displayMode
}
```

- [ ] **Step 4: Save the value in `save()`**

Update `save()` to write displayMode for both new and existing medleys:

```swift
private func save() {
    let trimmed = name.trimmingCharacters(in: .whitespaces)
    if let medley {
        medley.name = trimmed
        medley.displayMode = displayMode
    } else {
        let newMedley = Medley(name: trimmed)
        newMedley.displayMode = displayMode
        context.insert(newMedley)
    }
    dismiss()
}
```

- [ ] **Step 5: Build to verify**

Run:
```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add Leadify/Views/Medley/MedleyEditSheet.swift Leadify/Models/Medley.swift
git commit -m "feat: add display mode picker to medley edit sheet"
```

---

### Task 8: Update test seeder and run full build + test

**Files:**
- Modify: `Leadify/UITestSeeder.swift` (if medleys need explicit displayMode for test scenarios)

- [ ] **Step 1: Verify existing seeder still works**

The existing seeder creates medleys without setting `displayMode`. Since the default is `.separated`, these medleys will now render as separate songs in performance mode. This is the desired behavior — no seeder changes needed unless you want to demonstrate both modes.

Optionally, set one medley to `.combined` to test both modes:

In `UITestSeeder.swift`, after creating "Evening Set" medley, add:

```swift
eveningSet.displayMode = .combined
```

This way the seeder demonstrates both modes: "Folk Trio" (separated, default) and "Evening Set" (combined).

- [ ] **Step 2: Run all unit tests**

Run:
```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' \
  -only-testing:LeadifyTests
```
Expected: All tests pass

- [ ] **Step 3: Build, install, and launch on simulator for manual testing**

Run:
```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```

Then:
```bash
xcrun simctl terminate B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5 dev.bartvanraaij.leadify 2>/dev/null
xcrun simctl install B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5 \
  ~/Library/Developer/Xcode/DerivedData/Leadify-dcfskxmsfskcybdoxvrgstsbknvm/Build/Products/Debug-iphonesimulator/Leadify.app
xcrun simctl launch B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5 dev.bartvanraaij.leadify
```

Manual checks:
- Open a setlist with a medley in Performance mode — separated songs should each appear as individual items
- Sidebar shows medley label above first song, remaining songs are regular rows
- Navigation (next/prev) treats each song individually
- Edit a medley, switch to Combined — performance mode shows the old single-block view with dividers between songs
- Create a new medley — default should be Separated

- [ ] **Step 4: Commit if seeder was changed**

```bash
git add Leadify/UITestSeeder.swift
git commit -m "chore: set Evening Set medley to combined mode in test seeder"
```
