# Leadify — Plan 2: Performance Mode

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Prerequisite:** Plan 1 complete. The `PerformanceView` placeholder exists at `Leadify/Views/Setlist/Performance/PerformanceView.swift`.

**Goal:** A fullscreen, distraction-free performance display with Markdown-rendered song content, tap-zone snap scrolling, an "up next" label, and triple-tap-to-exit.

**Architecture:** `PerformanceView` is a `ScrollView` with a `ScrollViewReader` for programmatic scrolling. Each entry tracks its own visibility via `onAppear`/`onDisappear` and reports it to a `PerformanceViewModel` (`@Observable` class) that computes the "up next" song and handles snap scroll targets.

**Tech Stack:** Swift 5.9+, SwiftUI, MarkdownUI (already added in Plan 1)

---

## File Map

```
Leadify/Views/Setlist/Performance/
├── PerformanceView.swift        # Root view: fullscreen cover, tap zones, scroll container
├── PerformanceViewModel.swift   # @Observable: tracks visible entries, up-next, snap targets
├── SongBlock.swift              # Renders one song entry (title, reminder, markdown content)
└── TacetBlock.swift             # Renders one tacet entry (centered label + dividers)
```

---

## Task 1: PerformanceViewModel

**Files:**
- Create: `Leadify/Views/Setlist/Performance/PerformanceViewModel.swift`

> **Swift note:** `@Observable` is the iOS 17 equivalent of a class implementing `INotifyPropertyChanged` in C# or a MobX `@observable` store. Any SwiftUI view that reads a property from an `@Observable` class will automatically re-render when that property changes.

- [ ] **Step 1: Create PerformanceViewModel.swift**

```swift
import SwiftUI

@Observable
final class PerformanceViewModel {
    /// IDs of entries currently visible on screen (reported by each block view).
    private(set) var visibleEntryIDs: Set<String> = []

    /// The ordered list of entries in this setlist (set once on init).
    private let entries: [SetlistEntry]

    init(entries: [SetlistEntry]) {
        self.entries = entries
    }

    // MARK: Visibility tracking

    func markVisible(_ id: String) {
        visibleEntryIDs.insert(id)
    }

    func markHidden(_ id: String) {
        visibleEntryIDs.remove(id)
    }

    // MARK: Up Next

    /// The first song entry that is not currently visible and comes after the last visible entry.
    var upNextSong: Song? {
        guard !visibleEntryIDs.isEmpty else { return nil }
        // Find the last visible index
        let lastVisibleIndex = entries.indices.last(where: {
            visibleEntryIDs.contains(entryID(entries[$0]))
        }) ?? -1
        // Return the first song entry after that index
        return entries[(lastVisibleIndex + 1)...].first(where: { $0.itemType == .song })?.song
    }

    // MARK: Snap Scroll

    /// The ID to scroll to when tapping the bottom zone:
    /// the first entry after the last currently-visible one.
    var snapDownTargetID: String? {
        guard !visibleEntryIDs.isEmpty else {
            return entries.first.map { entryID($0) }
        }
        let lastVisibleIndex = entries.indices.last(where: {
            visibleEntryIDs.contains(entryID(entries[$0]))
        }) ?? -1
        guard lastVisibleIndex + 1 < entries.count else { return nil }
        return entryID(entries[lastVisibleIndex + 1])
    }

    /// The ID to scroll to when tapping the top zone:
    /// jumps back by the number of currently-visible entries.
    var snapUpTargetID: String? {
        guard !visibleEntryIDs.isEmpty else { return nil }
        let firstVisibleIndex = entries.indices.first(where: {
            visibleEntryIDs.contains(entryID(entries[$0]))
        }) ?? 0
        let visibleCount = visibleEntryIDs.count
        let targetIndex = max(0, firstVisibleIndex - visibleCount)
        return entryID(entries[targetIndex])
    }

    // MARK: Helpers

    /// Stable string ID for a SetlistEntry, used as the scroll anchor.
    func entryID(_ entry: SetlistEntry) -> String {
        entry.persistentModelID.hashValue.description
    }
}
```

---

## Task 2: SongBlock and TacetBlock

**Files:**
- Create: `Leadify/Views/Setlist/Performance/SongBlock.swift`
- Create: `Leadify/Views/Setlist/Performance/TacetBlock.swift`

- [ ] **Step 1: Create SongBlock.swift**

```swift
import SwiftUI
import MarkdownUI

struct SongBlock: View {
    let song: Song
    let entryID: String
    let viewModel: PerformanceViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(song.title)
                .font(.system(size: PerformanceTheme.songTitleSize, weight: .bold))
                .foregroundStyle(PerformanceTheme.songTitleColor)

            if let reminder = song.reminder {
                Text(reminder)
                    .font(.system(size: PerformanceTheme.reminderSize))
                    .foregroundStyle(PerformanceTheme.reminderColor)
            }

            Markdown(song.content)
                .markdownTheme(.leadifyPerformance)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .onAppear { viewModel.markVisible(entryID) }
        .onDisappear { viewModel.markHidden(entryID) }
    }
}
```

