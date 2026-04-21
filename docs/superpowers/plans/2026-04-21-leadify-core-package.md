# LeadifyCore Package Extraction

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract all testable logic into a local Swift package (LeadifyCore) so unit tests can run on macOS without a simulator, eliminating the 60-90s simulator boot from CI.

**Architecture:** Create a local Swift package containing models, navigators, parsers, and calculators — all pure logic with no SwiftUI/UIKit dependencies. The main Leadify app depends on LeadifyCore. Tests live in the package and run via `swift test` on macOS.

**Tech Stack:** Swift Package Manager, SwiftData, Foundation, CoreGraphics, Observation

---

## File structure

### New files
- `LeadifyCore/Package.swift`
- `LeadifyCore/Sources/LeadifyCore/` — all moved source files
- `LeadifyCore/Tests/LeadifyCoreTests/` — all moved test files
- `Leadify/Models/SongContentParser.swift` — extracted from SongContentRenderer (created in Task 1, moved in Task 5)

### Files moved from app to package (Task 5)
Source files (from `Leadify/` to `LeadifyCore/Sources/LeadifyCore/`):
- `Models/Song.swift`
- `Models/Setlist.swift`
- `Models/SetlistEntry.swift`
- `Models/Medley.swift`
- `Models/MedleyEntry.swift`
- `Models/Tacet.swift`
- `Models/Performable.swift`
- `Models/PerformanceNavigationMode.swift`
- `Models/SongFileParser.swift`
- `Models/SongImporter.swift`
- `Models/SongContentParser.swift` (created in Task 1)
- `Views/Performance/ScreenNavigator.swift`
- `Views/Performance/SongNavigator.swift`
- `Views/Performance/SmartNavigator.swift`
- `Views/Performance/PerformanceScrollCalculator.swift`

Test files (from `Tests/UnitTests/` to `LeadifyCore/Tests/LeadifyCoreTests/`):
- `TestHelpers.swift`
- `MedleyTests.swift`
- `SetlistTests.swift`
- `SongTests.swift`
- `SongImporterTests.swift`
- `SongFileParserTests.swift`
- `SongContentRendererTests.swift` → renamed to `SongContentParserTests.swift`
- `PerformanceScrollCalculatorTests.swift`
- `PerformanceNavigationTests.swift`

### Files modified in place (not moved)
- `Leadify/Views/Performance/SongContentRenderer.swift` — remove parser logic, import LeadifyCore
- All view files that reference moved types — add `import LeadifyCore`

### File removed
- `Tests/UnitTests/LeadifyTests.swift` — empty placeholder, not needed

---

## Prerequisite knowledge

### Why this works
SwiftData, Foundation, CoreGraphics, and Observation are all available on macOS. The only frameworks that tie us to iOS Simulator are SwiftUI (views) and UIKit. By extracting all non-view logic into a package, `swift test` runs on macOS natively.

### Access control
Files in a Swift package default to `internal` — invisible to the importing app. Every type, property, method, and initializer that the main app needs must be marked `public`. Test files within the package use `@testable import LeadifyCore` and can access `internal` members, so no `public` needed just for tests.

### SwiftData in packages
`@Model` classes work fine in Swift packages. SwiftData is a system framework — no SPM dependency needed, just `import SwiftData` in source files. The `ModelContainer` in tests uses in-memory configuration, same as today.

---

## Task 1: Extract SongContentParser from SongContentRenderer

**Files:**
- Create: `Leadify/Models/SongContentParser.swift`
- Modify: `Leadify/Views/Performance/SongContentRenderer.swift`
- Modify: `Tests/UnitTests/SongContentRendererTests.swift`

This separates the pure parsing logic (Foundation-only) from the SwiftUI rendering. The parser will later move into the package; the renderer stays in the app.

- [ ] **Step 1: Create SongContentParser.swift**

Create `Leadify/Models/SongContentParser.swift` with the types and functions extracted from `SongContentRenderer`:

