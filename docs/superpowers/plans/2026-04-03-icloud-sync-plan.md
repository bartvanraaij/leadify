# iCloud Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable automatic iCloud sync so all songs, setlists, and medleys sync across devices.

**Architecture:** Set `cloudKitDatabase: .automatic` on ModelConfiguration, add missing inverse relationships required by CloudKit, add Xcode entitlements, and create a SyncMonitor for a subtle sync spinner in the sidebar.

**Tech Stack:** SwiftData, CloudKit, SwiftUI

**Spec:** `docs/superpowers/specs/2026-04-02-icloud-sync-design.md`

---

### Task 1: Add Missing Inverse Relationships

CloudKit requires all relationships to have explicit inverses. Several are missing.

**Files:**
- Modify: `Leadify/Models/Song.swift`
- Modify: `Leadify/Models/Tacet.swift`
- Modify: `Leadify/Models/SetlistEntry.swift`
- Modify: `Leadify/Models/Setlist.swift`
- Modify: `Leadify/Models/Medley.swift`
- Modify: `Leadify/Models/MedleyEntry.swift`

- [ ] **Step 1: Add `medleyEntries` inverse on Song**

In `Leadify/Models/Song.swift`, add below the existing `entries` property:

```swift
@Relationship(deleteRule: .cascade, inverse: \MedleyEntry.song)
var medleyEntries: [MedleyEntry] = []
```

- [ ] **Step 2: Add `setlist` inverse on SetlistEntry**

In `Leadify/Models/SetlistEntry.swift`, add a new property:

```swift
var setlist: Setlist?
```

- [ ] **Step 3: Update Setlist.entries with explicit inverse**

In `Leadify/Models/Setlist.swift`, change:

```swift
@Relationship(deleteRule: .cascade) var entries: [SetlistEntry]
```

to:

```swift
@Relationship(deleteRule: .cascade, inverse: \SetlistEntry.setlist) var entries: [SetlistEntry]
```

- [ ] **Step 4: Add `medley` inverse on MedleyEntry**

In `Leadify/Models/MedleyEntry.swift`, add a new property:

```swift
var medley: Medley?
```

- [ ] **Step 5: Update Medley.entries with explicit inverse**

In `Leadify/Models/Medley.swift`, change:

```swift
@Relationship(deleteRule: .cascade) var entries: [MedleyEntry]
```

to:

```swift
@Relationship(deleteRule: .cascade, inverse: \MedleyEntry.medley) var entries: [MedleyEntry]
```

- [ ] **Step 6: Add `setlistEntries` inverse on Medley for SetlistEntry.medley**

In `Leadify/Models/Medley.swift`, add a new property:

```swift
@Relationship(deleteRule: .cascade, inverse: \SetlistEntry.medley)
var setlistEntries: [SetlistEntry] = []
```

- [ ] **Step 7: Add `entry` inverse on Tacet**

In `Leadify/Models/Tacet.swift`, add a new property:

```swift
var entry: SetlistEntry?
```

- [ ] **Step 8: Update SetlistEntry.tacet with explicit inverse**

In `Leadify/Models/SetlistEntry.swift`, change:

```swift
@Relationship(deleteRule: .cascade) var tacet: Tacet?
```

to:

```swift
@Relationship(deleteRule: .cascade, inverse: \Tacet.entry) var tacet: Tacet?
```

- [ ] **Step 9: Build and verify**

Run:
```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```
Expected: BUILD SUCCEEDED with no errors.

- [ ] **Step 10: Run unit tests**

Run:
```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' \
  -only-testing:LeadifyTests
```
Expected: All tests pass. The new inverse properties are automatically populated by SwiftData — no existing code needs to change.

- [ ] **Step 11: Commit**

```bash
git add Leadify/Models/Song.swift Leadify/Models/Tacet.swift Leadify/Models/SetlistEntry.swift \
  Leadify/Models/Setlist.swift Leadify/Models/Medley.swift Leadify/Models/MedleyEntry.swift
git commit -m "feat: add explicit inverse relationships for CloudKit compatibility"
```

---

### Task 2: Enable CloudKit on ModelContainer

**Files:**
- Modify: `Leadify/LeadifyApp.swift`

- [ ] **Step 1: Update ModelContainer initialization**

In `Leadify/LeadifyApp.swift`, replace the `init()` method with:

