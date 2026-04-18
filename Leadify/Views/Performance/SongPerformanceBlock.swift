import SwiftUI

/// The inner content of a song in performance mode (title, reminder, divider, chords).
/// Used by SongPerformanceBlock, MedleyPerformanceBlock, and song editor preview.
struct SongPerformanceContent: View {
    let title: String
    let reminder: String?
    let content: String
    var titleTopPadding: CGFloat = PerformanceTheme.itemInnerVerticalPadding
    var titleBottomPadding: CGFloat = PerformanceTheme.itemInnerVerticalPadding

    init(song: Song, titleTopPadding: CGFloat = PerformanceTheme.itemInnerVerticalPadding, titleBottomPadding: CGFloat = PerformanceTheme.itemInnerVerticalPadding) {
        self.title = song.title
        self.reminder = song.reminder
        self.content = song.content
        self.titleTopPadding = titleTopPadding
        self.titleBottomPadding = titleBottomPadding
    }

    init(title: String, reminder: String?, content: String) {
        self.title = title
        self.reminder = reminder
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: PerformanceTheme.titleReminderSpacing) {
                Text(title)
                    .font(
                        .system(
                            size: PerformanceTheme.songTitleSize,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(PerformanceTheme.songTitleColor)

                if let reminder, !reminder.isEmpty {
                    Text(reminder)
                        .font(.system(size: PerformanceTheme.reminderFontSize, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.top, titleTopPadding)
            .padding(.bottom, titleBottomPadding)

            SongContentRenderer(content: content)
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
                    .font(.system(size: PerformanceTheme.medleyTitleSize, weight: .semibold, design: .rounded))
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
                        weight: .semibold,
                        design: .rounded
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
                    titleBottomPadding: PerformanceTheme.medleyInnerSongTitleTopPadding
                )
            }
            
            Rectangle().fill(PerformanceTheme.dividerColor).frame(height: 1)
        }

    }
}
