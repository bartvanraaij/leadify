import CoreGraphics

enum TapDirection {
    case forward
    case backward
}

struct NavigationResult {
    let newActiveIndex: Int
    /// If non-nil, scroll to this absolute Y offset. If nil, scroll to the new active entry's anchor.
    let scrollTarget: CGFloat?
}

/// Pure-logic helper for the two-phase ForScore-style tap navigation.
/// All frames are in the scroll view's coordinate space relative to the viewport.
enum PerformanceNavigator {
    private static let scrollFraction: CGFloat = 0.6

    static func handleTap(
        direction: TapDirection,
        activeIndex: Int,
        entryCount: Int,
        activeEntryFrame: CGRect,
        viewportHeight: CGFloat,
        scrollOffset: CGFloat
    ) -> NavigationResult {
        switch direction {
        case .forward:
            return handleForward(
                activeIndex: activeIndex,
                entryCount: entryCount,
                activeEntryFrame: activeEntryFrame,
                viewportHeight: viewportHeight,
                scrollOffset: scrollOffset
            )
        case .backward:
            return handleBackward(
                activeIndex: activeIndex,
                activeEntryFrame: activeEntryFrame,
                viewportHeight: viewportHeight,
                scrollOffset: scrollOffset
            )
        }
    }

    private static func handleForward(
        activeIndex: Int,
        entryCount: Int,
        activeEntryFrame: CGRect,
        viewportHeight: CGFloat,
        scrollOffset: CGFloat
    ) -> NavigationResult {
        let entryBottom = activeEntryFrame.maxY
        let viewportBottom = viewportHeight

        // Phase 1: entry extends below viewport — scroll within
        if entryBottom > viewportBottom + 1 {
            let target = scrollOffset + viewportHeight * scrollFraction
            return NavigationResult(newActiveIndex: activeIndex, scrollTarget: target)
        }

        // Phase 2: entry bottom visible — advance to next (if not last)
        if activeIndex < entryCount - 1 {
            return NavigationResult(newActiveIndex: activeIndex + 1, scrollTarget: nil)
        }

        // Already at last entry and fully visible — do nothing
        return NavigationResult(newActiveIndex: activeIndex, scrollTarget: nil)
    }

    private static func handleBackward(
        activeIndex: Int,
        activeEntryFrame: CGRect,
        viewportHeight: CGFloat,
        scrollOffset: CGFloat
    ) -> NavigationResult {
        let entryTop = activeEntryFrame.minY

        // Phase 1: entry extends above viewport — scroll within
        if entryTop < -1 {
            let target = max(0, scrollOffset - viewportHeight * scrollFraction)
            return NavigationResult(newActiveIndex: activeIndex, scrollTarget: target)
        }

        // Phase 2: entry top visible — go to previous (if not first)
        if activeIndex > 0 {
            return NavigationResult(newActiveIndex: activeIndex - 1, scrollTarget: nil)
        }

        // Already at first entry and top visible — do nothing
        return NavigationResult(newActiveIndex: activeIndex, scrollTarget: nil)
    }
}
