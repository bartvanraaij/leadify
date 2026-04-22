import Foundation

public enum PerformanceNavigationMode: String, CaseIterable, Identifiable, Sendable {
    case screenNavigation
    case chevronNavigation
    case songNavigation
    case smartNavigation

    public var id: String { rawValue }

    public static let storageKey = "performanceNavigationMode"
    public static let defaultMode: PerformanceNavigationMode = .smartNavigation

    public static var pickerCases: [PerformanceNavigationMode] {
        [.screenNavigation, .songNavigation, .smartNavigation]
    }

    public var title: String {
        switch self {
        case .screenNavigation: "Screen"
        case .chevronNavigation: "Chevron"
        case .songNavigation: "Song"
        case .smartNavigation: "Smart"
        }
    }

    public var explanation: String {
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

    public var showsChevrons: Bool {
        self == .chevronNavigation
    }
}
