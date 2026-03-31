import SwiftUI
import MarkdownUI

/// The inner content of a song in performance mode (title, reminder, divider, chords).
/// Used by both standalone SongPerformanceBlock and MedleyPerformanceBlock.
struct SongPerformanceContent: View {
    let song: Song

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title and Reminder Header
            HStack(alignment: .center, spacing: 12) {
                Text(song.title)
                    .font(.system(size: PerformanceTheme.songTitleSize, weight: .bold))
                    .foregroundStyle(PerformanceTheme.songTitleColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let reminder = song.reminder {
                    Text(reminder)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(EditTheme.accentColor)
                        )
                }
            }
            .padding(.bottom, 16)

            Markdown(song.content)
                .markdownTheme(.leadifyPerformance)
        }
    }
}

/// A standalone song card with drop shadow, used for songs not in a medley.
struct SongPerformanceBlock: View {
    let song: Song
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        SongPerformanceContent(song: song)
            .padding(.horizontal, 32)
            .padding(.vertical, 32)
            .background(
                colorScheme == .dark ? Color(white: 0.09) : Color.white
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(
                color: colorScheme == .dark ? .black.opacity(0.4) : .black.opacity(0.12),
                radius: colorScheme == .dark ? 12 : 8,
                x: 0,
                y: colorScheme == .dark ? 6 : 4
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
    }
}

/// A medley rendered as a single card — medley title on top, songs separated by subtle dividers.
struct MedleyPerformanceBlock: View {
    let medley: Medley
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Medley title
            Text(medley.name)
                .font(.system(size: PerformanceTheme.medleyTitleSize, weight: .semibold))
                .foregroundStyle(PerformanceTheme.medleyIndicatorColor)
                .padding(.bottom, 24)

            // Songs with subtle dividers between them
            ForEach(Array(medley.sortedEntries.enumerated()), id: \.element.persistentModelID) { index, entry in
                if index > 0 {
                    Rectangle()
                        .fill(PerformanceTheme.dividerColor)
                        .frame(height: 1)
                        .padding(.vertical, 24)
                }
                SongPerformanceContent(song: entry.song)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 32)
        .background(
            colorScheme == .dark ? Color(white: 0.09) : Color.white
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(
            color: colorScheme == .dark ? .black.opacity(0.4) : .black.opacity(0.12),
            radius: colorScheme == .dark ? 12 : 8,
            x: 0,
            y: colorScheme == .dark ? 6 : 4
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}