```swift
import Foundation

enum SongContentParser {
    enum ContentBlock {
        case heading1(String)
        case heading2(String)
        case chordLine([ChordToken])
        case plainText(String)
        case codeBlock(String, language: String?)
    }

    enum ChordToken: Equatable {
        case chord(String)
        case divider
        case annotation(String)
    }

    private static let chordPattern = try! NSRegularExpression(
        pattern:
            #"^[A-G][b#]?(?:(?:maj|M)\d*|min|m|aug|\+|dim|ø|sus[24]?|add\d+)?\d*(?:[b#+-]\d+)*(?:/[A-G][b#]?)?$"#
    )

    static func isChord(_ token: String) -> Bool {
        let range = NSRange(token.startIndex..., in: token)
        return chordPattern.firstMatch(in: token, range: range) != nil
    }

    static func tokenizeChordLine(_ line: String) -> [ChordToken] {
        let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            .map(String.init)
        var tokens: [ChordToken] = []

        for (index, part) in parts.enumerated() {
            if part.hasPrefix("(") {
                let annotationText = parts[index...].joined(separator: " ")
                tokens.append(.annotation(annotationText))
                break
            } else if part == "/" {
                tokens.append(.divider)
            } else {
                tokens.append(.chord(part))
            }
        }

        return tokens
    }

    static func parse(_ text: String) -> [ContentBlock] {
        let lines = text.components(separatedBy: .newlines)
        var blocks: [ContentBlock] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]

            if line.hasPrefix("```") {
                let language = String(line.dropFirst(3)).trimmingCharacters(
                    in: .whitespaces
                )
                let lang: String? = language.isEmpty ? nil : language
                var codeLines: [String] = []
                index += 1
                while index < lines.count && !lines[index].hasPrefix("```") {
                    codeLines.append(lines[index])
                    index += 1
                }
                if index < lines.count { index += 1 }
                let content = codeLines.joined(separator: "\n")
                if !content.isEmpty {
                    blocks.append(.codeBlock(content, language: lang))
                }
                continue
            }

            if line.hasPrefix("## ") {
                let text = String(line.dropFirst(3)).trimmingCharacters(
                    in: .whitespaces
                )
                if !text.isEmpty { blocks.append(.heading2(text)) }
                index += 1
                continue
            }

            if line.hasPrefix("# ") {
                let text = String(line.dropFirst(2)).trimmingCharacters(
                    in: .whitespaces
                )
                if !text.isEmpty { blocks.append(.heading1(text)) }
                index += 1
                continue
            }

            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                index += 1
                continue
            }

            var paraLines: [String] = []
            while index < lines.count {
                let l = lines[index]
                if l.trimmingCharacters(in: .whitespaces).isEmpty
                    || l.hasPrefix("# ")
                    || l.hasPrefix("## ")
                    || l.hasPrefix("```")
                {
                    break
                }
                paraLines.append(l)
                index += 1
            }
            for line in paraLines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let firstToken =
                    trimmed.split(separator: " ", maxSplits: 1).first.map(
                        String.init
                    ) ?? ""
                if isChord(firstToken) {
                    blocks.append(.chordLine(tokenizeChordLine(trimmed)))
                } else {
                    blocks.append(.plainText(trimmed))
                }
            }
        }

        return blocks
    }
}
```

- [ ] **Step 2: Update SongContentRenderer to use SongContentParser**

Remove from `SongContentRenderer.swift`:
- The entire `// MARK: - Content blocks` extension (lines 208-397): `ContentBlock` enum, `ChordToken` enum, `chordPattern`, `isChord()`, `tokenizeChordLine()`, `ChordFlowLayout` struct, and `parse()` method.

Keep `ChordFlowLayout` in `SongContentRenderer.swift` — it's a SwiftUI `Layout` and belongs with the renderer.

Update references in `SongContentRenderer.swift`:
- `Self.parse(content)` → `SongContentParser.parse(content)`
- `ContentBlock` → `SongContentParser.ContentBlock`
- `ChordToken` → `SongContentParser.ChordToken`
- The switch cases in `blockView` and `chordLineView` stay the same (pattern matching works through the qualified type)

- [ ] **Step 3: Update tests to reference SongContentParser**

In `Tests/UnitTests/SongContentRendererTests.swift`, replace all occurrences:
- `SongContentRenderer.parse(` → `SongContentParser.parse(`
- `SongContentRenderer.ContentBlock` → `SongContentParser.ContentBlock` (if any explicit references exist)

No other changes needed — the tests only call `parse()` and pattern-match on the returned enums.

- [ ] **Step 4: Build and run tests**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'

xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' \
  -only-testing:LeadifyTests
```

Expected: all tests pass, app builds successfully.

- [ ] **Step 5: Commit**

```bash
git add Leadify/Models/SongContentParser.swift \
       Leadify/Views/Performance/SongContentRenderer.swift \
       Tests/UnitTests/SongContentRendererTests.swift
