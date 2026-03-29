import SwiftUI
import SwiftData
import MarkdownUI

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
            VStack(spacing: 0) {
                // MARK: - Header Fields
                VStack(spacing: 0) {
                    // Title Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .textCase(.none)
                        
                        TextField("Song title", text: $title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    
                    Divider()
                    
                    // Reminder Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reminder")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .textCase(.none)
                        
                        TextField("e.g. Capo 4, Fuzz, Tsw +1", text: $reminder)
                            .font(.body)
                            .foregroundStyle(EditTheme.reminderColor)
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    
                    Divider()
                        .padding(.bottom, 12)
                }

                // MARK: - Content Section Header
                HStack {
                    Text("Content")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .textCase(.none)
                    
                    Spacer()
                    
                    Picker("", selection: $showPreview) {
                        Text("Edit").tag(false)
                        Text("Preview").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                Divider()

                // MARK: - Content Editor/Preview
                if showPreview {
                    ScrollView {
                        SongContentPreview(content: content)
                            .padding()
                    }
                    .background(PerformanceTheme.background)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    TextEditor(text: $content)
                        .font(.system(size: 15, design: .monospaced))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scrollContentBackground(.hidden)
                        .background(Color(.systemBackground))
                }
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
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
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
            let newSong = Song(title: trimmedTitle, content: content, reminder: reminderValue)
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
        Markdown(content)
            .markdownTheme(.leadifyPerformance)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Custom MarkdownUI theme

extension MarkdownUI.Theme {
    static let leadifyPerformance = Theme()
        .heading2 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(PerformanceTheme.sectionHeaderSize)
                    FontWeight(.semibold)
                    ForegroundColor(PerformanceTheme.sectionHeaderColor)
                }
                .relativeLineSpacing(.em(0.1))
                .markdownMargin(top: .em(0.8), bottom: .em(0.2))
        }
        .paragraph { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(PerformanceTheme.chordTextSize)
                    ForegroundColor(PerformanceTheme.chordTextColor)
                }
        }
        .codeBlock { configuration in
            configuration.label
                .markdownTextStyle {
                    FontFamilyVariant(.monospaced)
                    FontSize(PerformanceTheme.tabFontSize)
                    ForegroundColor(PerformanceTheme.tabColor)
                }
                .padding(.vertical, 4)
        }
}
