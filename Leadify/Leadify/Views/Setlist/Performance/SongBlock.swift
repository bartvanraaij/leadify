import SwiftUI
import MarkdownUI

struct SongBlock: View {
    let song: Song

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(song.title)
                .font(.system(size: PerformanceTheme.songTitleSize, weight: .bold))
                .foregroundStyle(PerformanceTheme.songTitleColor)

            if let reminder = song.reminder {
                Text(reminder)
                    .font(.system(size: PerformanceTheme.reminderSize))
                    .foregroundStyle(PerformanceTheme.reminderColor)
            }

            Markdown(song.content)
                .markdownTheme(.leadifyPerformance)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
    }
}