git commit -m "Extract SongContentParser from SongContentRenderer"
```

---

## Task 2: Decouple PerformanceScrollCalculator from PerformanceTheme

**Files:**
- Modify: `Leadify/Views/Performance/PerformanceScrollCalculator.swift`
- Modify: `Tests/UnitTests/PerformanceScrollCalculatorTests.swift`
- Modify: `Tests/UnitTests/PerformanceNavigationTests.swift`
- Grep for all callers in view files

The calculator currently reads `PerformanceTheme.dividerHeight` (a static `CGFloat` constant = 1). We add a `dividerHeight` parameter with a default value so the calculator has no theme dependency.

- [ ] **Step 1: Update PerformanceScrollCalculator.swift**

Remove `import UIKit` (unused). Replace `import CoreGraphics` and `import UIKit` with just:

```swift
import CoreGraphics
```

Add `dividerHeight` parameter to the two functions that use it:

In `inEntrySnaps`:
```swift
static func inEntrySnaps(for frame: CGRect, viewportHeight: CGFloat, dividerHeight: CGFloat = 1) -> [CGFloat] {
    let workingFrameMaxY = frame.maxY - dividerHeight
```

In `canScrollDown`:
```swift
static func canScrollDown(
    activeEntryFrame frame: CGRect?,
    scrollOffset: CGFloat,
    viewportHeight: CGFloat,
    overlap: CGFloat = 0,
    dividerHeight: CGFloat = 1
) -> Bool {
    ...
    let workingFrameMaxY = frame.maxY - dividerHeight
```

Remove both references to `PerformanceTheme.dividerHeight`.

- [ ] **Step 2: Update callers in view files**

Search for all callers of `inEntrySnaps` and `canScrollDown` in view files. They currently don't pass `dividerHeight`, so the default value (`1`) matches the existing `PerformanceTheme.dividerHeight` value. **No changes needed in callers** — the default handles it.

Verify by grepping:
```bash
grep -rn "inEntrySnaps\|canScrollDown" Leadify/Views/
```

Confirm none pass a custom dividerHeight — they'll use the default.

- [ ] **Step 3: Update test files**

In `Tests/UnitTests/PerformanceNavigationTests.swift`, replace references to `PerformanceTheme.dividerHeight` with the literal `1.0`:

Line 49:
```swift
let expectedLastSnap = 800 - 1.0 - 600
```

Line 90:
```swift
let expectedLastSnap = 800 - 1.0 - 600
```

`PerformanceScrollCalculatorTests.swift` doesn't reference PerformanceTheme — no changes needed.

- [ ] **Step 4: Build and run tests**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'

xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' \
  -only-testing:LeadifyTests
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add Leadify/Views/Performance/PerformanceScrollCalculator.swift \
       Tests/UnitTests/PerformanceNavigationTests.swift
git commit -m "Decouple PerformanceScrollCalculator from PerformanceTheme"
```

---

## Task 3: Decouple SongImporter from SwiftUI

**Files:**
- Modify: `Leadify/Models/SongImporter.swift`

`SongImporter` imports SwiftUI but only uses `@Observable` (from the `Observation` framework) and SwiftData types. No SwiftUI-specific types are referenced.

- [ ] **Step 1: Replace import**

In `Leadify/Models/SongImporter.swift`, replace:
```swift
import SwiftUI
import SwiftData
```
with:
```swift
import Foundation
import Observation
import SwiftData
```

- [ ] **Step 2: Build and run tests**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'

xcodebuild test -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5' \
  -only-testing:LeadifyTests
```

Expected: all tests pass, no SwiftUI dependency in any file that will move to the package.

- [ ] **Step 3: Commit**

```bash
git add Leadify/Models/SongImporter.swift
git commit -m "Replace SwiftUI import with Observation in SongImporter"
```

---

## Task 4: Create LeadifyCore Swift package and move files

**Files:**
- Create: `LeadifyCore/Package.swift`
- Create: `LeadifyCore/Sources/LeadifyCore/` — directory structure
- Create: `LeadifyCore/Tests/LeadifyCoreTests/` — directory structure
- Move: all source and test files listed in the file structure section above
- Modify: moved files to add `public` access control
- Delete: `Tests/UnitTests/LeadifyTests.swift` (empty placeholder)

This is the big structural change. After this task, all tests run via `swift test` in the LeadifyCore directory.

- [ ] **Step 1: Create package directory structure**

```bash
mkdir -p LeadifyCore/Sources/LeadifyCore
mkdir -p LeadifyCore/Tests/LeadifyCoreTests
```

- [ ] **Step 2: Create Package.swift**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LeadifyCore",
    platforms: [.macOS(.v15), .iOS(.v18)],
    products: [
        .library(name: "LeadifyCore", targets: ["LeadifyCore"]),
    ],
    targets: [
        .target(name: "LeadifyCore"),
        .testTarget(name: "LeadifyCoreTests", dependencies: ["LeadifyCore"]),
    ]
)
```

Note: platform versions should match the project's deployment target. Adjust `.macOS(.v15)` and `.iOS(.v18)` if needed — the key requirement is that SwiftData and Observation are available (macOS 14+ / iOS 17+).

- [ ] **Step 3: Move source files**

```bash
# Models
mv Leadify/Models/Song.swift LeadifyCore/Sources/LeadifyCore/
mv Leadify/Models/Setlist.swift LeadifyCore/Sources/LeadifyCore/
mv Leadify/Models/SetlistEntry.swift LeadifyCore/Sources/LeadifyCore/
mv Leadify/Models/Medley.swift LeadifyCore/Sources/LeadifyCore/
mv Leadify/Models/MedleyEntry.swift LeadifyCore/Sources/LeadifyCore/
mv Leadify/Models/Tacet.swift LeadifyCore/Sources/LeadifyCore/
mv Leadify/Models/Performable.swift LeadifyCore/Sources/LeadifyCore/
mv Leadify/Models/PerformanceNavigationMode.swift LeadifyCore/Sources/LeadifyCore/
mv Leadify/Models/SongFileParser.swift LeadifyCore/Sources/LeadifyCore/
mv Leadify/Models/SongImporter.swift LeadifyCore/Sources/LeadifyCore/
mv Leadify/Models/SongContentParser.swift LeadifyCore/Sources/LeadifyCore/

# Navigators + calculator
mv Leadify/Views/Performance/ScreenNavigator.swift LeadifyCore/Sources/LeadifyCore/
mv Leadify/Views/Performance/SongNavigator.swift LeadifyCore/Sources/LeadifyCore/
mv Leadify/Views/Performance/SmartNavigator.swift LeadifyCore/Sources/LeadifyCore/
mv Leadify/Views/Performance/PerformanceScrollCalculator.swift LeadifyCore/Sources/LeadifyCore/
```

- [ ] **Step 4: Move test files**

```bash
mv Tests/UnitTests/TestHelpers.swift LeadifyCore/Tests/LeadifyCoreTests/
mv Tests/UnitTests/MedleyTests.swift LeadifyCore/Tests/LeadifyCoreTests/
mv Tests/UnitTests/SetlistTests.swift LeadifyCore/Tests/LeadifyCoreTests/
mv Tests/UnitTests/SongTests.swift LeadifyCore/Tests/LeadifyCoreTests/
mv Tests/UnitTests/SongImporterTests.swift LeadifyCore/Tests/LeadifyCoreTests/
mv Tests/UnitTests/SongFileParserTests.swift LeadifyCore/Tests/LeadifyCoreTests/
mv Tests/UnitTests/SongContentRendererTests.swift LeadifyCore/Tests/LeadifyCoreTests/SongContentParserTests.swift
mv Tests/UnitTests/PerformanceScrollCalculatorTests.swift LeadifyCore/Tests/LeadifyCoreTests/
mv Tests/UnitTests/PerformanceNavigationTests.swift LeadifyCore/Tests/LeadifyCoreTests/
rm Tests/UnitTests/LeadifyTests.swift
```

- [ ] **Step 5: Add `public` access control to all moved source files**

Every type, stored property, computed property, method, enum case, and initializer that the main app uses must be `public`. Test files use `@testable import LeadifyCore` so they can access `internal` members — only add `public` for what the app needs.

For each file, the pattern is:
- `class Song {` → `public class Song {`
- `var title: String` → `public var title: String`
- `func duplicate(` → `public func duplicate(`
- `enum SetlistItemType` → `public enum SetlistItemType`
- `case song` → `case song` (enum cases inherit access from their type)
- `init(` → `public init(`
- `protocol Performable` → `public protocol Performable`
- `struct PerformanceItem` → `public struct PerformanceItem`
- `enum PerformanceScrollCalculator` → `public enum PerformanceScrollCalculator`
- `static func handleTap(` → `public static func handleTap(`

**Important:** SwiftData's `@Model` macro generates an initializer, but you still need an explicit `public init(...)` for public access. Each `@Model` class already has a hand-written `init` — just add `public`.

Go through each of the 15 source files and add `public` where needed. This is the most tedious part of the task but it's mechanical.

- [ ] **Step 6: Update test imports**

In every test file, replace:
```swift
@testable import Leadify
```
with:
```swift
@testable import LeadifyCore
```

In `SongContentParserTests.swift` (renamed from `SongContentRendererTests.swift`), also rename the class:
```swift
final class SongContentParserTests: XCTestCase {
```

- [ ] **Step 7: Verify package builds and tests pass on macOS**

```bash
cd LeadifyCore && swift test
```

Expected: all tests pass on macOS, no simulator involved.

- [ ] **Step 8: Add LeadifyCore as a local package dependency in Xcode**

This step requires Xcode UI interaction:
1. Open `Leadify.xcodeproj` in Xcode
2. File → Add Package Dependencies → Add Local → select `LeadifyCore/` directory
3. In the Leadify target → General → "Frameworks, Libraries, and Embedded Content" → add `LeadifyCore`
4. Remove the now-empty `Tests/UnitTests/` directory and `LeadifyTests` test target from the Xcode project (all tests moved to the package)

- [ ] **Step 9: Add `import LeadifyCore` to app view files**

Every view file that references types from the moved files needs `import LeadifyCore`. Find them:

```bash
grep -rn "Song\|Setlist\|Medley\|Tacet\|Performable\|PerformanceItem\|PerformanceNavigationMode\|SongNavigator\|SmartNavigator\|ScreenNavigator\|PerformanceScrollCalculator\|SongContentParser\|SongImporter\|SongFileParser" Leadify/Views/ Leadify/Theme/ Leadify/
```

Add `import LeadifyCore` to each file that references these types. The compiler will tell you which ones you missed.

- [ ] **Step 10: Build the full app**

```bash
xcodebuild build -scheme Leadify \
  -destination 'platform=iOS Simulator,id=B05E0EF4-11D8-4C5A-AD11-FCA80684DEC5'
```

Expected: successful build. Fix any missing imports or access control issues the compiler reports.

- [ ] **Step 11: Run package tests one more time**

```bash
cd LeadifyCore && swift test
```

Expected: all tests pass on macOS.

- [ ] **Step 12: Commit**

```bash
git add -A
git commit -m "Extract LeadifyCore package with sim-less unit tests"
```

---

## Task 5: Update CI to run tests on macOS

**Files:**
- Modify: CI configuration file (e.g. `.github/workflows/test.yml` or equivalent)

- [ ] **Step 1: Update test command**

Replace the existing test command that uses `-destination 'platform=iOS Simulator,...'` with:

```bash
cd LeadifyCore && swift test
```

This runs on the macOS host directly — no simulator boot, no Xcode scheme, no device ID. On a CI Mac runner this should complete in ~10-20 seconds instead of 90-120.

- [ ] **Step 2: Commit**

```bash
git add <ci-config-file>
git commit -m "Run unit tests via swift test on macOS (no simulator)"
```

---

## Summary of what changes

| Before | After |
|--------|-------|
| All code in Xcode app target | Logic in LeadifyCore package, views in app |
| Tests run on iOS Simulator | Tests run on macOS via `swift test` |
| `xcodebuild test` needs ~90-120s (boot + build + run) | `swift test` needs ~10-20s (build + run) |
| SongContentRenderer contains parser + view | SongContentParser (Foundation) + SongContentRenderer (SwiftUI) |
| PerformanceScrollCalculator depends on PerformanceTheme | Standalone with default parameter |
| SongImporter imports SwiftUI | Imports Observation + SwiftData |

## Risks and mitigations

- **Swift 6 strict concurrency:** The package uses `swift-tools-version: 6.0` which enables strict concurrency. If any model or navigator triggers Sendable warnings, add `swiftSettings: [.swiftLanguageMode(.v5)]` to the target in Package.swift as a quick fix, then address warnings later.
- **Access control tedium:** Adding `public` to ~15 files is mechanical but error-prone. The compiler catches every miss — just iterate on `swift build` until it compiles.
- **Xcode project file:** Adding the local package dependency requires Xcode UI. Can't be done purely from CLI. This is a one-time manual step.
