import SwiftUI
import UIKit

/// A transparent overlay that detects taps in left/right zones without blocking scroll gestures.
/// Uses UIKit gesture recognizers so taps and ScrollView panning coexist naturally.
struct PerformanceTapOverlay: UIViewRepresentable {
    var onLeftTap: () -> Void
    var onRightTap: () -> Void

    func makeUIView(context: Context) -> TapOverlayView {
        let view = TapOverlayView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        view.onLeftTap = onLeftTap
        view.onRightTap = onRightTap

        let tap = UITapGestureRecognizer(target: view, action: #selector(TapOverlayView.handleTap(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        return view
    }

    func updateUIView(_ uiView: TapOverlayView, context: Context) {
        uiView.onLeftTap = onLeftTap
        uiView.onRightTap = onRightTap
    }
}

class TapOverlayView: UIView {
    var onLeftTap: (() -> Void)?
    var onRightTap: (() -> Void)?

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let width = bounds.width
        let leftZoneEnd = width * 0.4
        let rightZoneStart = width * 0.6

        if location.x < leftZoneEnd {
            onLeftTap?()
        } else if location.x > rightZoneStart {
            onRightTap?()
        }
        // Center 20% — ignored (pure scroll zone)
    }
}
