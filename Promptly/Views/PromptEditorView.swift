//
//  PromptEditorView.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import SwiftData
import SwiftUI
import AppKit

// add/edit prompt view
struct PromptEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]
    
    let prompt: Prompt? // nil means new, non-nil means edit
    
    // convenience initializer for new prompt
    init() {
        self.prompt = nil
    }
    
    // initializer for editing existing prompt
    init(prompt: Prompt) {
        self.prompt = prompt
    }
    
    @State private var title = ""
    @State private var description = ""
    @State private var userPrompt = ""
    @State private var selectedCategory: Category?
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var isFavorite = false
    
    @FocusState private var isNewTagFocused: Bool
    
    private var isEditing: Bool {
        prompt != nil
    }
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !userPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // title input
                    titleSection
                    
                    // description input
                    descriptionSection
                    
                    // category selection
                    categorySection
                    
                    // tags input
                    tagsSection
                    
                    // prompt content input
                    promptSection
                    
                    // favorite option
                    favoriteSection
                }
                .padding(24)
            }
            .navigationTitle(isEditing ? "Edit Prompt".localized : "New Prompt".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) {
                        savePrompt()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 700)
        .onAppear {
            loadPromptData()
            // record prompt editor page view - PV tracking
            AnalyticsManager.shared.logPageView(PageName.promptEditor.rawValue)
        }
    }
    
    // title input area
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title".localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                TextField("Enter prompt title...".localized, text: $title)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // description input area
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description".localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(alignment: .top) {
                TextField("Enter description (optional)...".localized, text: $description, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(3...6)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // category selection area
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category".localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            Menu {
                Button("None".localized) {
                    selectedCategory = nil
                }
                
                ForEach(categories) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        CategoryRowMenu(category: category)
                    }
                }
            } label: {
                HStack {
                    if let category = selectedCategory {
                        CategoryRow(category: category)
                            .foregroundColor(.primary)
                    } else {
                        Image(systemName: "folder")
                            .foregroundColor(Color(NSColor.placeholderTextColor))
                        Text("Select Category".localized)
                            .foregroundColor(Color(NSColor.placeholderTextColor))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // tags input area
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags".localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            // add new tag input field
            HStack {
                Image(systemName: "tag")
                    .foregroundColor(.secondary)
                
                TextField("Add tag...".localized, text: $newTag)
                    .textFieldStyle(.plain)
                    .focused($isNewTagFocused)
                    .onSubmit {
                        addTag()
                    }
                
                Button {
                    addTag()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            
            // existing tags (displayed below the input field)
            if !tags.isEmpty {
                EditorTagFlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        TagChip(text: tag) {
                            withAnimation(.spring(response: 0.3)) {
                                tags.removeAll { $0 == tag }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // prompt content input area
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prompt Content".localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $userPrompt)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                
                if userPrompt.isEmpty {
                    Text("Enter your prompt here...".localized)
                        .foregroundColor(Color(NSColor.placeholderTextColor))
                        .font(.system(.body, design: .monospaced))
                        .padding(.leading, 5)
                        .padding(.top, 0)
                        .allowsHitTesting(false)
                }
            }
            .frame(minHeight: 200)
            .padding(12)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // favorite option area
    private var favoriteSection: some View {
        HStack {
            Image(systemName: "heart")
                .foregroundColor(.secondary)
            
            Toggle("Add to Favorites".localized, isOn: $isFavorite)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .font(.body)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 0)
    }
    
    // load prompt data (edit mode)
    private func loadPromptData() {
        guard let prompt = prompt else { return }
        
        title = prompt.title
        description = prompt.promptDescription
        userPrompt = prompt.userPrompt
        selectedCategory = prompt.category
        tags = prompt.tags
        isFavorite = prompt.isFavorite
    }
    
    // add tag
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty, !tags.contains(trimmedTag) else { return }
        
        withAnimation(.spring(response: 0.3)) {
            tags.append(trimmedTag)
        }
        newTag = ""
        isNewTagFocused = true
    }
    
    // save prompt
    private func savePrompt() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUserPrompt = userPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let existingPrompt = prompt {
            // edit existing prompt
            existingPrompt.title = trimmedTitle
            existingPrompt.promptDescription = trimmedDescription
            existingPrompt.userPrompt = trimmedUserPrompt
            existingPrompt.category = selectedCategory
            existingPrompt.tags = tags
            existingPrompt.isFavorite = isFavorite
            existingPrompt.updatedAt = Date()
        } else {
            // create new prompt
            let newPrompt = Prompt(
                title: trimmedTitle,
                description: trimmedDescription,
                userPrompt: trimmedUserPrompt,
                category: selectedCategory,
                tags: tags,
                isFavorite: isFavorite
            )
            modelContext.insert(newPrompt)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save prompt: \(error)")
        }
    }
    
    // category row with icon
    private struct CategoryRowMenu: View {
        let category: Category
        
        var body: some View {
            HStack(spacing: 8) {
                // Display Emoji or SF Symbol
                if let firstChar = category.iconName.first, String(firstChar).emojis == String(firstChar) {
                    Text(category.iconName + "  " + category.name)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: category.iconName)
                        .frame(width: 16, height: 16)
                        .foregroundColor(colorForName(category.color))
                    Text(category.name)
                }
            }
        }
    }

    private struct CategoryRow: View {
        let category: Category
        
        var body: some View {
            HStack(spacing: 8) {
                // Display Emoji or SF Symbol
                if let firstChar = category.iconName.first, String(firstChar).emojis == String(firstChar) {
                    Text(category.iconName)
                        .frame(width: 16, height: 16)

                } else {
                    Image(systemName: category.iconName)
                        .frame(width: 16, height: 16)
                        .foregroundColor(colorForName(category.color))
                }
                Text(category.name)
            }
        }
    }
}

// tag chip (deletable)
struct TagChip: View {
    let text: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
                .foregroundColor(.blue)
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - editor flex layout
struct EditorTagFlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { row in
            row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        }.reduce(0) { $0 + $1 + spacing } - spacing
        
        return CGSize(width: proposal.width ?? 0, height: max(height, 0))
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            
            y += rowHeight + spacing
        }
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        let availableWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubviews.Element]] = []
        var currentRow: [LayoutSubviews.Element] = []
        var currentRowWidth: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentRowWidth + subviewSize.width > availableWidth && !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = [subview]
                currentRowWidth = subviewSize.width
            } else {
                currentRow.append(subview)
                currentRowWidth += subviewSize.width + (currentRow.count > 1 ? spacing : 0)
            }
        }
        
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
}
