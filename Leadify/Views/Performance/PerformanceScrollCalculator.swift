import CoreGraphics
import UIKit

/// Pure-logic helper for within-entry scroll calculations (chevron up/down).
/// Extracted from PerformanceView so the math can be unit tested independently.
enum PerformanceScrollCalculator {
    

    /// Ordered snap positions for within-entry scrolling, anchored at the entry top.
    /// Full steps of (viewportHeight - overlap) from frame.minY, with the final step
    /// landing at lastSnap (the near-bottom position).
    static func inEntrySnaps(for frame: CGRect, viewportHeight: CGFloat)
        -> [CGFloat]
    {
        let workingFrameMaxY = frame.maxY - PerformanceTheme.dividerHeight
        let step = viewportHeight
        let lastSnap = workingFrameMaxY - viewportHeight

        guard lastSnap > frame.minY + 1, step > 0 else { return [frame.minY] }

        var snaps: [CGFloat] = []
        var pos = frame.minY
        while pos < lastSnap - 1 {
            snaps.append(pos)
            pos += step
        }

        snaps.append(lastSnap)
        return snaps
    }
    
    static func isWithinTolerance(_ a: CGFloat, _ b: CGFloat, _ tolerance: CGFloat = 1) -> Bool {
        abs(a - b) <= tolerance
    }
    
    static func isOutsideTolerance(_ a: CGFloat, _ b: CGFloat, _ tolerance: CGFloat = 1) -> Bool {
        abs(a - b) >= tolerance
    }

    /// Whether the active entry's bottom extends below the visible viewport.
    static func canScrollDown(
        activeEntryFrame frame: CGRect?,
        scrollOffset: CGFloat,
        viewportHeight: CGFloat,
        overlap: CGFloat = 0
    ) -> Bool {
        guard let frame else { return false }

  
        let entryIsInView = scrollOffset >= frame.minY || isWithinTolerance(scrollOffset, frame.minY, 2)

        if entryIsInView == false { return false }
        
        let workingFrameMaxY = frame.maxY - PerformanceTheme.dividerHeight

        let hasRemainingPixelsBelowViewport =
        workingFrameMaxY
            - (scrollOffset + viewportHeight
                 + overlap) >= 1

        return hasRemainingPixelsBelowViewport
    }

    /// Whether the active entry's top extends above the visible viewport.
    static func canScrollUp(
        activeEntryFrame frame: CGRect?,
        scrollOffset: CGFloat,
        viewportHeight: CGFloat,
        overlap: CGFloat = 0
    ) -> Bool {
        guard let frame else { return false }
        let lastSnap = frame.maxY - viewportHeight + overlap
        guard scrollOffset <= lastSnap
        else { return false }
        return scrollOffset > frame.minY
            + overlap
    }

    /// Returns the next snap position below the current scroll offset, or nil if already at bottom.
    static func nextSnapDown(
        activeEntryFrame frame: CGRect,
        scrollOffset: CGFloat,
        viewportHeight: CGFloat,
    ) -> CGFloat? {
        let snaps = inEntrySnaps(for: frame, viewportHeight: viewportHeight)
        return snaps.first(where: { $0 > scrollOffset + 1 })
    }

    /// Returns the next snap position above the current scroll offset, or nil if already at top.
    static func nextSnapUp(
        activeEntryFrame frame: CGRect,
        scrollOffset: CGFloat,
        viewportHeight: CGFloat
    ) -> CGFloat? {
        let snaps = inEntrySnaps(for: frame, viewportHeight: viewportHeight)
        return snaps.last(where: { $0 < scrollOffset - 1 })
    }
}
