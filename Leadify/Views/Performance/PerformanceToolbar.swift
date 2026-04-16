import SwiftUI

/// On-demand floating capsule shown in the performance view.
/// Exposes Exit (left), Mode picker (center), Sidebar toggle (right).
/// Stock SwiftUI components only — no custom styling beyond a material capsule background.
struct PerformanceToolbar: View {
    let onExit: () -> Void
    let onToggleSidebar: () -> Void

    @AppStorage(PerformanceNavigationMode.storageKey)
    private var storedMode: String = PerformanceNavigationMode.defaultMode.rawValue

    private var currentMode: PerformanceNavigationMode {
        PerformanceNavigationMode(rawValue: storedMode) ?? .defaultMode
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onExit) {
                Label("Done", systemImage: "xmark")
            }
            .accessibilityIdentifier("close-performance")

            Menu {
                ForEach(PerformanceNavigationMode.allCases) { mode in
                    Button {
                        storedMode = mode.rawValue
                    } label: {
                        if mode == currentMode {
                            Label(mode.title, systemImage: "checkmark")
                        } else {
                            Text(mode.title)
                        }
                    }
                }
            } label: {
                Label(currentMode.title, systemImage: "slider.horizontal.3")
            }
            .accessibilityIdentifier("performance-mode-menu")

            Button(action: onToggleSidebar) {
                Label("Sidebar", systemImage: "sidebar.right")
            }
            .accessibilityIdentifier("toggle-sidebar")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .accessibilityIdentifier("performance-toolbar")
    }
}

#Preview("Toolbar") {
    PerformanceToolbar(onExit: {}, onToggleSidebar: {})
        .padding()
        .background(Color.gray)
}
