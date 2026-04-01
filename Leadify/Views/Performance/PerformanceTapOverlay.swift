import SwiftUI
import UIKit

/// Attaches left/right/center tap gesture recognizers to the parent UIScrollView.
/// By adding the gesture directly to the scroll view (instead of overlaying a UIView on top),
/// taps and native scroll gestures coexist naturally.
struct PerformanceTapOverlay: UIViewRepresentable {
    var onLeftTap: () -> Void
    var onRightTap: () -> Void
    /// Called when the user taps in the center zone. Passes the Y position in the scroll view.
    var onCenterTap: ((CGFloat) -> Void)?

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isHidden = true
        context.coordinator.onLeftTap = onLeftTap
        context.coordinator.onRightTap = onRightTap
        context.coordinator.onCenterTap = onCenterTap

        DispatchQueue.main.async {
            guard let scrollView = view.enclosingScrollView() else { return }
            if context.coordinator.tapGesture == nil {
                let tap = UITapGestureRecognizer(
                    target: context.coordinator,
                    action: #selector(Coordinator.handleTap(_:))
                )
                tap.cancelsTouchesInView = false
                scrollView.addGestureRecognizer(tap)
                context.coordinator.tapGesture = tap
            }
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onLeftTap = onLeftTap
        context.coordinator.onRightTap = onRightTap
        context.coordinator.onCenterTap = onCenterTap
    }

    class Coordinator: NSObject {
        var onLeftTap: (() -> Void)?
        var onRightTap: (() -> Void)?
        var onCenterTap: ((CGFloat) -> Void)?
        var tapGesture: UITapGestureRecognizer?

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view else { return }
            let location = gesture.location(in: view)
            let width = view.bounds.width
            let leftZoneEnd = width * 0.4
            let rightZoneStart = width * 0.6

            if location.x < leftZoneEnd {
                onLeftTap?()
            } else if location.x > rightZoneStart {
                onRightTap?()
            } else {
                onCenterTap?(location.y)
            }
        }
    }
}

private extension UIView {
    func enclosingScrollView() -> UIScrollView? {
        var current = superview
        while let view = current {
            if let sv = view as? UIScrollView { return sv }
            current = view.superview
        }
        return nil
    }
}
