//
//  AddPromptView.swift
//  PromptPal
//
//  Created by Melon on 17/06/2025.
//

import SwiftUI
import SwiftData

/// 添加/编辑 Prompt 视图
struct AddPromptView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let prompt: Prompt? // nil 表示新建，非 nil 表示编辑
    
    /// 便利初始化器，用于新建 Prompt
    init() {
        self.prompt = nil
    }
    
    /// 初始化器，用于编辑现有 Prompt
    init(prompt: Prompt) {
        self.prompt = prompt
    }
    
    @State private var title = ""
    @State private var description = ""
    @State private var userPrompt = ""
    @State private var selectedCategory: PromptCategory = .other
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
                    // 标题输入
                    titleSection
                    
                    // 描述输入
                    descriptionSection
                    
                    // 分类选择
                    categorySection
                    
                    // 标签输入
                    tagsSection
                    
                    // Prompt 内容输入
                    promptSection
                    
                    // 收藏选项
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
    
    /// 标题输入区域
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title".localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("Enter prompt title...".localized, text: $title)
                .textFieldStyle(.roundedBorder)
                .font(.body)
        }
    }
    
    /// 描述输入区域
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description".localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("Enter description (optional)...".localized, text: $description, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
                .font(.body)
        }
    }
    
    /// 分类选择区域
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category".localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("Select Category".localized, selection: $selectedCategory) {
                ForEach(PromptCategory.allCases, id: \.self) { category in
                    HStack {
                        Circle()
                            .fill(colorForCategory(category.color))
                            .frame(width: 12, height: 12)
                        
                        Text(category.displayName)
                    }
                    .tag(category)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// 标签输入区域
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags".localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            // 添加新标签输入框
            HStack {
                TextField("Add tag...".localized, text: $newTag)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNewTagFocused)
                    .onSubmit {
                        addTag()
                    }
                
                Button("Add".localized) {
                    addTag()
                }
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            // 当前已有的标签（显示在输入框下方）
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
    
    /// Prompt 内容输入区域
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prompt Content".localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            TextEditor(text: $userPrompt)
                .font(.system(.body, design: .monospaced))
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .frame(minHeight: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    /// 收藏选项区域
    private var favoriteSection: some View {
        Toggle("Add to Favorites".localized, isOn: $isFavorite)
            .font(.headline)
    }
    
    /// 加载 Prompt 数据（编辑模式）
    private func loadPromptData() {
        guard let prompt = prompt else { return }
        
        title = prompt.title
        description = prompt.promptDescription
        userPrompt = prompt.userPrompt
        selectedCategory = prompt.category
        tags = prompt.tags
        isFavorite = prompt.isFavorite
    }
    
    /// 添加标签
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty, !tags.contains(trimmedTag) else { return }
        
        withAnimation(.spring(response: 0.3)) {
            tags.append(trimmedTag)
        }
        newTag = ""
        isNewTagFocused = true
    }
    
    /// 保存 Prompt
    private func savePrompt() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUserPrompt = userPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let existingPrompt = prompt {
            // 编辑现有 Prompt
            existingPrompt.title = trimmedTitle
            existingPrompt.promptDescription = trimmedDescription
            existingPrompt.userPrompt = trimmedUserPrompt
            existingPrompt.category = selectedCategory
            existingPrompt.tags = tags
            existingPrompt.isFavorite = isFavorite
            existingPrompt.updatedAt = Date()
        } else {
            // 创建新 Prompt
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
    
    /// 获取分类对应的颜色
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



/// 标签芯片（可删除）
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

 