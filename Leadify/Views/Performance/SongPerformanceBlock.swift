import SwiftUI

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

            SongContentRenderer(content: song.content)
        }
    }
}

/// A standalone song block, used for songs not in a medley.
struct SongPerformanceBlock: View {
    let song: Song

    var body: some View {
        SongPerformanceContent(song: song)
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 16)
    }
}

/// A medley rendered as a single block — medley title on top, songs separated by subtle dividers.
struct MedleyPerformanceBlock: View {
    let medley: Medley

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
    }
}
