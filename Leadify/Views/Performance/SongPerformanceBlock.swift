import SwiftUI
import LeadifyCore

/// The inner content of a song in performance mode (title, reminder, divider, chords).
/// Used by SongPerformanceBlock, MedleyPerformanceBlock, and song editor preview.
struct SongPerformanceContent: View {
    let title: String
    let reminder: String?
    let content: String
    var titleTopPadding: CGFloat?
    var titleBottomPadding: CGFloat?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(song: Song, titleTopPadding: CGFloat? = nil, titleBottomPadding: CGFloat? = nil) {
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
        let m = PerformanceTheme.metrics(for: horizontalSizeClass)

        VStack(alignment: .leading, spacing: 0) {
            titleAndReminder(m)
                .padding(.top, titleTopPadding ?? m.itemInnerVerticalPadding)
                .padding(.bottom, titleBottomPadding ?? m.itemInnerVerticalPadding)

            SongContentRenderer(content: content)
        }
    }

    @ViewBuilder
    private func titleAndReminder(_ m: PerformanceTheme.Metrics) -> some View {
        if horizontalSizeClass == .compact {
            VStack(alignment: .leading, spacing: 8) {
                titleText(m)
                reminderText(m)
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: PerformanceTheme.titleReminderSpacing) {
                titleText(m)
                reminderText(m)
            }
        }
    }

    private func titleText(_ m: PerformanceTheme.Metrics) -> some View {
        Text(title)
            .font(.system(size: m.songTitleSize, weight: .bold, design: .rounded))
            .foregroundStyle(PerformanceTheme.songTitleColor)
    }

    @ViewBuilder
    private func reminderText(_ m: PerformanceTheme.Metrics) -> some View {
        if let reminder, !reminder.isEmpty {
            Text(reminder)
                .font(.system(size: m.reminderFontSize, weight: .semibold))
                .foregroundStyle(Color.accentColor)
        }
    }
}

/// A standalone song card with drop shadow, used for songs not in a medley.
struct SongPerformanceBlock: View {
    let song: Song

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        let m = PerformanceTheme.metrics(for: horizontalSizeClass)

        VStack(alignment: .leading, spacing: 0) {
            SongPerformanceContent(song: song)
                .padding(
                    .bottom,
                    (m.itemInnerVerticalPadding + m.chordTextSize - m.chordRowHeight)
                )

            Rectangle().fill(PerformanceTheme.dividerColor).frame(height: 1)
        }
    }
}

/// A medley rendered as a single card — medley title on top, songs separated by subtle dividers.
struct MedleyPerformanceBlock: View {
    let medley: Medley
    var titleTopPadding: CGFloat?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        let m = PerformanceTheme.metrics(for: horizontalSizeClass)

        VStack(alignment: .leading, spacing: 0) {
            Text(medley.name)
                .font(
                    .system(
                        size: m.medleyTitleSize,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .foregroundStyle(PerformanceTheme.medleyIndicatorColor)
                .padding(.top, titleTopPadding ?? m.itemInnerVerticalPadding)
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
