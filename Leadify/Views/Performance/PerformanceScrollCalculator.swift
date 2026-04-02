import CoreGraphics

/// Pure-logic helper for within-entry scroll calculations (chevron up/down).
/// Extracted from PerformanceView so the math can be unit tested independently.
enum PerformanceScrollCalculator {
    /// Overlap kept between scroll steps when paging through a long entry.
    static let inEntryScrollOverlap: CGFloat = 32

    /// Ordered snap positions for within-entry scrolling, anchored at the entry top.
    /// Full steps of (viewportHeight - overlap) from frame.minY, with the final step
    /// landing at lastSnap (the near-bottom position).
    static func inEntrySnaps(for frame: CGRect, viewportHeight: CGFloat) -> [CGFloat] {
        let lastSnap = frame.maxY - viewportHeight + inEntryScrollOverlap
        let step = viewportHeight - inEntryScrollOverlap
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

    /// Whether the active entry's bottom extends below the visible viewport.
    static func canScrollDown(
        activeEntryFrame frame: CGRect?,
        scrollOffset: CGFloat,
        viewportHeight: CGFloat
    ) -> Bool {
        guard let frame else { return false }
        guard scrollOffset >= frame.minY - 5 else { return false }
        return frame.maxY > scrollOffset + viewportHeight + 5
    }

    /// Whether the active entry's top extends above the visible viewport.
    static func canScrollUp(
        activeEntryFrame frame: CGRect?,
        scrollOffset: CGFloat,
        viewportHeight: CGFloat
    ) -> Bool {
        guard let frame else { return false }
        let lastSnap = frame.maxY - viewportHeight + inEntryScrollOverlap
        guard scrollOffset <= lastSnap + 5 else { return false }
        return scrollOffset > frame.minY + 5
    }

    /// Returns the next snap position below the current scroll offset, or nil if already at bottom.
    static func nextSnapDown(
        activeEntryFrame frame: CGRect,
        scrollOffset: CGFloat,
        viewportHeight: CGFloat
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