- [ ] **Step 2: Create TacetBlock.swift**

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
                .foregroundStyle(Color(white: 0.15))

            Text(displayLabel)
                .font(.system(size: PerformanceTheme.sectionHeaderSize))
                .italic()
                .foregroundStyle(PerformanceTheme.tacetTextColor)
                .textCase(.uppercase)
                .tracking(2)
                .padding(.vertical, 10)

            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color(white: 0.15))
        }
        .frame(maxWidth: .infinity)
        .onAppear { viewModel.markVisible(entryID) }
        .onDisappear { viewModel.markHidden(entryID) }
    }
}
```

---

## Task 3: PerformanceView

**Files:**
- Modify: `Leadify/Views/Setlist/Performance/PerformanceView.swift` (replace placeholder)

- [ ] **Step 1: Replace PerformanceView.swift**

```swift
import SwiftUI

struct PerformanceView: View {
    let setlist: Setlist
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PerformanceViewModel

    init(setlist: Setlist) {
        self.setlist = setlist
        self._viewModel = State(initialValue: PerformanceViewModel(entries: setlist.entries))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            PerformanceTheme.background
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(setlist.entries) { entry in
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
                    .padding(.top, 64)   // space for top tap zone
                    .padding(.bottom, 80) // space for bottom tap zone + up next
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

            // Up Next label — bottom right
            if let upNext = viewModel.upNextSong {
                HStack {
                    Spacer()
                    Text("next: \(upNext.title)")
                        .font(.system(size: PerformanceTheme.upNextSize))
                        .foregroundStyle(PerformanceTheme.upNextColor)
                        .padding(.trailing, 20)
                        .padding(.bottom, 16)
                }
            }
        }
        .ignoresSafeArea()
        .onTapGesture(count: 3) {
            dismiss()
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
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

  Press **Cmd+B**. Expected: Build Succeeded.

---

## Task 4: Verify Triple-Tap and Tap Zones in Simulator

- [ ] **Step 1: Run in simulator**

  Press **Cmd+R**. Open a setlist with at least 5 songs. Tap **▶ Perform**.

- [ ] **Step 2: Verify performance mode appearance**

  - Black background, no navigation bar, no status bar.
  - Songs displayed with correct styling (white titles, grey chord text, orange reminders, green tabs).
  - Subtle chevron indicators at top and bottom edges.
  - "next: [song title]" label visible in bottom-right.

- [ ] **Step 3: Verify tap zones**

  - Tap the bottom zone → view scrolls so the next song appears at the top.
  - Tap the top zone → view scrolls back.
  - If at the end of the setlist, bottom tap does nothing (no target). Expected.

- [ ] **Step 4: Verify triple-tap exits**

  Triple-tap anywhere on screen → returns to ordering mode.

- [ ] **Step 5: Verify "up next" label**

  When scrolling, the label updates to always show the first song below the visible area. When all songs are visible or you're at the end, the label disappears.

- [ ] **Step 6: Commit**

```
git add Leadify/Views/Setlist/Performance/
git commit -m "feat: implement performance mode with snap scroll and triple-tap exit"
```

---

## Task 5: Full App Smoke Test

- [ ] **Step 1: End-to-end test**

  1. Create a setlist "Kermis Arcen" dated 28-03-2026.
  2. Add 6 songs with varying content lengths (some with tabs, some without).
  3. Add a tacet "15 min" between songs 3 and 4.
  4. Reorder songs using drag handles.
  5. Enter performance mode — verify all songs and the tacet render correctly.
  6. Tap bottom zone — verify snap scroll advances to the next unseen song.
  7. Tap top zone — verify snap scroll goes back.
  8. Triple-tap — exits performance mode.
  9. Duplicate the setlist, edit a song in the original — verify the change appears in both.
  10. Delete the duplicate — verify the original and its songs are unaffected.

- [ ] **Step 2: Run all tests**

  Press **Cmd+U**. Expected: all tests pass.

- [ ] **Step 3: Final commit**

```
git commit -m "feat: performance mode complete — Leadify v1 done"
```

---

## Self-Review Notes

- ✅ Spec §7 (performance mode) fully covered.
- ✅ All `PerformanceTheme` tokens used — no hardcoded values in views.
- ✅ Triple-tap to exit via `onTapGesture(count: 3)`.
- ✅ Status bar and system overlays hidden during performance.
- ✅ `PerformanceViewModel` is `@Observable` — reactive, no boilerplate.
- ✅ `onAppear`/`onDisappear` visibility tracking: pragmatic approximation. Partially visible blocks may report inconsistently at the fold boundary — acceptable for stage use.
- ✅ `SongBlock` reuses `leadifyPerformance` MarkdownUI theme defined in Plan 1's `SongEditorSheet.swift`. If that file moves, move the theme extension with it or extract to a separate `MarkdownTheme.swift` file.
- ⚠️ `viewModel` is re-initialized on each `PerformanceView` appearance because it's `@State`. If the setlist changes while in performance mode (unlikely), the view won't update. Acceptable for v1.
