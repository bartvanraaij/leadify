import CoreGraphics

struct SmartNavigationState {
    var backStack: [Int] = []
    var nextTargetIndex: Int? = nil
}

enum SmartNavigator {
    static func computeNextTarget(
        activeIndex: Int,
        entryFrames: [Int: CGRect],
        entryCount: Int,
        isSkippable: (Int) -> Bool,
        viewportHeight: CGFloat
    ) -> Int? {
        guard let activeFrame = entryFrames[activeIndex] else { return nil }
        let viewportBottom = activeFrame.minY + viewportHeight
        var i = activeIndex + 1
        while i < entryCount {
            if !isSkippable(i) {
                if let frame = entryFrames[i], frame.maxY > viewportBottom + 1 {
                    return i
                }
            }
            i += 1
        }
        return nil
    }

    static func handleForward(
        state: inout SmartNavigationState,
        activeIndex: Int,
        activeEntryFrame: CGRect,
        scrollOffset: CGFloat,
        viewportHeight: CGFloat,
        overlap: CGFloat
    ) -> SmartForwardResult {
        if PerformanceScrollCalculator.canScrollDown(
            activeEntryFrame: activeEntryFrame,
            scrollOffset: scrollOffset,
            viewportHeight: viewportHeight,
            overlap: overlap
        ),
            let snapTarget = PerformanceScrollCalculator.nextSnapDown(
                activeEntryFrame: activeEntryFrame,
                scrollOffset: scrollOffset,
                viewportHeight: viewportHeight
            )
        {
            return .scrollWithin(target: snapTarget)
        }

        guard let target = state.nextTargetIndex else { return .none }
        state.backStack.append(activeIndex)
        return .jumpTo(index: target)
    }

    static func handleBack(
        state: inout SmartNavigationState,
        activeIndex: Int,
        activeEntryFrame: CGRect,
        scrollOffset: CGFloat,
        viewportHeight: CGFloat,
        overlap: CGFloat,
        previousNavigableIndex: Int?
    ) -> SmartBackResult {
        if PerformanceScrollCalculator.canScrollUp(
            activeEntryFrame: activeEntryFrame,
            scrollOffset: scrollOffset,
            viewportHeight: viewportHeight,
            overlap: overlap
        ),
            let snapTarget = PerformanceScrollCalculator.nextSnapUp(
                activeEntryFrame: activeEntryFrame,
                scrollOffset: scrollOffset,
                viewportHeight: viewportHeight
            )
        {
            return .scrollWithin(target: snapTarget)
        }

        guard let previous = state.backStack.popLast() ?? previousNavigableIndex else {
            return .none
        }
        return .jumpTo(index: previous)
    }
}

enum SmartForwardResult: Equatable {
    case scrollWithin(target: CGFloat)
    case jumpTo(index: Int)
    case none
}

enum SmartBackResult: Equatable {
    case scrollWithin(target: CGFloat)
    case jumpTo(index: Int)
    case none
}
