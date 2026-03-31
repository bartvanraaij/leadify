import SwiftUI

/// Compact setlist overview for wide-mode performance. Shows entry titles with active highlight.
struct PerformanceSetlistSidebar: View {
    let entries: [SetlistEntry]
    let activeIndex: Int
    var onSelect: (Int) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.persistentModelID) { index, entry in
                        sidebarRow(index: index, entry: entry)
                            .id(index)
                    }
                }
                .padding(.vertical, 16)
            }
            .onChange(of: activeIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PerformanceTheme.sidebarBackground)
    }

    @ViewBuilder
    private func sidebarRow(index: Int, entry: SetlistEntry) -> some View {
        let isActive = index == activeIndex

        Button {
            onSelect(index)
        } label: {
            HStack(spacing: 8) {
                // Active indicator bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(isActive ? PerformanceTheme.sidebarActiveColor : .clear)
                    .frame(width: 3)

                Text(entryTitle(entry))
                    .font(.system(size: 15, weight: isActive ? .bold : .regular))
                    .foregroundStyle(isActive ? PerformanceTheme.sidebarActiveColor : PerformanceTheme.sidebarTextColor)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func entryTitle(_ entry: SetlistEntry) -> String {
        switch entry.itemType {
        case .song:
            return entry.song?.title ?? "Untitled"
        case .tacet:
            if let label = entry.tacet?.label, !label.isEmpty {
                return label
            }
            return "Tacet"
        case .medley:
            return entry.medley?.name ?? "Medley"
        }
    }
}
