import SwiftUI

struct SongEntryRow: View {
    let entry: SetlistEntry
    let onEdit: () -> Void

    private var song: Song { entry.song! }

    private var contentPreview: String {
        song.content
            .components(separatedBy: .newlines)
            .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty
                           && !$0.hasPrefix("#")
                           && !$0.hasPrefix("```") })
            ?? ""
    }

    var body: some View {
        Button(action: onEdit) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(song.title)
                            .font(.system(size: EditTheme.songTitleSize, weight: .semibold))
                            .foregroundStyle(EditTheme.primaryText)
                        if let reminder = song.reminder {
                            Text(reminder)
                                .font(.system(size: EditTheme.reminderSize, weight: .semibold))
                                .foregroundStyle(EditTheme.reminderColor)
                        }
                    }
                    if !contentPreview.isEmpty {
                        Text(contentPreview)
                            .font(.system(size: EditTheme.songPreviewSize))
                            .foregroundStyle(EditTheme.secondaryText)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
