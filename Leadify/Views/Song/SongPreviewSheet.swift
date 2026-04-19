import SwiftUI

struct SongPreviewSheet: View {
    let title: String
    let reminder: String?
    let content: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                SongPerformanceContent(title: title, reminder: reminder, content: content)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationSizing(.page)
    }
}
