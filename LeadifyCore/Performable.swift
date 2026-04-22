import Foundation
import SwiftData

extension PersistentIdentifier {
    public var stableHash: String {
        "\(self)"
    }
}

public struct PerformanceItem: Identifiable {
    public let id: String
    public let title: String
    public let kind: Kind
    public let song: Song?
    public let tacet: Tacet?
    public let medley: Medley?
    public let medleyTitle: String?

    public enum Kind {
        case song
        case tacet
        case medley
    }

    public var isSkippable: Bool { kind == .tacet }

    public init(id: String, title: String, kind: Kind, song: Song?, tacet: Tacet?, medley: Medley?, medleyTitle: String?) {
        self.id = id
        self.title = title
        self.kind = kind
        self.song = song
        self.tacet = tacet
        self.medley = medley
        self.medleyTitle = medleyTitle
    }
}

public protocol Performable {
    var performanceTitle: String { get }
    var performanceItems: [PerformanceItem] { get }
}

extension Setlist: Performable {
    public var performanceTitle: String { name }

    public var performanceItems: [PerformanceItem] {
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

public struct SongCollection: Performable {
    public let performanceTitle: String
    public let songs: [Song]

    public init(performanceTitle: String, songs: [Song]) {
        self.performanceTitle = performanceTitle
        self.songs = songs
    }

    public var performanceItems: [PerformanceItem] {
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
    public var performanceTitle: String { name }

    public var performanceItems: [PerformanceItem] {
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
