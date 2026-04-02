import SwiftUI

/// Preference key to collect entry frames (in the scroll content's coordinate space).
private struct EntryFrameKey: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
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

    private var items: [PerformanceItem] { source.performanceItems }
    private static let scrollOvershoot: CGFloat = 40
    private static let autoSidebarThreshold: CGFloat = 900

    var body: some View {
        GeometryReader { geo in
            scrollContent(viewportSize: geo.size)
                .overlay { scrollIndicators }
                .overlay(alignment: .topLeading) { closeButton }
                .onAppear {
                    viewportHeight = geo.size.height
                    if geo.size.width >= Self.autoSidebarThreshold {
                        showSidebar = true
                    }
                    if let first = nextNavigableIndex(after: -1) {
                        activeIndex = first
                    }
                }
                .onChange(of: geo.size) { _, newSize in
                    viewportHeight = newSize.height
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let frame = entryFrames[activeIndex] {
                            let contentY = frame.minY + scrollOffset + Self.scrollOvershoot
                            withAnimation(.easeInOut(duration: 0.25)) {
                                scrollPosition.scrollTo(y: max(0, contentY))
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
            .inspectorColumnWidth(min: 220, ideal: 280, max: 380)
        }
        .overlay(alignment: .topTrailing) { sidebarToggleButton }
        .background(PerformanceTheme.background.ignoresSafeArea())
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    // MARK: - Scroll content

    @ViewBuilder
    private func scrollContent(viewportSize: CGSize) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    itemView(item: item)
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
            .padding(.top, 0)
            .padding(.bottom, 80)
            .background(
                PerformanceTapOverlay(
                    onLeftTap: { navigateToPrevious() },
                    onRightTap: { navigateToNext() },
                    onCenterTap: { tapY in activateEntryAt(viewportY: tapY) }
                )
            )
        }
        .coordinateSpace(name: "perfScroll")
        .scrollPosition($scrollPosition)
        .onPreferenceChange(EntryFrameKey.self) { entryFrames = $0 }
        .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentOffset.y }) { _, y in
            scrollOffset = y
        }
    }

    // MARK: - Scroll indicators (up/down chevrons)

    private var canScrollDown: Bool {
        guard let frame = entryFrames[activeIndex] else { return false }
        let entryBottomInContent = frame.maxY + scrollOffset
        return entryBottomInContent > scrollOffset + viewportHeight + 5
    }

    private var canScrollUp: Bool {
        guard let frame = entryFrames[activeIndex] else { return false }
        let entryTopTarget = frame.minY + scrollOffset + Self.scrollOvershoot
        return scrollOffset > entryTopTarget + 5
    }

    @ViewBuilder
    private var scrollIndicators: some View {
        ZStack {
            if canScrollDown {
                VStack {
                    Spacer()
                    Button { scrollActiveEntryDown() } label: {
                        Image(systemName: "chevron.compact.down")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 80, height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.black.opacity(0.25))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 24)
                }
                .transition(.opacity)
            }

            if canScrollUp {
                VStack {
                    Button { scrollActiveEntryUp() } label: {
                        Image(systemName: "chevron.compact.up")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 80, height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.black.opacity(0.25))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 24)
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: canScrollDown)
        .animation(.easeInOut(duration: 0.2), value: canScrollUp)
    }

    // MARK: - Item rendering

    @ViewBuilder
    private func itemView(item: PerformanceItem) -> some View {
        switch item.kind {
        case .song:
            SongPerformanceBlock(song: item.song!)
        case .tacet:
            TacetPerformanceBlock(tacet: item.tacet!)
        case .medley:
            if let medley = item.medley {
                MedleyPerformanceBlock(medley: medley)
            }
        }
    }

    // MARK: - Dimming

    private func opacityFor(index: Int) -> Double {
        if index == activeIndex { return 1.0 }
        return 0.5
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
            let contentY = frame.minY + scrollOffset + Self.scrollOvershoot
            withAnimation(.easeInOut(duration: 0.25)) {
                scrollPosition.scrollTo(y: max(0, contentY))
            }
        }
    }

    // MARK: - Tap-to-activate (center zone)

    private func activateEntryAt(viewportY contentY: CGFloat) {
        let viewportY = contentY - scrollOffset
        for (index, frame) in entryFrames {
            if viewportY >= frame.minY && viewportY <= frame.maxY {
                if index != activeIndex && !items[index].isSkippable {
                    navigateTo(index: index)
                }
                return
            }
        }
    }

    // MARK: - Within-entry scrolling (up/down chevrons)

    private func scrollActiveEntryDown() {
        guard let frame = entryFrames[activeIndex] else { return }
        let entryBottomInContent = frame.maxY + scrollOffset
        let remainingBelow = entryBottomInContent - (scrollOffset + viewportHeight)

        let targetY: CGFloat
        if remainingBelow > viewportHeight {
            targetY = scrollOffset + viewportHeight
        } else {
            targetY = entryBottomInContent - viewportHeight + Self.scrollOvershoot
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            scrollPosition.scrollTo(y: max(0, targetY))
        }
    }

    private func scrollActiveEntryUp() {
        guard let frame = entryFrames[activeIndex] else { return }
        let entryTopTarget = frame.minY + scrollOffset + Self.scrollOvershoot
        let amountAbove = scrollOffset - entryTopTarget

        let targetY: CGFloat
        if amountAbove > viewportHeight {
            targetY = scrollOffset - viewportHeight
        } else {
            targetY = entryTopTarget
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            scrollPosition.scrollTo(y: max(0, targetY))
        }
    }

    // MARK: - Toolbar buttons

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)
        }
        .buttonStyle(.plain)
        .padding(.top, 12)
        .padding(.horizontal, 16)
    }

    private var sidebarToggleButton: some View {
        Button {
            withAnimation {
                showSidebar.toggle()
            }
        } label: {
            Image(systemName: "list.bullet.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)
        }
        .buttonStyle(.plain)
        .padding(.top, 12)
        .padding(.horizontal, 16)
    }
}
