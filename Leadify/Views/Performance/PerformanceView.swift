import SwiftUI

/// Preference key to collect entry frames (in the scroll content's coordinate space).
private struct EntryFrameKey: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct PerformanceView: View {
    let setlist: Setlist
    @Environment(\.dismiss) private var dismiss

    @State private var activeIndex: Int = 0
    @State private var scrollPosition = ScrollPosition()
    @State private var scrollOffset: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0
    @State private var entryFrames: [Int: CGRect] = [:]

    private var entries: [SetlistEntry] { setlist.sortedEntries }
    private static let wideSidebarThreshold: CGFloat = 950

    var body: some View {
        GeometryReader { geo in
            let isWide = geo.size.width >= Self.wideSidebarThreshold

            HStack(spacing: 0) {
                // Main scroll content
                scrollContent(viewportSize: geo.size)

                // Sidebar in wide mode
                if isWide {
                    Divider()
                    PerformanceSetlistSidebar(
                        entries: entries,
                        activeIndex: activeIndex
                    ) { index in
                        navigateTo(index: index)
                    }
                    .frame(width: geo.size.width * 0.25)
                }
            }
            .onAppear { viewportHeight = geo.size.height }
            .onChange(of: geo.size.height) { _, h in viewportHeight = h }
        }
        .background(PerformanceTheme.background.ignoresSafeArea())
        .overlay(alignment: .topTrailing) { closeButton }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    // MARK: - Scroll content

    @ViewBuilder
    private func scrollContent(viewportSize: CGSize) -> some View {
        ZStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.persistentModelID) { index, entry in
                        entryView(entry: entry, index: index)
                            .padding(.horizontal, 32)
                            .opacity(opacityFor(index: index))
                            .animation(.easeInOut(duration: 0.3), value: activeIndex)
                            .background(
                                GeometryReader { entryGeo in
                                    Color.clear.preference(
                                        key: EntryFrameKey.self,
                                        value: [index: entryGeo.frame(in: .named("perfScroll"))]
                                    )
                                }
                            )
                            .id(index)
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 80)
            }
            .coordinateSpace(name: "perfScroll")
            .scrollPosition($scrollPosition)
            .onPreferenceChange(EntryFrameKey.self) { entryFrames = $0 }
            .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentOffset.y }) { _, y in
                scrollOffset = y
            }

            // Tap overlay — UIKit-based, does not block scroll
            PerformanceTapOverlay(
                onLeftTap: { handleTap(direction: .backward) },
                onRightTap: { handleTap(direction: .forward) }
            )
        }
    }

    // MARK: - Entry rendering

    @ViewBuilder
    private func entryView(entry: SetlistEntry, index: Int) -> some View {
        switch entry.itemType {
        case .song:
            SongPerformanceBlock(song: entry.song!)
        case .tacet:
            TacetPerformanceBlock(tacet: entry.tacet!)
        case .medley:
            if let medley = entry.medley {
                MedleyPerformanceBlock(medley: medley)
            }
        }
    }

    // MARK: - Dimming

    private func opacityFor(index: Int) -> Double {
        if index == activeIndex { return 1.0 }
        if index < activeIndex { return 0.3 }
        return 0.4 // upcoming
    }

    // MARK: - Navigation

    private func handleTap(direction: TapDirection) {
        // Get the active entry's frame relative to the viewport
        guard let frameInScroll = entryFrames[activeIndex] else { return }

        // Convert from scroll-content space to viewport space:
        // In scroll-content space, the frame's Y is relative to the content top.
        // The viewport sees content starting at scrollOffset.
        let viewportRelativeFrame = CGRect(
            x: frameInScroll.minX,
            y: frameInScroll.minY - scrollOffset,
            width: frameInScroll.width,
            height: frameInScroll.height
        )

        let result = PerformanceNavigator.handleTap(
            direction: direction,
            activeIndex: activeIndex,
            entryCount: entries.count,
            activeEntryFrame: viewportRelativeFrame,
            viewportHeight: viewportHeight,
            scrollOffset: scrollOffset
        )

        if let target = result.scrollTarget {
            // Scroll within current entry
            withAnimation(.easeInOut(duration: 0.25)) {
                scrollPosition.scrollTo(y: target)
            }
        } else if result.newActiveIndex != activeIndex {
            // Navigate to new entry — scroll to its anchor
            navigateTo(index: result.newActiveIndex)
        }

        activeIndex = result.newActiveIndex
    }

    private func navigateTo(index: Int) {
        activeIndex = index
        withAnimation(.easeInOut(duration: 0.25)) {
            scrollPosition.scrollTo(id: index, anchor: .top)
        }
    }

    // MARK: - Close button

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
}
