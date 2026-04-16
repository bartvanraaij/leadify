import SwiftUI
import UIKit

/// Attaches left/right/center tap gesture recognizers to the parent UIScrollView.
/// By adding the gesture directly to the scroll view (instead of overlaying a UIView on top),
/// taps and native scroll gestures coexist naturally.
/// `contentWidth` must be the visible scrollable area width — NOT the full screen width —
/// so that tap zones remain correct when the sidebar inspector is open.
struct PerformanceTapOverlay: UIViewRepresentable {
    var contentWidth: CGFloat
    var onLeftTap: () -> Void
    var onRightTap: () -> Void
    /// Called when the user taps in the center zone.
    var onCenterTap: (() -> Void)?

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isHidden = true
        context.coordinator.contentWidth = contentWidth
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
        context.coordinator.contentWidth = contentWidth
        context.coordinator.onLeftTap = onLeftTap
        context.coordinator.onRightTap = onRightTap
        context.coordinator.onCenterTap = onCenterTap
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        if let gesture = coordinator.tapGesture {
            gesture.view?.removeGestureRecognizer(gesture)
            coordinator.tapGesture = nil
        }
    }

    class Coordinator: NSObject {
        var contentWidth: CGFloat = 0
        var onLeftTap: (() -> Void)?
        var onRightTap: (() -> Void)?
        var onCenterTap: (() -> Void)?
        var tapGesture: UITapGestureRecognizer?

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view else { return }
            let location = gesture.location(in: view)
            // Use the explicit contentWidth so zones are relative to the scrollable area,
            // not the full UIScrollView bounds (which ignores the sidebar panel).
            let width = contentWidth > 0 ? contentWidth : view.bounds.width
            let leftZoneEnd = width * 0.36
            let rightZoneStart = width * 0.64

            if location.x < leftZoneEnd {
                onLeftTap?()
            } else if location.x > rightZoneStart {
                onRightTap?()
            } else {
                onCenterTap?()
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
