import SwiftUI

/// Preference key to collect entry frames in the scroll content's own coordinate space.
/// Frames are stable absolute content positions — they do not change as the user scrolls.
private struct EntryFrameKey: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]
    static func reduce(
        value: inout [Int: CGRect],
        nextValue: () -> [Int: CGRect]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct PerformanceView: View {
    let source: any Performable
    @Environment(\.dismiss) private var dismiss

    @State private var activeIndex: Int = 0
    @State private var scrollPosition = ScrollPosition()
    @State private var scrollOffset: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0
    @State private var entryFrames: [Int: CGRect] = [:]
    @State private var showSidebar: Bool = false
    @State var safeAreaInsets: EdgeInsets = .init()
    @AppStorage(PerformanceNavigationMode.storageKey) private var storedNavMode: String = PerformanceNavigationMode.defaultMode.rawValue
    @State private var showToolbar: Bool = false

    private var navMode: PerformanceNavigationMode {
        PerformanceNavigationMode(rawValue: storedNavMode) ?? .defaultMode
    }

    private var items: [PerformanceItem] { source.performanceItems }

    private static let autoSidebarThreshold: CGFloat = PerformanceTheme.autoSidebarThreshold

    var body: some View {
        GeometryReader { geo in
            scrollContent(viewportSize: geo.size)

                .overlay { scrollIndicators }
                .overlay(alignment: .top) {
                    LinearGradient(
                        stops: [
                            .init(color: PerformanceTheme.background.opacity(0.85), location: 0),
                            .init(color: PerformanceTheme.background.opacity(0.6), location: 0.3),
                            .init(color: PerformanceTheme.background.opacity(0), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 240)
                    .allowsHitTesting(false)
                    .opacity(showToolbar ? 1 : 0)
                    .animation(.easeInOut(duration: PerformanceTheme.navigationAnimationDuration), value: showToolbar)
                }
                .overlay(alignment: .top) {
                    if showToolbar {
                        PerformanceToolbar(
                            onExit: { dismiss() },
                            onToggleSidebar: {
                                withAnimation { showSidebar.toggle() }
                            }
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .overlay(alignment: .topLeading) {
                    // Accessibility landmark marking the content area bounds.
                    // Used by VoiceOver and UI tests to determine the tap zone layout.
                    Color.clear
                        .frame(width: geo.size.width, height: geo.size.height)
                        .accessibilityElement()
                        .accessibilityIdentifier("performance-content-area")
                        .accessibilityLabel("Performance content")
                        .allowsHitTesting(false)
                }
                .onAppear {
                    safeAreaInsets = geo.safeAreaInsets
                    viewportHeight =
                        geo.size.height + safeAreaInsets.top
                        + safeAreaInsets.bottom
                    if geo.size.width >= Self.autoSidebarThreshold {
                        showSidebar = true
                    }
                    if let first = nextNavigableIndex(after: -1) {
                        activeIndex = first
                    }
                }
                .onChange(of: geo.size) { _, newSize in
                    safeAreaInsets = geo.safeAreaInsets
                    viewportHeight =
                        newSize.height + safeAreaInsets.top
                        + safeAreaInsets.bottom

                    DispatchQueue.main.async {
                        if let frame = entryFrames[activeIndex] {
                            withAnimation(.easeInOut(duration: PerformanceTheme.navigationAnimationDuration)) {
                                scrollPosition.scrollTo(y: max(0, frame.minY))
                            }
                        }
                    }
                }
        }
        .inspector(isPresented: $showSidebar) {
            PerformanceSetlistSidebar(
                title: source.performanceTitle,
                items: items,
                activeIndex: activeIndex,
                onSelect: { index in navigateTo(index: index) },
                onPrevious: { navigateToPrevious() },
                onNext: { navigateToNext() }
            )
            .inspectorColumnWidth(min: PerformanceTheme.inspectorColumnWidthMin, ideal: PerformanceTheme.inspectorColumnWidthIdeal, max: PerformanceTheme.inspectorColumnWidthMax)
        }
        .background(PerformanceTheme.background)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    // MARK: - Scroll content

    @ViewBuilder
    private func scrollContent(viewportSize: CGSize) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) {
                    index,
                    item in
                    itemView(item: item)
                        .padding(.horizontal, PerformanceTheme.itemHorizontalPadding)
                        .opacity(opacityFor(index: index))
                        .animation(
                            .easeInOut(duration: PerformanceTheme.dimmingAnimationDuration),
                            value: activeIndex
                        )
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("performance-entry-\(index)")
                        .accessibilityLabel(
                            index == activeIndex
                                ? "Active: \(item.title)" : item.title
                        )
                        .background(
                            GeometryReader { entryGeo in
                                Color.clear.preference(
                                    key: EntryFrameKey.self,
                                    value: [
                                        index: entryGeo.frame(
                                            in: .named("perfContent")
                                        )
                                    ]
                                )
                            }
                        )
                        .id(index)
                }
            }
            .coordinateSpace(name: "perfContent")
            .padding(.top, 0)
            .padding(.bottom, 0)
            .background(
                PerformanceTapOverlay(
                    contentWidth: viewportSize.width,
                    onLeftTap: { handleLeftTap() },
                    onRightTap: { handleRightTap() },
                    onCenterTap: { toggleToolbar() }
                )
            )
        }

        //
        .scrollPosition($scrollPosition)
        .onPreferenceChange(EntryFrameKey.self) { entryFrames = $0 }
        .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentOffset.y }) {
            _,
            y in
            scrollOffset = y + safeAreaInsets.top
            syncActiveIndexToViewportIfNeeded()
        }
    }

    // MARK: - Scroll indicators (up/down chevrons)

    private var canScrollDown: Bool {
        guard navMode.showsChevrons else { return false }
        return PerformanceScrollCalculator.canScrollDown(
            activeEntryFrame: entryFrames[activeIndex],
            scrollOffset: scrollOffset,
            viewportHeight: viewportHeight,
            overlap: safeAreaInsets.top
        )
    }

    private var canScrollUp: Bool {
        guard navMode.showsChevrons else { return false }
        return PerformanceScrollCalculator.canScrollUp(
            activeEntryFrame: entryFrames[activeIndex],
            scrollOffset: scrollOffset,
            viewportHeight: viewportHeight,
            overlap: safeAreaInsets.bottom
        )
    }

    @ViewBuilder
    private var scrollIndicators: some View {
        ZStack {
            if canScrollDown {
                VStack {
                    Spacer()
                    Button {
                        scrollActiveEntryDown()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.title)
                            .fontWeight(.semibold)
                            .frame(width: 72, height: 72)
                            .contentShape(Circle())
                            .glassEffect(.regular.interactive(), in: .circle)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Scroll down")
                    .accessibilityIdentifier("scroll-down-chevron")
                    .padding(.bottom, PerformanceTheme.chevronEdgePadding)
                }
                .transition(.opacity)
            }

            if canScrollUp {
                VStack {
                    Button {
                        scrollActiveEntryUp()
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.title)
                            .fontWeight(.semibold)
                            .frame(width: 72, height: 72)
                            .contentShape(Circle())
                            .glassEffect(.regular.interactive(), in: .circle)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Scroll up")
                    .accessibilityIdentifier("scroll-up-chevron")
                    .padding(.top, PerformanceTheme.chevronEdgePadding)
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: PerformanceTheme.chevronFadeAnimationDuration), value: canScrollDown)
        .animation(.easeInOut(duration: PerformanceTheme.chevronFadeAnimationDuration), value: canScrollUp)
    }

    // MARK: - Item rendering

    @ViewBuilder
    private func itemView(item: PerformanceItem) -> some View {
        switch item.kind {
        case .song:
            if let song = item.song {
                SongPerformanceBlock(song: song, medleyTitle: item.medleyTitle)
            }
        case .tacet:
            if let tacet = item.tacet {
                TacetPerformanceBlock(tacet: tacet)
            }
        case .medley:
            if let medley = item.medley {
                MedleyPerformanceBlock(medley: medley)
            }
        }
    }

    // MARK: - Dimming

    private func opacityFor(index: Int) -> Double {
        if navMode == .screenNavigation { return 1.0 }
        if index == activeIndex { return 1.0 }
        return PerformanceTheme.inactiveItemOpacity
    }

    // MARK: - Entry navigation (left/right taps)

    private func nextNavigableIndex(after index: Int) -> Int? {
        var i = index + 1
        while i < items.count {
            if !items[i].isSkippable { return i }
            i += 1
        }
        return nil
    }

    private func previousNavigableIndex(before index: Int) -> Int? {
        var i = index - 1
        while i >= 0 {
            if !items[i].isSkippable { return i }
            i -= 1
        }
        return nil
    }

    private func navigateToNext() {
        if let idx = nextNavigableIndex(after: activeIndex) {
            navigateTo(index: idx)
        }
    }

    private func navigateToPrevious() {
        if let idx = previousNavigableIndex(before: activeIndex) {
            navigateTo(index: idx)
        }
    }

    private func navigateTo(index: Int) {
        activeIndex = index
        if let frame = entryFrames[index] {
            withAnimation(.easeInOut(duration: PerformanceTheme.navigationAnimationDuration)) {
                scrollPosition.scrollTo(y: max(0, frame.minY))
            }
        }
    }

    // MARK: - Simple-mode sidebar highlight sync

    /// In simple mode the user scrolls freely with no song-level active index,
    /// so update `activeIndex` from scroll position to keep the sidebar highlight
    /// in sync with what's visible. Other modes manage `activeIndex` themselves.
    private func syncActiveIndexToViewportIfNeeded() {
        guard navMode == .screenNavigation else { return }
        let viewportTop = scrollOffset
        let viewportBottom = scrollOffset + viewportHeight
        let visible = entryFrames
            .filter { index, frame in
                frame.maxY > viewportTop
                    && frame.minY < viewportBottom
                    && items.indices.contains(index)
                    && !items[index].isSkippable
            }
            .sorted { $0.key < $1.key }

        guard !visible.isEmpty else { return }

        let candidate: Int?
        if visible.count == 1 {
            candidate = visible[0].key
        } else {
            // Multiple entries on screen: activate the first whose title (top edge) is visible.
            candidate = visible.first(where: { _, frame in frame.minY >= viewportTop })?.key
        }

        if let candidate, candidate != activeIndex {
            activeIndex = candidate
        }
    }

    // MARK: - Tap dispatch (per navigation mode)

    private func handleLeftTap() {
        switch navMode {
        case .screenNavigation: scrollViewportBy(direction: .backward)
        case .songNavigation: navigateToPrevious()
        case .smartNavigation: handleNavigatorTap(.backward)
        }
    }

    private func handleRightTap() {
        switch navMode {
        case .screenNavigation: scrollViewportBy(direction: .forward)
        case .songNavigation: navigateToNext()
        case .smartNavigation: handleNavigatorTap(.forward)
        }
    }

    private func scrollViewportBy(direction: TapDirection) {
        let step = viewportHeight
        let delta = direction == .forward ? step : -step
        let target = max(0, scrollOffset + delta)
        withAnimation(.easeInOut(duration: PerformanceTheme.navigationAnimationDuration)) {
            scrollPosition.scrollTo(y: target)
        }
    }

    // MARK: - Two-phase tap navigation (PerformanceNavigator)

    private func handleNavigatorTap(_ direction: TapDirection) {
        guard let frame = entryFrames[activeIndex] else {
            // Fall back to simple entry navigation if frame not yet measured.
            direction == .forward ? navigateToNext() : navigateToPrevious()
            return
        }

        let overlap = direction == .forward ? safeAreaInsets.top : safeAreaInsets.bottom

        let result = PerformanceNavigator.handleTap(
            direction: direction,
            activeIndex: activeIndex,
            entryCount: items.count,
            activeEntryFrame: frame,
            scrollOffset: scrollOffset,
            viewportHeight: viewportHeight,
            overlap: overlap
        )

        if result.newActiveIndex != activeIndex {
            // Respect skippable entries by stepping onward if navigator picked one.
            if items.indices.contains(result.newActiveIndex),
               items[result.newActiveIndex].isSkippable {
                direction == .forward ? navigateToNext() : navigateToPrevious()
            } else if direction == .backward,
                      let prevFrame = entryFrames[result.newActiveIndex] {
                // Going back: land on the previous entry's last snap (near-bottom),
                // mirroring how scrolling up through it would end.
                activeIndex = result.newActiveIndex
                let snaps = PerformanceScrollCalculator.inEntrySnaps(
                    for: prevFrame,
                    viewportHeight: viewportHeight
                )
                let target = snaps.last ?? prevFrame.minY
                withAnimation(.easeInOut(duration: PerformanceTheme.navigationAnimationDuration)) {
                    scrollPosition.scrollTo(y: max(0, target))
                }
            } else {
                navigateTo(index: result.newActiveIndex)
            }
            return
        }

        if let target = result.scrollTarget {
            withAnimation(.easeInOut(duration: PerformanceTheme.navigationAnimationDuration)) {
                scrollPosition.scrollTo(y: max(0, target))
            }
        }
    }

    // MARK: - Toolbar

    private func toggleToolbar() {
        withAnimation(.easeInOut(duration: PerformanceTheme.navigationAnimationDuration)) {
            showToolbar.toggle()
        }
    }

    // MARK: - Within-entry scrolling (up/down chevrons)

    private func scrollActiveEntryDown() {
        guard let frame = entryFrames[activeIndex] else { return }
        guard
            let target = PerformanceScrollCalculator.nextSnapDown(
                activeEntryFrame: frame,
                scrollOffset: scrollOffset,
                viewportHeight: viewportHeight
            )
        else { return }
        withAnimation(.easeInOut(duration: PerformanceTheme.navigationAnimationDuration)) {
            scrollPosition.scrollTo(y: max(0, target))
        }
    }

    private func scrollActiveEntryUp() {
        guard let frame = entryFrames[activeIndex] else { return }
        guard
            let target = PerformanceScrollCalculator.nextSnapUp(
                activeEntryFrame: frame,
                scrollOffset: scrollOffset,
                viewportHeight: viewportHeight
            )
        else { return }
        withAnimation(.easeInOut(duration: PerformanceTheme.navigationAnimationDuration)) {
            scrollPosition.scrollTo(y: max(0, target))
        }
    }

}
