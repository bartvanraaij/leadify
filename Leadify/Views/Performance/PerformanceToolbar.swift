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
        GlassEffectContainer(spacing: 32) {
            HStack(spacing: 0) {
                Button(action: onExit) {
                    Label("Done", systemImage: "xmark")
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .accessibilityIdentifier("close-performance")

                Spacer(minLength: 16)

                Menu {
                    Section("Navigation mode") {
                    ForEach(PerformanceNavigationMode.pickerCases) { mode in
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
                    }
                } label: {
                    Label(currentMode.title, systemImage: "hand.tap")
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                .accessibilityIdentifier("performance-mode-menu")

                Spacer(minLength: 16)

                Button(action: onToggleSidebar) {
                    Label("Sidebar", systemImage: "sidebar.right")
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .accessibilityIdentifier("toggle-sidebar")
            }
            .fontWeight(.semibold)
        }
        .accessibilityIdentifier("performance-toolbar")
    }
}

#Preview("Toolbar") {
    PerformanceToolbar(onExit: {}, onToggleSidebar: {})
        .padding()
        .background(Color.gray)
}