```swift
init() {
    do {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try ModelContainer(
                for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self, Medley.self, MedleyEntry.self,
                configurations: config
            )
        } else {
            let config = ModelConfiguration(cloudKitDatabase: .automatic)
            container = try ModelContainer(
                for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self, Medley.self, MedleyEntry.self,
                configurations: config
            )
        }
        #else
        let config = ModelConfiguration(cloudKitDatabase: .automatic)
        container = try ModelContainer(
            for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self, Medley.self, MedleyEntry.self,
            configurations: config
        )
        #endif
    } catch {
        fatalError("Failed to create ModelContainer: \(error)")
    }
}
```

- [ ] **Step 2: Build**

Run:
```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```
Expected: BUILD SUCCEEDED. (Note: CloudKit won't actually sync on the simulator without iCloud entitlements — that's Task 3. But the code should compile.)

- [ ] **Step 3: Commit**

```bash
git add Leadify/LeadifyApp.swift
git commit -m "feat: enable CloudKit sync on ModelContainer"
```

---

### Task 3: Add Xcode Entitlements (Manual — User)

This task must be done in Xcode by the user. It cannot be done via file edits because Xcode manages entitlements through its Signing & Capabilities UI.

- [ ] **Step 1: Add iCloud capability**

In Xcode:
1. Select the **Leadify** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **iCloud**
5. Check **CloudKit** under Services
6. Under Containers, click **+** and add: `iCloud.dev.bartvanraaij.leadify`

- [ ] **Step 2: Add Push Notifications capability**

1. Click **+ Capability** again
2. Add **Push Notifications**

- [ ] **Step 3: Add Background Modes capability**

1. Click **+ Capability** again
2. Add **Background Modes**
3. Check **Remote notifications**

- [ ] **Step 4: Verify entitlements file was created**

Check that `Leadify/Leadify.entitlements` (or similar) was created by Xcode with the correct keys.

- [ ] **Step 5: Build and run on device**

Build and run on a real device signed into iCloud to verify CloudKit container is accessible. Check the Xcode console for CloudKit-related logs — initial setup may show schema creation messages.

- [ ] **Step 6: Commit**

```bash
git add Leadify/Leadify.entitlements Leadify.xcodeproj/project.pbxproj
git commit -m "feat: add iCloud, Push Notifications, and Background Modes entitlements"
```

---

### Task 4: Create SyncMonitor

**Files:**
- Create: `Leadify/Models/SyncMonitor.swift`

- [ ] **Step 1: Create SyncMonitor**

Create `Leadify/Models/SyncMonitor.swift`:

```swift
import Foundation
import CoreData

@Observable
final class SyncMonitor {
    private(set) var isSyncing = false

    private var activeCounts = 0

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEvent(_:)),
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil
        )
    }

    @objc private func handleEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if event.endDate == nil {
                self.activeCounts += 1
            } else {
                self.activeCounts = max(0, self.activeCounts - 1)
            }
            self.isSyncing = self.activeCounts > 0
        }
    }
}
```

- [ ] **Step 2: Build**

Run:
```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add Leadify/Models/SyncMonitor.swift
git commit -m "feat: add SyncMonitor to observe CloudKit sync events"
```

---

### Task 5: Wire SyncMonitor into the App and Sidebar Views

**Files:**
- Modify: `Leadify/LeadifyApp.swift`
- Modify: `Leadify/Views/Setlist/SetlistSidebarView.swift`
- Modify: `Leadify/Views/Song/SongLibrarySidebarView.swift`
- Modify: `Leadify/Views/Medley/MedleySidebarView.swift`

- [ ] **Step 1: Create and inject SyncMonitor in LeadifyApp**

In `Leadify/LeadifyApp.swift`, add a new `@State` property next to `songImporter`:

```swift
@State private var syncMonitor = SyncMonitor()
```

Then add `.environment(syncMonitor)` to the `ContentView()` in the body, next to the existing `.environment(songImporter)`:

```swift
ContentView()
    .environment(songImporter)
    .environment(syncMonitor)
```

- [ ] **Step 2: Add sync spinner to SetlistSidebarView**

In `Leadify/Views/Setlist/SetlistSidebarView.swift`, add an environment property:

```swift
@Environment(SyncMonitor.self) private var syncMonitor
```

