import CoreGraphics

enum TapDirection {
    case forward
    case backward
}

struct NavigationResult {
    let newActiveIndex: Int
    let scrollTarget: CGFloat?
}

/// Pure-logic helper for the two-phase ForScore-style tap navigation.
///
/// Frames are in absolute scroll-content coordinates (same convention as
/// `PerformanceScrollCalculator`). Phase 1 (scroll-within) is delegated to the
/// calculator so tap steps match chevron steps exactly, including the
/// `dividerHeight` trim on `frame.maxY` and sub-pixel tolerances.
enum SongNavigator {
    static func handleTap(
        direction: TapDirection,
        activeIndex: Int,
        entryCount: Int,
        activeEntryFrame: CGRect,
        scrollOffset: CGFloat,
        viewportHeight: CGFloat,
        overlap: CGFloat = 0
    ) -> NavigationResult {
        switch direction {
        case .forward:
            return handleForward(
                activeIndex: activeIndex,
                entryCount: entryCount,
                activeEntryFrame: activeEntryFrame,
                scrollOffset: scrollOffset,
                viewportHeight: viewportHeight,
                overlap: overlap
            )
        case .backward:
            return handleBackward(
                activeIndex: activeIndex,
                activeEntryFrame: activeEntryFrame,
                scrollOffset: scrollOffset,
                viewportHeight: viewportHeight,
                overlap: overlap
            )
        }
    }

    private static func handleForward(
        activeIndex: Int,
        entryCount: Int,
        activeEntryFrame: CGRect,
        scrollOffset: CGFloat,
        viewportHeight: CGFloat,
        overlap: CGFloat
    ) -> NavigationResult {
        if PerformanceScrollCalculator.canScrollDown(
            activeEntryFrame: activeEntryFrame,
            scrollOffset: scrollOffset,
            viewportHeight: viewportHeight,
            overlap: overlap
        ),
            let target = PerformanceScrollCalculator.nextSnapDown(
                activeEntryFrame: activeEntryFrame,
                scrollOffset: scrollOffset,
                viewportHeight: viewportHeight
            )
        {
            return NavigationResult(newActiveIndex: activeIndex, scrollTarget: target)
        }

        if activeIndex < entryCount - 1 {
            return NavigationResult(newActiveIndex: activeIndex + 1, scrollTarget: nil)
        }

        return NavigationResult(newActiveIndex: activeIndex, scrollTarget: nil)
    }

    private static func handleBackward(
        activeIndex: Int,
        activeEntryFrame: CGRect,
        scrollOffset: CGFloat,
        viewportHeight: CGFloat,
        overlap: CGFloat
    ) -> NavigationResult {
        if PerformanceScrollCalculator.canScrollUp(
            activeEntryFrame: activeEntryFrame,
            scrollOffset: scrollOffset,
            viewportHeight: viewportHeight,
            overlap: overlap
        ),
            let target = PerformanceScrollCalculator.nextSnapUp(
                activeEntryFrame: activeEntryFrame,
                scrollOffset: scrollOffset,
                viewportHeight: viewportHeight
            )
        {
            return NavigationResult(newActiveIndex: activeIndex, scrollTarget: target)
        }

        if activeIndex > 0 {
            return NavigationResult(newActiveIndex: activeIndex - 1, scrollTarget: nil)
        }

        return NavigationResult(newActiveIndex: activeIndex, scrollTarget: nil)
    }
}
