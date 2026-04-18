import Foundation
import SwiftData

extension PersistentIdentifier {
    /// Stable string representation suitable for use as an Identifiable id.
    /// Unlike hashValue, this is consistent across app launches and unique per entry.
    var stableHash: String {
        "\(self)"
    }
}

/// A lightweight value type representing one item in a performance.
/// Used by PerformanceView to render and navigate without knowing about SetlistEntry or MedleyEntry.
struct PerformanceItem: Identifiable {
    let id: String
    let title: String
    let kind: Kind
    /// Non-nil for song and medley items.
    let song: Song?
    /// Non-nil for tacet items.
    let tacet: Tacet?
    /// Non-nil for medley items (the full medley, rendered as a single block).
    let medley: Medley?
    /// Non-nil for the first song in a separated medley — carries the medley name for display.
    let medleyTitle: String?

    enum Kind {
        case song
        case tacet
        case medley
    }

    /// Whether this item should be skipped during next/prev navigation.
    var isSkippable: Bool { kind == .tacet }
}

/// Anything that can be performed — provides a title and a list of performance items.
/// Conformers: Setlist (songs, tacets, medleys) and Medley (individual songs).
protocol Performable {
    var performanceTitle: String { get }
    var performanceItems: [PerformanceItem] { get }
}

extension Setlist: Performable {
    var performanceTitle: String { name }

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
}

/// Ad-hoc performable for playing all songs (e.g. from the song library).
struct SongCollection: Performable {
    let performanceTitle: String
    let songs: [Song]

    var performanceItems: [PerformanceItem] {
        songs.map { song in
            PerformanceItem(
                id: song.persistentModelID.stableHash,
                title: song.title,
                kind: .song,
                song: song,
                tacet: nil,
                medley: nil,
                medleyTitle: nil
            )
        }
    }
}

extension Medley: Performable {
    var performanceTitle: String { name }

    var performanceItems: [PerformanceItem] {
        sortedEntries.map { entry in
            PerformanceItem(
                id: entry.persistentModelID.stableHash,
                title: entry.song.title,
                kind: .song,
                song: entry.song,
                tacet: nil,
                medley: nil,
                medleyTitle: nil
            )
        }
    }
}
