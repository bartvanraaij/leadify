import SwiftData
import SwiftUI

struct SongEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let song: Song?
    var onSave: ((Song) -> Void)?

    @State private var title: String = ""
    @State private var reminder: String = ""
    @State private var content: String = ""
    @State private var showPreview: Bool = false

    var body: some View {
        NavigationStack {

            ScrollView {
                VStack(spacing: 12) {
                    // MARK: - Title & Reminder fields
                    VStack(spacing: 0) {
                        TextField("Title", text: $title)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                        Divider().padding(.leading, 16)

                        TextField("Reminder", text: $reminder)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    // MARK: - Content Editor/Preview
                    VStack(spacing: 0) {
                        HStack {
                            Text("Content")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)

                            Spacer()

                            Picker("", selection: $showPreview) {
                                Text("Edit").tag(false)
                                Text("Preview").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 150)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                        if showPreview {
                            ScrollView {
                                SongContentPreview(content: content)
                                    .padding(16)
                            }
                            .background(Color(.secondarySystemGroupedBackground))
                            .frame(maxWidth: .infinity, minHeight: 200)
                        } else {
                            TextEditor(text: $content)
                                .font(.system(size: 15, design: .monospaced))
                                .frame(minHeight: 200)
                                .scrollContentBackground(.hidden)
                                .padding(.horizontal, 12)
                                .padding(.bottom, 8)
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(song == nil ? "New Song" : "Edit Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        title.trimmingCharacters(in: .whitespaces).isEmpty
                    )
                }
            }
            .onAppear { loadExistingValues() }
        }
    }

    private func loadExistingValues() {
        guard let song else { return }
        title = song.title
        reminder = song.reminder ?? ""
        content = song.content
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedReminder = reminder.trimmingCharacters(in: .whitespaces)
        let reminderValue = trimmedReminder.isEmpty ? nil : trimmedReminder

        if let song {
            song.title = trimmedTitle
            song.reminder = reminderValue
            song.content = content
            dismiss()
        } else {
            let newSong = Song(
                title: trimmedTitle,
                content: content,
                reminder: reminderValue
            )
            context.insert(newSong)
            dismiss()
            onSave?(newSong)
        }
    }
}

// MARK: - Markdown preview

struct SongContentPreview: View {
    let content: String

    var body: some View {
        SongContentRenderer(content: content)
    }
}

