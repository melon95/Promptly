//
//  AddPromptView.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import SwiftData
import SwiftUI

// add/edit prompt view
struct AddPromptView: View {
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
                
                ForEach(0..<categories.count, id: \.self) { index in
                    Button(action: {
                        selectedCategory = categories[index]
                    }, label: {
                        HStack {
                            Circle()
                                .fill(colorForCategory(categories[index].color))
                                .frame(width: 12, height: 12)
                            
                            Text(categories[index].name)
                        }
                    })
                }
            } label: {
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.secondary)
                    
                    if let category = selectedCategory {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(colorForCategory(category.color))
                                .frame(width: 12, height: 12)
                            
                            Text(category.name)
                                .foregroundColor(.primary)
                        }
                    } else {
                        Text("Select Category".localized)
                            .foregroundColor(.secondary)
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
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), alignment: .leading, spacing: 8) {
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
            .padding(12)
            .frame(minHeight: 200)
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
    
    // get color for category
    private func colorForCategory(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "pink": return .pink
        case "red": return .red
        case "gray": return .gray
        default: return .gray
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

 
