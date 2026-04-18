import SwiftUI

/// The inner content of a song in performance mode (title, reminder, divider, chords).
/// Used by both standalone SongPerformanceBlock and MedleyPerformanceBlock.
struct SongPerformanceContent: View {
    let song: Song
    var titleTopPadding: CGFloat = PerformanceTheme.itemInnerVerticalPadding
    var titleBottomPadding: CGFloat = PerformanceTheme.itemInnerVerticalPadding

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title and Reminder Header
            HStack(alignment: .center, spacing: PerformanceTheme.titleReminderSpacing) {
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
                        .font(.system(size: PerformanceTheme.reminderFontSize, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, PerformanceTheme.reminderHorizontalPadding)
                        .padding(.vertical, PerformanceTheme.reminderVerticalPadding)
                        .background(
                            RoundedRectangle(
                                cornerRadius: PerformanceTheme.reminderCornerRadius,
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
    var medleyTitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let medleyTitle {
                Text(medleyTitle)
                    .font(.system(size: PerformanceTheme.medleyTitleSize, weight: .semibold))
                    .foregroundStyle(PerformanceTheme.medleyIndicatorColor)
                    .padding(.top, PerformanceTheme.itemInnerVerticalPadding)
                    .padding(.bottom, PerformanceTheme.medleyTitleBottomPadding)
            }

            SongPerformanceContent(song: song)
                .padding(
                    .bottom,
                    (PerformanceTheme.itemInnerVerticalPadding
                        + PerformanceTheme.chordTextSize
                        - PerformanceTheme.chordRowHeight)
                )

            Rectangle().fill(PerformanceTheme.dividerColor).frame(height: 1)
        }
    }
}

/// A medley rendered as a single card — medley title on top, songs separated by subtle dividers.
struct MedleyPerformanceBlock: View {
    let medley: Medley
    var titleTopPadding: CGFloat = PerformanceTheme.itemInnerVerticalPadding

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
                .padding(.bottom, PerformanceTheme.medleyTitleBottomPadding)

            // Songs with subtle dividers between them
            ForEach(
                Array(medley.sortedEntries.enumerated()),
                id: \.element.persistentModelID
            ) { index, entry in
                if index > 0 {
                    Rectangle()
                        .fill(PerformanceTheme.dividerColor)
                        .frame(height: PerformanceTheme.dividerHeight)
                }

                SongPerformanceContent(
                    song: entry.song,
                    titleTopPadding: PerformanceTheme.medleyInnerSongTitleTopPadding,
                    titleBottomPadding: 0
                )
            }
            
            Rectangle().fill(PerformanceTheme.dividerColor).frame(height: 1)
        }

    }
}
