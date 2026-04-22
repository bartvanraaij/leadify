import CoreGraphics

public enum PerformanceScrollCalculator {

    public static func inEntrySnaps(for frame: CGRect, viewportHeight: CGFloat, dividerHeight: CGFloat = 1)
        -> [CGFloat]
    {
        let workingFrameMaxY = frame.maxY - dividerHeight
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

    public static func isWithinTolerance(_ a: CGFloat, _ b: CGFloat, _ tolerance: CGFloat = 1) -> Bool {
        abs(a - b) <= tolerance
    }

    public static func isOutsideTolerance(_ a: CGFloat, _ b: CGFloat, _ tolerance: CGFloat = 1) -> Bool {
        abs(a - b) >= tolerance
    }

    public static func canScrollDown(
        activeEntryFrame frame: CGRect?,
        scrollOffset: CGFloat,
        viewportHeight: CGFloat,
        overlap: CGFloat = 0,
        dividerHeight: CGFloat = 1
    ) -> Bool {
        guard let frame else { return false }

        let entryIsInView = scrollOffset >= frame.minY || isWithinTolerance(scrollOffset, frame.minY, 2)

        if entryIsInView == false { return false }

        let workingFrameMaxY = frame.maxY - dividerHeight

        let hasRemainingPixelsBelowViewport =
        workingFrameMaxY
            - (scrollOffset + viewportHeight
                 + overlap) >= 1

        return hasRemainingPixelsBelowViewport
    }

    public static func canScrollUp(
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

    public static func nextSnapDown(
        activeEntryFrame frame: CGRect,
        scrollOffset: CGFloat,
        viewportHeight: CGFloat
    ) -> CGFloat? {
        let snaps = inEntrySnaps(for: frame, viewportHeight: viewportHeight)
        return snaps.first(where: { $0 > scrollOffset + 1 })
    }

    public static func nextSnapUp(
        activeEntryFrame frame: CGRect,
        scrollOffset: CGFloat,
        viewportHeight: CGFloat
    ) -> CGFloat? {
        let snaps = inEntrySnaps(for: frame, viewportHeight: viewportHeight)
        return snaps.last(where: { $0 < scrollOffset - 1 })
    }
}
