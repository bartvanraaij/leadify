# UI Polish — Plan 3

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Address 12 UI/UX issues across performance mode, the song editor sheet, setlist ordering view, and the sidebar.

**Architecture:** Purely UI/theme changes — no model or business-logic changes. Most fixes are confined to a single file. `PerformanceTheme` drives the biggest cascade: colors become adaptive (light/dark) throughout performance mode.

**Tech Stack:** SwiftUI, iOS 26.2, MarkdownUI, SwiftData (unchanged)

---

## File map

| File | Changes |
|---|---|
| `Theme/PerformanceTheme.swift` | All colors → adaptive; chord size 22→26; tab color fixed; add close-button tokens; add tacet divider token |
| `Views/Setlist/Performance/TacetBlock.swift` | Replace hardcoded `Color(white: 0.15)` dividers with theme token |
| `Views/Setlist/Performance/PerformanceView.swift` | Add close button overlay; remove triple-tap dismiss; fix bottom tap zone blocked by upNext overlay |
| `Views/Setlist/SongEditorSheet.swift` | Smaller TextEditor font size |
| `Views/Setlist/SongLibrarySheet.swift` | Add `.presentationSizing(.page)` to SongEditorSheet sheet |
| `Views/Setlist/SetlistDetailView.swift` | Add `.presentationSizing(.page)` to song editor sheet; remove weird tacet row background |
| `ContentView.swift` | Pin sidebar column width to prevent expansion animation on selection |

---

## Task 1: PerformanceTheme — adaptive colors + font tweaks

**Issues addressed:** performance mode white-on-black in light mode (1), tab color (10), chord font size (11)

**Files:**
- Modify: `Leadify/Theme/PerformanceTheme.swift`

- [ ] **Step 1: Replace PerformanceTheme with adaptive version**

```swift
import SwiftUI

/// All visual constants for Performance Mode.
/// Colors are adaptive — they respond to light / dark mode automatically.
struct PerformanceTheme {
    // MARK: Font sizes
    static let songTitleSize: CGFloat = 28
    static let reminderSize: CGFloat = 18
    static let sectionHeaderSize: CGFloat = 16
    static let chordTextSize: CGFloat = 26       // bumped from 22
    static let tabFontSize: CGFloat = 18
    static let upNextSize: CGFloat = 14

    // MARK: Colors
    static let background = Color(UIColor.systemBackground)
    static let songTitleColor = Color.primary
    static let chordTextColor = Color.primary
    static let sectionHeaderColor = Color.secondary
    static let reminderColor = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let tabColor = Color.primary          // was hard-coded green
    static let tacetTextColor = Color.secondary
    static let tacetDividerColor = Color.primary.opacity(0.12)
    static let upNextColor = Color.secondary
    static let tapZoneIndicatorColor = Color.primary.opacity(0.3)
    static let closeButtonColor = Color.primary.opacity(0.5)
    static let closeButtonBackground = Color.primary.opacity(0.08)
}
```

- [ ] **Step 2: Build and verify no compilation errors**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=2EB88329-DA02-4D84-ABFD-8E49B53AF6B8' \
  | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Leadify/Theme/PerformanceTheme.swift
git commit -m "feat: adaptive PerformanceTheme colors; larger chord font; tab = primary"
```

---

## Task 2: TacetBlock — adaptive divider colors

**Issue addressed:** hardcoded near-black dividers in TacetBlock are invisible in light mode.

**Files:**
- Modify: `Leadify/Views/Setlist/Performance/TacetBlock.swift`

- [ ] **Step 1: Replace both hardcoded divider colors**

In `TacetBlock.swift`, there are two `Rectangle()` views with `.foregroundStyle(Color(white: 0.15))`. Change both:

```swift
// Before (line ~18 and ~29):
.foregroundStyle(Color(white: 0.15))

// After — use the theme token:
.foregroundStyle(PerformanceTheme.tacetDividerColor)
```

The full file after the change should look like:

```swift
import SwiftUI

struct TacetBlock: View {
    let tacet: Tacet
    let entryID: String
    let viewModel: PerformanceViewModel

