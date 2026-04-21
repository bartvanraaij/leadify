import CoreGraphics

public enum ScreenNavigator {
    public static func handleTap(
        direction: TapDirection,
        scrollOffset: CGFloat,
        viewportHeight: CGFloat
    ) -> CGFloat {
        let delta = direction == .forward ? viewportHeight : -viewportHeight
        return max(0, scrollOffset + delta)
    }
}
