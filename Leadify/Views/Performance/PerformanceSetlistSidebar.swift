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
                    .padding(.horizontal, PerformanceTheme.sidebarTitleHorizontalPadding)
                    .padding(.top, PerformanceTheme.sidebarSectionSpacing)
                    .padding(.bottom, PerformanceTheme.sidebarSectionSpacing)

                Divider()
                    .padding(.horizontal, PerformanceTheme.sidebarDividerHorizontalPadding)
                    .padding(.bottom, PerformanceTheme.sidebarSmallSpacing)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: PerformanceTheme.sidebarTightSpacing) {
                        ForEach(Array(items.enumerated()), id: \.element.id) {
                            index,
                            item in
                            sidebarRow(index: index, item: item)
                                .opacity(index == activeIndex ? 1.0 : 0.5)
                                .accessibilityIdentifier("sidebar-row-\(index)")
                                .id(index)
                        }
                    }
                    .padding(.bottom, PerformanceTheme.sidebarSectionSpacing)
                    .padding(.horizontal, PerformanceTheme.sidebarSmallSpacing)
                }
                .onChange(of: activeIndex) { _, newIndex in
                    withAnimation(.easeInOut(duration: PerformanceTheme.navigationAnimationDuration)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }

                Divider()
                    .padding(.horizontal, PerformanceTheme.sidebarDividerHorizontalPadding)

                navigationButtons
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PerformanceTheme.sidebarSectionSpacing)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                .padding(.horizontal, PerformanceTheme.sidebarRowHorizontalPadding)
                .padding(.vertical, PerformanceTheme.sidebarTacetRowVerticalPadding)

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
                        .padding(.horizontal, PerformanceTheme.sidebarRowHorizontalPadding)
                        .padding(.vertical, PerformanceTheme.sidebarRowVerticalPadding)
                        .background(
                            RoundedRectangle(
                                cornerRadius: PerformanceTheme.sidebarRowCornerRadius,
                                style: .continuous
                            )
                            .fill(
                                isActive
                                    ? PerformanceTheme.sidebarActiveColor
                                    : .clear
                            )
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if let medley = item.medley {
                    ForEach(medley.sortedEntries, id: \.persistentModelID) {
                        medleyEntry in
                        Text(medleyEntry.song.title)
                            .font(
                                .system(
                                    size: PerformanceTheme.sidebarMedleySongSize
                                )
                            )
                            .foregroundStyle(PerformanceTheme.sidebarTextColor)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .padding(.leading, PerformanceTheme.sidebarRowHorizontalPadding * 2)
                            .padding(.trailing, PerformanceTheme.sidebarRowHorizontalPadding)
                            .padding(.vertical, PerformanceTheme.sidebarTightSpacing)
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
                    .padding(.horizontal, PerformanceTheme.sidebarRowHorizontalPadding)
                    .padding(.vertical, PerformanceTheme.sidebarRowVerticalPadding)
                    .background(
                        RoundedRectangle(cornerRadius: PerformanceTheme.sidebarRowCornerRadius, style: .continuous)
                            .fill(
                                isActive
                                    ? PerformanceTheme.sidebarActiveColor
                                    : .clear
                            )
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
        HStack(spacing: PerformanceTheme.sidebarNavButtonSize) {
            
            Button {
                onPrevious()
            } label: {
                Image(systemName: "chevron.backward")
                    .fontWeight(.semibold)
                    .frame(width: 48, height: 48)
                    .contentShape(Circle())
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous entry")
            .accessibilityIdentifier("sidebar-previous")
            .disabled(!hasPrevious)
            
            
            Button {
                onNext()
            } label: {
                Image(systemName: "chevron.forward")
                    .fontWeight(.semibold)
                    .frame(width: 48, height: 48)
                    .contentShape(Circle())
                    .glassEffect(.regular.interactive(), in: .circle)
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

        HStack(spacing: PerformanceTheme.sidebarSmallSpacing) {
            Rectangle()
                .fill(color)
                .frame(height: 1)
                .frame(maxWidth: PerformanceTheme.sidebarDividerHorizontalPadding)

            Text(label)
                .font(.system(size: PerformanceTheme.sidebarTacetSize).italic())
                .foregroundStyle(color)
                .lineLimit(1)

            Rectangle()
                .fill(color)
                .frame(height: 1)
                .frame(maxWidth: PerformanceTheme.sidebarDividerHorizontalPadding)
        }
    }
}
