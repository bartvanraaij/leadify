# iCloud Sync Design Spec

**Date:** 2026-04-02
**Goal:** Sync all app data (songs, setlists, medleys) across devices via iCloud, like Apple Notes.

## Decisions

- **Always-on sync** — no settings toggle. `cloudKitDatabase: .automatic` on the ModelConfiguration.
- **Fully invisible** — no sync status UI. Data syncs in the background when connected.
- **Offline-first** — full CRUD works offline; changes sync when connectivity returns.
- **Last-writer-wins** — CloudKit's default conflict resolution. No manual merge UI.
- **iPad-only for now** — Mac target can be added later pointing at the same CloudKit container.

## Changes Required

### 1. Xcode Project Configuration

Add three capabilities to the Leadify target:

1. **iCloud** — enable CloudKit service, container `iCloud.bartvanraaij.Leadify`
2. **Background Modes** — enable "Remote notifications" (for push-based sync)
3. **Push Notifications** — required by CloudKit for silent push delivery

These add an entitlements file (`Leadify.entitlements`) with:
- `com.apple.developer.icloud-container-identifiers` → `["iCloud.bartvanraaij.Leadify"]`
- `com.apple.developer.icloud-services` → `["CloudDocuments"]` (CloudKit)
- `UIBackgroundModes` → `["remote-notification"]`
- `aps-environment` → `development` (auto-switches to `production` on release)

### 2. ModelContainer Configuration

In `LeadifyApp.swift`, update the non-test `ModelConfiguration` to enable CloudKit:

```swift
let config = ModelConfiguration(cloudKitDatabase: .automatic)
container = try ModelContainer(
    for: Song.self, Tacet.self, SetlistEntry.self, Setlist.self, Medley.self, MedleyEntry.self,
    configurations: config
)
```

UI test path stays `isStoredInMemoryOnly: true` — no CloudKit in tests.

### 3. Model Relationship Fixes (CloudKit Requires Explicit Inverses)

CloudKit (via NSPersistentCloudKitContainer) requires all relationships to have explicit inverses. Currently missing:

#### Song — add inverse for MedleyEntry
```swift
// Song.swift — add:
@Relationship(deleteRule: .cascade, inverse: \MedleyEntry.song)
var medleyEntries: [MedleyEntry] = []
```

Note: Song already has `entries` for SetlistEntry. This adds `medleyEntries` for the MedleyEntry relationship.

**Problem:** Song currently declares `@Relationship(deleteRule: .cascade, inverse: \SetlistEntry.song) var entries`. The `.cascade` delete rule means deleting a Song cascades to delete its SetlistEntry objects — which then cascades to remove those entries from their Setlist. This is correct behavior (a deleted song should disappear from setlists). The same `.cascade` applies to `medleyEntries`.

#### SetlistEntry — add inverse back to Setlist
```swift
// SetlistEntry.swift — add:
var setlist: Setlist?
```
And update Setlist.entries:
```swift
// Setlist.swift — update:
@Relationship(deleteRule: .cascade, inverse: \SetlistEntry.setlist)
var entries: [SetlistEntry]
```

#### MedleyEntry — add inverse back to Medley
```swift
// MedleyEntry.swift — add:
var medley: Medley?
```
And update Medley.entries:
```swift
// Medley.swift — update:
@Relationship(deleteRule: .cascade, inverse: \MedleyEntry.medley)
var entries: [MedleyEntry]
```

#### Tacet — add inverse back to SetlistEntry
```swift
// Tacet.swift — add:
var entry: SetlistEntry?
```
And update SetlistEntry.tacet:
```swift
// SetlistEntry.swift — update:
@Relationship(deleteRule: .cascade, inverse: \Tacet.entry)
var tacet: Tacet?
```

#### SetlistEntry.medley — add inverse on Medley
```swift
// Medley.swift — add:
@Relationship(deleteRule: .nullify, inverse: \SetlistEntry.medley)
var setlistEntries: [SetlistEntry] = []
```

Note: `.nullify` here because deleting a Medley should set `SetlistEntry.medley = nil` and leave the entry in place (or the entry can be cleaned up separately). This differs from Song's `.cascade` because a medley deletion is more deliberate.

**Reconsideration:** Actually, deleting a Medley should also remove the SetlistEntry that references it (same as Song). Use `.cascade`:
```swift
@Relationship(deleteRule: .cascade, inverse: \SetlistEntry.medley)
var setlistEntries: [SetlistEntry] = []
```

### 4. Summary of All Relationships After Fixes

| Parent | Property | Child | Inverse Property | Delete Rule |
|--------|----------|-------|-----------------|-------------|
| Song | entries | SetlistEntry | setlist (n/a, existing) | .cascade |
| Song | medleyEntries | MedleyEntry | song | .cascade |
| Setlist | entries | SetlistEntry | setlist | .cascade |
| SetlistEntry | tacet | Tacet | entry | .cascade |
| Medley | entries | MedleyEntry | medley | .cascade |
| Medley | setlistEntries | SetlistEntry | medley | .cascade |

### 5. Verify Existing Code Isn't Broken by New Inverse Properties

Adding inverse properties like `setlist: Setlist?` on SetlistEntry means SwiftData will automatically populate them. Existing code that creates entries and appends them to `setlist.entries` will continue to work — SwiftData maintains both sides of the relationship.

Scan for any code that manually sets these new properties (there shouldn't be any since they didn't exist before).

### 6. No Schema Migration Needed

SwiftData with CloudKit uses lightweight migration automatically. Adding new optional properties (the inverse relationships) and changing ModelConfiguration are both handled without an explicit migration plan.

## What Does NOT Change

- All views, themes, and UI code — unaffected
- Performable protocol and PerformanceView — unaffected
- Unit and UI tests — unaffected (tests use in-memory store)
- Song import/export — unaffected
- Ordering logic (sortedEntries, addEntry, moveEntries) — unaffected

## Testing

- **Automated tests** continue using in-memory store — no CloudKit involvement
- **Manual testing** requires two devices (or simulators) signed into the same iCloud account
- **Verify:** create a song on Device A, confirm it appears on Device B within seconds
- **Verify:** edit a song on Device A, confirm the change syncs to Device B
- **Verify:** delete a setlist on Device A, confirm it disappears on Device B
- **Verify:** app works fully offline (airplane mode), syncs when reconnected

## CloudKit Dashboard

After first run with CloudKit enabled, the schema is auto-created in the CloudKit Dashboard (developer.apple.com/icloud/dashboard). The development environment schema must be promoted to production before App Store release. This is a one-click operation in the dashboard.