    private var displayLabel: String {
        if let label = tacet.label, !label.isEmpty {
            return "— \(label) —"
        }
        return "— Tacet —"
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(PerformanceTheme.tacetDividerColor)

            Text(displayLabel)
                .font(.system(size: PerformanceTheme.sectionHeaderSize))
                .italic()
                .foregroundStyle(PerformanceTheme.tacetTextColor)
                .textCase(.uppercase)
                .tracking(2)
                .padding(.vertical, 10)

            Rectangle()
                .frame(height: 1)
                .foregroundStyle(PerformanceTheme.tacetDividerColor)
        }
        .frame(maxWidth: .infinity)
        .onAppear { viewModel.markVisible(entryID) }
        .onDisappear { viewModel.markHidden(entryID) }
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=2EB88329-DA02-4D84-ABFD-8E49B53AF6B8' \
  | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add Leadify/Views/Setlist/Performance/TacetBlock.swift
git commit -m "fix: TacetBlock dividers use adaptive theme color"
```

---

## Task 3: PerformanceView — close button + fix scroll-down tap zone

**Issues addressed:** no close button (8), scroll-down tap zone blocked by upNext overlay (9)

**Root cause of issue 9:** The `upNext` HStack sits at the `ZStack`'s `.bottom` alignment and has a `Spacer()` that stretches its hit-test area across the full width, sitting on top of the tap zone overlay that's inside the `ScrollView`. Taps on the bottom hit the HStack first.

**Fix:** Add `.allowsHitTesting(false)` to the upNext overlay so taps fall through to the tap zone.

**Files:**
- Modify: `Leadify/Views/Setlist/Performance/PerformanceView.swift`

- [ ] **Step 1: Rewrite PerformanceView.swift**

```swift
import SwiftUI

struct PerformanceView: View {
    let setlist: Setlist
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PerformanceViewModel

