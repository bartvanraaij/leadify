import Foundation

enum PerformanceNavigationMode: String, CaseIterable, Identifiable {
    case screenNavigation
    case chevronNavigation
    case songNavigation
    case smartNavigation

    var id: String { rawValue }

    static let storageKey = "performanceNavigationMode"
    static let defaultMode: PerformanceNavigationMode = .smartNavigation

    static var pickerCases: [PerformanceNavigationMode] {
        [.screenNavigation, .songNavigation, .smartNavigation]
    }

    var title: String {
        switch self {
        case .screenNavigation: "Screen"
        case .chevronNavigation: "Chevron"
        case .songNavigation: "Song"
        case .smartNavigation: "Smart"
        }
    }

    var explanation: String {
        switch self {
        case .screenNavigation:
            "Left tap scrolls up one screen, right tap scrolls down one screen."
        case .chevronNavigation:
            "Left tap goes to the previous song, right tap to the next. Chevrons scroll within the current song."
        case .songNavigation:
            "Tap right advances through snap points, then to the next song. Tap left does the reverse. No chevrons needed."
        case .smartNavigation:
            "Tap right jumps to the next item not fully visible on screen. Tap left returns to the previous position."
        }
    }

    var showsChevrons: Bool {
        self == .chevronNavigation
    }
}
