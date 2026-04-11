import SwiftUI

/// The inner content of a song in performance mode (title, reminder, divider, chords).
/// Used by both standalone SongPerformanceBlock and MedleyPerformanceBlock.
struct SongPerformanceContent: View {
    let song: Song
    var titleTopPadding: CGFloat = PerformanceTheme.itemInnerVerticalPadding
    var titleBottomPadding: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title and Reminder Header
            HStack(alignment: .center, spacing: 12) {
                Text(song.title)
                    .font(
                        .system(
                            size: PerformanceTheme.songTitleSize,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(PerformanceTheme.songTitleColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let reminder = song.reminder {
                    Text(reminder)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 12,
                                style: .continuous
                            )
                            .fill(EditTheme.accentColor)
                        )
                }
            }
            .padding(.top, titleTopPadding)
            .padding(.bottom, titleBottomPadding)

            SongContentRenderer(content: song.content)
        }
    }
}

/// A standalone song card with drop shadow, used for songs not in a medley.
struct SongPerformanceBlock: View {
    let song: Song
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SongPerformanceContent(song: song)
                .padding(
                    .bottom,
                    (PerformanceTheme.itemInnerVerticalPadding
                        + PerformanceTheme.chordTextSize
                        - PerformanceTheme.chordRowHeight)
                )
                .background(
                    colorScheme == .dark ? Color(white: 0.09) : Color.white
                )

            Rectangle().fill(PerformanceTheme.dividerColor).frame(height: 1)
        }
    }
}

/// A medley rendered as a single card — medley title on top, songs separated by subtle dividers.
struct MedleyPerformanceBlock: View {
    let medley: Medley
    var titleTopPadding: CGFloat = PerformanceTheme.itemInnerVerticalPadding
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Medley title
            Text(medley.name)
                .font(
                    .system(
                        size: PerformanceTheme.medleyTitleSize,
                        weight: .semibold
                    )
                )
                .foregroundStyle(PerformanceTheme.medleyIndicatorColor)
                .padding(.top, titleTopPadding)
                .padding(.bottom, 24)

            // Songs with subtle dividers between them
            ForEach(
                Array(medley.sortedEntries.enumerated()),
                id: \.element.persistentModelID
            ) { index, entry in
                // Divider between songs in medley
                //                if index > 0 {
                //                    Rectangle()
                //                        .fill(PerformanceTheme.dividerColor)
                //                        .frame(height: 1)
                //                        .padding(.vertical, 16)
                //                }
                SongPerformanceContent(
                    song: entry.song,
                    titleTopPadding: 16,
                    titleBottomPadding: 0
                )
            }
        }

    }
}