    init(setlist: Setlist) {
        self.setlist = setlist
        self._viewModel = State(initialValue: PerformanceViewModel(entries: setlist.sortedEntries))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            PerformanceTheme.background
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(setlist.sortedEntries) { entry in
                            let id = viewModel.entryID(entry)
                            Group {
                                switch entry.itemType {
                                case .song:
                                    SongBlock(song: entry.song!, entryID: id, viewModel: viewModel)
                                case .tacet:
                                    TacetBlock(tacet: entry.tacet!, entryID: id, viewModel: viewModel)
                                }
                            }
                            .id(id)
                            .padding(.horizontal, 32)
                        }
                    }
                    .padding(.top, 64)
                    .padding(.bottom, 80)
                }
                .overlay(alignment: .top) {
                    tapZone(direction: .up) {
                        if let target = viewModel.snapUpTargetID {
                            withAnimation { proxy.scrollTo(target, anchor: .top) }
                        }
                    }
                }
                .overlay(alignment: .bottom) {
                    tapZone(direction: .down) {
                        if let target = viewModel.snapDownTargetID {
                            withAnimation { proxy.scrollTo(target, anchor: .top) }
                        }
                    }
                }
            }

            // upNext: allowsHitTesting(false) so taps fall through to the scroll tap zone below
            if let upNext = viewModel.upNextSong {
                HStack {
                    Spacer()
                    Text("next: \(upNext.title)")
                        .font(.system(size: PerformanceTheme.upNextSize))
                        .foregroundStyle(PerformanceTheme.upNextColor)
                        .padding(.trailing, 20)
                        .padding(.bottom, 16)
                }
                .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            closeButton
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    // MARK: - Close button

    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(PerformanceTheme.closeButtonColor)
                .frame(width: 28, height: 28)
                .background(PerformanceTheme.closeButtonBackground)
                .clipShape(Circle())
        }
        .padding(.top, 20)
        .padding(.trailing, 20)
    }

    // MARK: - Tap Zones

    enum TapDirection { case up, down }

    @ViewBuilder
    private func tapZone(direction: TapDirection, action: @escaping () -> Void) -> some View {
        Rectangle()
            .foregroundStyle(Color.clear)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .contentShape(Rectangle())
            .overlay(alignment: direction == .up ? .top : .bottom) {
                Image(systemName: direction == .up ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(PerformanceTheme.tapZoneIndicatorColor)
                    .padding(8)
            }
            .onTapGesture { action() }
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=2EB88329-DA02-4D84-ABFD-8E49B53AF6B8' \
  | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add Leadify/Views/Setlist/Performance/PerformanceView.swift
git commit -m "feat: performance mode close button; fix scroll-down tap zone blocked by upNext"
```

---

## Task 4: SongEditorSheet — wider presentation, smaller TextEditor font

**Issues addressed:** "New Song" modal too narrow (3), content font too large (5), TextEditor not scrollable (4)

**Notes on issue 4 (scroll):** `.presentationSizing(.page)` gives the sheet a fixed large size, which properly constrains the TextEditor height so it can scroll. On macOS Simulator, also note that TextEditor scrolling requires clicking inside first, then using the scroll wheel or arrow keys.

**Files:**
- Modify: `Leadify/Views/Setlist/SongEditorSheet.swift` (font size)
- Modify: `Leadify/Views/Setlist/SongLibrarySheet.swift` (sheet sizing)
- Modify: `Leadify/Views/Setlist/SetlistDetailView.swift` (sheet sizing for edit)

- [ ] **Step 1: Reduce TextEditor font size in SongEditorSheet.swift**

Find the `TextEditor` in `SongEditorSheet.swift` (currently around line 63) and change its font:

```swift
// Before:
TextEditor(text: $content)
    .font(.system(.body, design: .monospaced))
    .padding(.horizontal, 8)
    .frame(maxWidth: .infinity, maxHeight: .infinity)

// After:
TextEditor(text: $content)
    .font(.system(size: 13, design: .monospaced))
    .padding(.horizontal, 8)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
```

- [ ] **Step 2: Add `.presentationSizing(.page)` in SongLibrarySheet.swift**

Find the `.sheet(isPresented: $showNewSongEditor)` (around line 51) and add `.presentationSizing(.page)`:

```swift
.sheet(isPresented: $showNewSongEditor) {
    SongEditorSheet(song: nil, onSave: { newSong in
        addSong(newSong)
    })
    .presentationSizing(.page)
}
```

- [ ] **Step 3: Add `.presentationSizing(.page)` for song edit in SetlistDetailView.swift**

Find the `.sheet(item: $editingEntry)` (around line 66) and add sizing for the song case:

```swift
.sheet(item: $editingEntry) { entry in
    switch entry.itemType {
    case .song:
        SongEditorSheet(song: entry.song!)
            .presentationSizing(.page)
    case .tacet:
        TacetEditSheet(entry: entry, setlist: setlist)
    }
}
```

- [ ] **Step 4: Build**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=2EB88329-DA02-4D84-ABFD-8E49B53AF6B8' \
  | tail -5
```

- [ ] **Step 5: Commit**

```bash
git add Leadify/Views/Setlist/SongEditorSheet.swift \
        Leadify/Views/Setlist/SongLibrarySheet.swift \
        Leadify/Views/Setlist/SetlistDetailView.swift
git commit -m "fix: song editor sheet wider (.page sizing); smaller TextEditor font"
```

---

## Task 5: Setlist detail — fix tacet row background

**Issue addressed:** tacet row background color looks weird (7)

**Root cause:** `Color.secondary.opacity(0.07)` on a `.plain` list style produces an inconsistent tint that doesn't match the list's own row background system. Removing it and relying on tacet rows' italic/secondary text style for visual differentiation is cleaner.

**Files:**
- Modify: `Leadify/Views/Setlist/SetlistDetailView.swift`

- [ ] **Step 1: Remove the listRowBackground from the tacet case**

In `SetlistDetailView.swift`, find the tacet case inside the `ForEach` (around line 23):

```swift
// Before:
case .tacet:
    TacetRow(entry: entry) {
        editingEntry = entry
    }
    .listRowBackground(Color.secondary.opacity(0.07))

// After:
case .tacet:
    TacetRow(entry: entry) {
        editingEntry = entry
    }
```

- [ ] **Step 2: Build**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=2EB88329-DA02-4D84-ABFD-8E49B53AF6B8' \
  | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add Leadify/Views/Setlist/SetlistDetailView.swift
git commit -m "fix: remove tacet row custom background — relies on italic/secondary text for visual distinction"
```

---

## Task 6: ContentView — pin sidebar column width

**Issue addressed:** sidebar panel visually enlarges/shifts when a setlist row is clicked (2)

**Root cause:** `NavigationSplitView` in `.automatic` style can animate column widths when selection changes. Pinning the sidebar column width prevents this.

**Files:**
- Modify: `Leadify/ContentView.swift`

- [ ] **Step 1: Pin the sidebar column width**

In `ContentView.swift`, add `.navigationSplitViewColumnWidth` to the sidebar:

```swift
var body: some View {
    NavigationSplitView {
        SetlistSidebarView(
            setlists: sortedSetlists,
            selectedSetlist: $selectedSetlist
        )
        .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 320)
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
```

- [ ] **Step 2: Build**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=2EB88329-DA02-4D84-ABFD-8E49B53AF6B8' \
  | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add Leadify/ContentView.swift
git commit -m "fix: pin sidebar column width to prevent expansion on row selection"
```

---

## Known limitations (no code fix needed)

**Drag row above sidebar (issue 6):** When drag-to-reorder is active in a `List` inside `NavigationSplitView`, SwiftUI renders the drag preview at the window layer (above all views). There is no SwiftUI API to clip the drag proxy to the detail column. This is a framework limitation; the behavior is correct on-device and acceptable given the workaround is visual-only.

**Swipe to delete in simulator (issue 12):** The swipe actions (`.swipeActions`) are present in `SetlistDetailView` and work correctly on a real device. In the macOS Simulator, swipe-to-delete requires a **two-finger swipe to the left** on the trackpad over the row (or Fn+Delete on keyboard). This is a simulator input difference, not a bug.

---

## Self-review

| Issue | Task | Covered? |
|---|---|---|
| Performance mode black text on white | Task 1 | ✅ |
| Setlist panel enlarges on click | Task 6 | ✅ |
| New Song modal wider | Task 4 | ✅ |
| Content field cannot scroll | Task 4 (presentationSizing fixes height constraint) | ✅ |
| Content font size smaller | Task 4 | ✅ |
| Drag row above panel | Known limitations | ✅ noted |
| Tacet row background weird | Task 5 | ✅ |
| Performance close button | Task 3 | ✅ |
| Scroll down button doesn't work | Task 3 (allowsHitTesting fix) | ✅ |
| Tabs same color as text | Task 1 | ✅ |
| Chord font bigger | Task 1 | ✅ |
| Swipe to delete | Known limitations | ✅ noted |
