import SwiftUI
import MarkdownUI

struct SongBlock: View {
    let song: Song
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title and Reminder Header
            HStack(alignment: .center, spacing: 12) {
                // Title
                Text(song.title)
                    .font(.system(size: PerformanceTheme.songTitleSize, weight: .bold))
                    .foregroundStyle(PerformanceTheme.songTitleColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Reminder (if exists) - Pill style on the right
                if let reminder = song.reminder {
                    Text(reminder)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(PerformanceTheme.reminderColor)
                        )
                        .shadow(
                            color: PerformanceTheme.reminderColor.opacity(0.3),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                }
            }
            .padding(.bottom, 28)

            // Thin divider line
            Rectangle()
                .fill(PerformanceTheme.dividerColor)
                .frame(height: 1)
                .padding(.bottom, 28)

            // Content
            Markdown(song.content)
                .markdownTheme(.leadifyPerformance)
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
