import SwiftUI
import LeadifyCore

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
    @State private var smartState = SmartNavigationState()
    @FocusState private var isFocused: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
        .modifier(PerformanceSidebarPresentation(
            isPresented: $showSidebar,
            title: source.performanceTitle,
            items: items,
            activeIndex: activeIndex,
            showsActiveHighlight: navMode != .screenNavigation,
            onSelect: { index in
                smartState.backStack = []
                navigateTo(index: index)
                computeSmartNextTarget()
            },
            onPrevious: { navigateToPrevious() },
            onNext: { navigateToNext() }
        ))
        .background(PerformanceTheme.background)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .onAppear { isFocused = true }
        .onKeyPress(.downArrow) { handleRightTap(); return .handled }
        .onKeyPress(.upArrow) { handleLeftTap(); return .handled }
    }

    // MARK: - Scroll content

    @ViewBuilder
    private func scrollContent(viewportSize: CGSize) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) {
                    index,
                    item in
                    VStack(alignment: .leading, spacing: 0) {
                        if let medleyTitle = item.medleyTitle {
                            let m = PerformanceTheme.metrics(for: horizontalSizeClass)
                            Text(medleyTitle)
                                .font(.system(size: m.medleyTitleSize, weight: .semibold, design: .rounded))
                                .foregroundStyle(PerformanceTheme.medleyIndicatorColor)
                                .padding(.top, m.itemInnerVerticalPadding)
                                .padding(.bottom, PerformanceTheme.medleyTitleBottomPadding)
                                .padding(.horizontal, m.itemHorizontalPadding)
                        }

                        itemView(item: item)
                            .padding(.horizontal, PerformanceTheme.metrics(for: horizontalSizeClass).itemHorizontalPadding)
                            .overlay(alignment: .topLeading) {
                                if index == activeIndex, navMode != .smartNavigation, navMode != .screenNavigation {
                                    activeIndicator(item: item)
                                }
                            }
                    }
                    .animation(.easeInOut(duration: 0.2), value: activeIndex)
                    .animation(.easeInOut(duration: 0.2), value: smartState.nextTargetIndex)
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
        .onPreferenceChange(EntryFrameKey.self) {
            entryFrames = $0
            computeSmartNextTarget()
        }
        .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentOffset.y }) {
            _,
            y in
            scrollOffset = y + safeAreaInsets.top
            dismissToolbar()
            syncActiveIndexToViewportIfNeeded()
        }
        .onChange(of: storedNavMode) {
            smartState.backStack = []
            computeSmartNextTarget()
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
                SongPerformanceBlock(song: song)
            }
        case .tacet:
            if let tacet = item.tacet {
                TacetPerformanceBlock(tacet: tacet)
            }
        case .medley:
            if let medley = item.medley {
                MedleyPerformanceBlock(medley: medley)
            }
        @unknown default:
            EmptyView()
        }
    }

    // MARK: - Active indicator

    @ViewBuilder
    private func activeIndicator(item: PerformanceItem) -> some View {
        let m = PerformanceTheme.metrics(for: horizontalSizeClass)
        Image(systemName: "triangle.fill")
            .font(.system(size: m.activeIndicatorSize))
            .foregroundStyle(PerformanceTheme.activeIndicatorColor)
            .rotationEffect(.degrees(90))
            .offset(
                x: m.activeIndicatorLeadingOffset,
                y: m.activeIndicatorTopPadding
                    + (item.kind == .medley ? -4 : 0)
            )
    }

    @ViewBuilder
    private func nextTargetIndicator(item: PerformanceItem) -> some View {
        let m = PerformanceTheme.metrics(for: horizontalSizeClass)
        Image(systemName: "triangle.fill")
            .font(.system(size: m.activeIndicatorSize))
            .foregroundStyle(PerformanceTheme.nextIndicatorColor)
            .rotationEffect(.degrees(90))
            .offset(
                x: m.activeIndicatorLeadingOffset,
                y: m.activeIndicatorTopPadding
                    + (item.kind == .medley ? -4 : 0)
            )
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
        case .chevronNavigation: navigateToPrevious()
        case .songNavigation: handleNavigatorTap(.backward)
        case .smartNavigation: handleSmartBack()
        @unknown default: break
        }
    }

    private func handleRightTap() {
        switch navMode {
        case .screenNavigation: scrollViewportBy(direction: .forward)
        case .chevronNavigation: navigateToNext()
        case .songNavigation: handleNavigatorTap(.forward)
        case .smartNavigation: handleSmartForward()
        @unknown default: break
        }
    }

    private func scrollViewportBy(direction: TapDirection) {
        let target = ScreenNavigator.handleTap(
            direction: direction,
            scrollOffset: scrollOffset,
            viewportHeight: viewportHeight
        )
        withAnimation(.easeInOut(duration: PerformanceTheme.navigationAnimationDuration)) {
            scrollPosition.scrollTo(y: target)
        }
    }

    // MARK: - Two-phase tap navigation (SongNavigator)

    private func handleNavigatorTap(_ direction: TapDirection) {
        guard let frame = entryFrames[activeIndex] else {
            direction == .forward ? navigateToNext() : navigateToPrevious()
            return
        }

        let overlap = direction == .forward ? safeAreaInsets.top : safeAreaInsets.bottom

        let result = SongNavigator.handleTap(
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

    // MARK: - Smart navigation

    private func computeSmartNextTarget() {
        guard navMode == .smartNavigation else {
            smartState.nextTargetIndex = nil
            return
        }
        smartState.nextTargetIndex = SmartNavigator.computeNextTarget(
            activeIndex: activeIndex,
            entryFrames: entryFrames,
            entryCount: items.count,
            isSkippable: { items[$0].isSkippable },
            viewportHeight: viewportHeight
        )
    }

    private func handleSmartForward() {
        guard let frame = entryFrames[activeIndex] else { return }

        let result = SmartNavigator.handleForward(
            state: &smartState,
            activeIndex: activeIndex,
            activeEntryFrame: frame,
            scrollOffset: scrollOffset,
            viewportHeight: viewportHeight,
            overlap: safeAreaInsets.top
        )

        switch result {
        case .scrollWithin(let target):
            withAnimation(.easeInOut(duration: PerformanceTheme.navigationAnimationDuration)) {
                scrollPosition.scrollTo(y: max(0, target))
            }
        case .jumpTo(let index):
            navigateTo(index: index)
            computeSmartNextTarget()
        case .none:
            break
        @unknown default:
            break
        }
    }

    private func handleSmartBack() {
        guard let frame = entryFrames[activeIndex] else { return }

        let result = SmartNavigator.handleBack(
            state: &smartState,
            activeIndex: activeIndex,
            activeEntryFrame: frame,
            scrollOffset: scrollOffset,
            viewportHeight: viewportHeight,
            overlap: safeAreaInsets.bottom,
            previousNavigableIndex: previousNavigableIndex(before: activeIndex)
        )

        switch result {
        case .scrollWithin(let target):
            withAnimation(.easeInOut(duration: PerformanceTheme.navigationAnimationDuration)) {
                scrollPosition.scrollTo(y: max(0, target))
            }
        case .jumpTo(let index):
            activeIndex = index
            if let prevFrame = entryFrames[index] {
                let snaps = PerformanceScrollCalculator.inEntrySnaps(
                    for: prevFrame,
                    viewportHeight: viewportHeight
                )
                let target = snaps.last ?? prevFrame.minY
                withAnimation(.easeInOut(duration: PerformanceTheme.navigationAnimationDuration)) {
                    scrollPosition.scrollTo(y: max(0, target))
                }
            }
            computeSmartNextTarget()
        case .none:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Toolbar

    private func toggleToolbar() {
        withAnimation(.easeInOut(duration: PerformanceTheme.navigationAnimationDuration)) {
            showToolbar.toggle()
        }
    }

    private func dismissToolbar() {
        guard showToolbar else { return }
        withAnimation(.easeInOut(duration: PerformanceTheme.navigationAnimationDuration)) {
            showToolbar = false
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

private struct PerformanceSidebarPresentation: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let items: [PerformanceItem]
    let activeIndex: Int
    let showsActiveHighlight: Bool
    let onSelect: (Int) -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func body(content: Content) -> some View {
        if horizontalSizeClass == .compact {
            content
                .sheet(isPresented: $isPresented) {
                    NavigationStack {
                        PerformanceSetlistSidebar(
                            title: title,
                            items: items,
                            activeIndex: activeIndex,
                            showsActiveHighlight: showsActiveHighlight,
                            onSelect: onSelect,
                            onPrevious: onPrevious,
                            onNext: onNext,
                            showNavigationButtons: false,
                            showTitle: false
                        )
                        .navigationTitle(title)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { isPresented = false }
                            }
                        }
                    }
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
        } else {
            content
                .inspector(isPresented: $isPresented) {
                    PerformanceSetlistSidebar(
                        title: title,
                        items: items,
                        activeIndex: activeIndex,
                        showsActiveHighlight: showsActiveHighlight,
                        onSelect: onSelect,
                        onPrevious: onPrevious,
                        onNext: onNext
                    )
                    .inspectorColumnWidth(min: PerformanceTheme.inspectorColumnWidthMin, ideal: PerformanceTheme.inspectorColumnWidthIdeal, max: PerformanceTheme.inspectorColumnWidthMax)
                }
        }
    }
}