Then update the `ToolbarItem(placement: .principal)` VStack — replace:

```swift
Text("\(setlists.count) setlist\(setlists.count == 1 ? "" : "s")")
    .font(.caption)
    .foregroundStyle(.secondary)
```

with:

```swift
HStack(spacing: 4) {
    if syncMonitor.isSyncing {
        ProgressView()
            .controlSize(.mini)
    }
    Text("\(setlists.count) setlist\(setlists.count == 1 ? "" : "s")")
        .font(.caption)
        .foregroundStyle(.secondary)
}
```

- [ ] **Step 3: Add sync spinner to SongLibrarySidebarView**

In `Leadify/Views/Song/SongLibrarySidebarView.swift`, add an environment property:

```swift
@Environment(SyncMonitor.self) private var syncMonitor
```

Then update the `ToolbarItem(placement: .principal)` VStack — replace:

```swift
Text("\(allSongs.count) song\(allSongs.count == 1 ? "" : "s")")
    .font(.caption)
    .foregroundStyle(.secondary)
```

with:

```swift
HStack(spacing: 4) {
    if syncMonitor.isSyncing {
        ProgressView()
            .controlSize(.mini)
    }
    Text("\(allSongs.count) song\(allSongs.count == 1 ? "" : "s")")
        .font(.caption)
        .foregroundStyle(.secondary)
}
```

- [ ] **Step 4: Add sync spinner to MedleySidebarView**

In `Leadify/Views/Medley/MedleySidebarView.swift`, add an environment property:

```swift
@Environment(SyncMonitor.self) private var syncMonitor
```

Then update the `ToolbarItem(placement: .principal)` VStack — replace:

```swift
Text("\(allMedleys.count) medley\(allMedleys.count == 1 ? "" : "s")")
    .font(.caption)
    .foregroundStyle(.secondary)
```

with:

```swift
HStack(spacing: 4) {
    if syncMonitor.isSyncing {
        ProgressView()
            .controlSize(.mini)
    }
    Text("\(allMedleys.count) medley\(allMedleys.count == 1 ? "" : "s")")
        .font(.caption)
        .foregroundStyle(.secondary)
}
```

- [ ] **Step 5: Update ContentView preview**

In `Leadify/ContentView.swift`, add `.environment(SyncMonitor())` to the preview:

```swift
#Preview {
    ContentView()
        .modelContainer(for: [Song.self, Tacet.self, SetlistEntry.self, Setlist.self, Medley.self, MedleyEntry.self],
                        inMemory: true)
        .environment(SongImporter())
        .environment(SyncMonitor())
}
```

- [ ] **Step 6: Build**

Run:
```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```
Expected: BUILD SUCCEEDED.

- [ ] **Step 7: Run unit tests**

Run:
```bash
xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' \
  -only-testing:LeadifyTests
```
Expected: All tests pass.

- [ ] **Step 8: Commit**

```bash
git add Leadify/LeadifyApp.swift Leadify/Views/Setlist/SetlistSidebarView.swift \
  Leadify/Views/Song/SongLibrarySidebarView.swift Leadify/Views/Medley/MedleySidebarView.swift \
  Leadify/ContentView.swift
git commit -m "feat: add sync spinner to sidebar views"
```

---

### Task 6: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update project status**

In `CLAUDE.md`, under "### Done", add:

```
- iCloud sync: always-on CloudKit sync via SwiftData, SyncMonitor with sidebar spinner ✅
```

Under "### Not yet started", remove:

```
- CloudKit sync (mentioned as future work in design spec)
```

- [ ] **Step 2: Add SyncMonitor to project layout**

In the `Models/` section of the project layout, add `SyncMonitor` to the list.

- [ ] **Step 3: Add data model note about CloudKit**

Under "## Data model key facts", add:

```
- `ModelContainer` is configured with `cloudKitDatabase: .automatic` — all data syncs to iCloud automatically. CloudKit requires explicit inverse relationships on all model relationships.
- `SyncMonitor` — `@Observable` class that listens to `NSPersistentCloudKitContainer.eventChangedNotification` and exposes `isSyncing` for the sidebar spinner.
```

And remove the existing note:
```
- `ModelContainer` is initialised without `.none` to keep the CloudKit migration path open.
```

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md for iCloud sync"
```
