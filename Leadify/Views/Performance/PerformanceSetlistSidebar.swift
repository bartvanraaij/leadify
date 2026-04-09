import SwiftUI

/// Compact overview for performance mode. Shows item titles with active highlight.
struct PerformanceSetlistSidebar: View {
    let title: String
    let items: [PerformanceItem]
    let activeIndex: Int
    var onSelect: (Int) -> Void
    var onPrevious: () -> Void
    var onNext: () -> Void

    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(PerformanceTheme.sidebarTextColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 22)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                Divider()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            sidebarRow(index: index, item: item)
                                .opacity(index == activeIndex ? 1.0 : 0.5)
                                .accessibilityIdentifier("sidebar-row-\(index)")
                                .id(index)
                        }
                    }
                    .padding(.bottom, 16)
                    .padding(.horizontal, 8)
                }
                .onChange(of: activeIndex) { _, newIndex in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }

                Divider()
                    .padding(.horizontal, 16)

                navigationButtons
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: .bottom)
        .background(
            PerformanceTheme.sidebarBackground
                .ignoresSafeArea()
                .accessibilityIdentifier("performance-sidebar")
        )
    }

    @ViewBuilder
    private func sidebarRow(index: Int, item: PerformanceItem) -> some View {
        let isActive = index == activeIndex

        switch item.kind {
        case .tacet:
            tacetLabel(item: item)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)

        case .medley:
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    onSelect(index)
                } label: {
                    Text(item.title)
                        .font(.system(size: PerformanceTheme.sidebarSongSize))
                        .foregroundStyle(PerformanceTheme.sidebarTextColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(isActive ? PerformanceTheme.sidebarActiveColor : .clear)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if let medley = item.medley {
                    ForEach(medley.sortedEntries, id: \.persistentModelID) { medleyEntry in
                        Text(medleyEntry.song.title)
                            .font(.system(size: PerformanceTheme.sidebarMedleySongSize))
                            .foregroundStyle(PerformanceTheme.sidebarTextColor)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .padding(.leading, 28)
                            .padding(.trailing, 14)
                            .padding(.vertical, 3)
                    }
                }
            }

        case .song:
            Button {
                onSelect(index)
            } label: {
                Text(item.title)
                    .font(.system(size: PerformanceTheme.sidebarSongSize))
                    .foregroundStyle(PerformanceTheme.sidebarTextColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(isActive ? PerformanceTheme.sidebarActiveColor : .clear)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var hasPrevious: Bool {
        items[0..<activeIndex].contains { !$0.isSkippable }
    }

    private var hasNext: Bool {
        items.dropFirst(activeIndex + 1).contains { !$0.isSkippable }
    }

    private var navigationButtons: some View {
        HStack(spacing: 40) {
            Button { onPrevious() } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
                    .opacity(hasPrevious ? 1 : 0.3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous entry")
            .accessibilityIdentifier("sidebar-previous")
            .disabled(!hasPrevious)

            Button { onNext() } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
                    .opacity(hasNext ? 1 : 0.3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next entry")
            .accessibilityIdentifier("sidebar-next")
            .disabled(!hasNext)
        }
    }

    @ViewBuilder
    private func tacetLabel(item: PerformanceItem) -> some View {
        let label = item.title.isEmpty ? "Tacet" : item.title
        let color = PerformanceTheme.sidebarTextColor.opacity(0.7)

        HStack(spacing: 8) {
            Rectangle()
                .fill(color)
                .frame(height: 1)
                .frame(maxWidth: 16)

            Text(label)
                .font(.system(size: PerformanceTheme.sidebarTacetSize).italic())
                .foregroundStyle(color)
                .lineLimit(1)

            Rectangle()
                .fill(color)
                .frame(height: 1)
                .frame(maxWidth: 16)
        }
    }
}
