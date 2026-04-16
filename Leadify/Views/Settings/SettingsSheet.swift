import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PerformanceNavigationMode.storageKey) private var storedMode: String = PerformanceNavigationMode.defaultMode.rawValue

    private var selection: Binding<PerformanceNavigationMode> {
        Binding(
            get: { PerformanceNavigationMode(rawValue: storedMode) ?? .defaultMode },
            set: { storedMode = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(PerformanceNavigationMode.allCases) { mode in
                        Button {
                            selection.wrappedValue = mode
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: selection.wrappedValue == mode ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selection.wrappedValue == mode ? Color.accentColor : Color.secondary)
                                    .font(.title3)
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mode.title)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(mode.explanation)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Performance navigation")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
