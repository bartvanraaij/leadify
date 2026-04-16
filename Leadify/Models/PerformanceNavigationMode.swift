import Foundation

enum PerformanceNavigationMode: String, CaseIterable, Identifiable {
    case simpleNavigation
    case songNavigation
    case smartNavigation

    var id: String { rawValue }

    static let storageKey = "performanceNavigationMode"
    static let defaultMode: PerformanceNavigationMode = .smartNavigation

    var title: String {
        switch self {
        case .simpleNavigation: "Simple"
        case .songNavigation: "Song navigation"
        case .smartNavigation: "Smart navigation"
        }
    }

    var explanation: String {
        switch self {
        case .simpleNavigation:
            "Left tap scrolls up one screen, right tap scrolls down one screen."
        case .songNavigation:
            "Left tap goes to the previous song, right tap to the next. Chevrons scroll within the current song."
        case .smartNavigation:
            "Tap right advances through snap points, then to the next song. Tap left does the reverse. No chevrons needed."
        }
    }

    var showsChevrons: Bool {
        self == .songNavigation
    }
}
