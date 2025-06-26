//
//  CategoryViews.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import SwiftData
import SwiftUI

// MARK: - Add/Edit Category View
struct CategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let category: Category?
    
    // Initializer for a new category
    init() {
        self.category = nil
    }
    
    // Initializer for editing an existing category
    init(category: Category) {
        self.category = category
    }

    @State private var categoryName = ""
    @State private var selectedColor: String = "blue"
    @State private var selectedIcon: String = "folder"
    @State private var customColor: Color = .blue
    @State private var showingColorPickerPopover = false
    @State private var customIcon: String = ""
    
    private let availableColors = ["blue", "green", "orange", "pink", "red", "gray"]
    private let availableIcons = ["folder", "pencil", "chevron.left.forwardslash.chevron.right", "megaphone", "paintbrush", "briefcase", "star", "heart", "bookmark", "tag"]
    
    private var isEditing: Bool {
        category != nil
    }

    private var canSave: Bool {
        !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // category name input
                    VStack(alignment: .leading, spacing: 8) {
                    Text("Category Name".localized)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        TextField("Enter category name...".localized, text: $categoryName)
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
                
                // color selection
                colorSelectionSection
                
                // icon selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Icon".localized)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                                customIcon = ""
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon && customIcon.isEmpty ? colorForName(selectedColor).opacity(0.2) : Color.clear)
                                    .foregroundColor(selectedIcon == icon && customIcon.isEmpty ? colorForName(selectedColor) : .primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        }
                    }
                    // Custom Icon (Emoji)
                    HStack {
                        TextField("Or enter an emoji to customize...".localized, text: $customIcon)
                            .textFieldStyle(.plain)
                            .onChange(of: customIcon) { _, newValue in
                                let filtered = String(newValue.emojis.prefix(1))
                                if customIcon != filtered {
                                    customIcon = filtered
                                }
                                
                                if !customIcon.isEmpty {
                                    selectedIcon = customIcon
                                } else if !availableIcons.contains(selectedIcon) {
                                    selectedIcon = "folder" // fallback to default
                                }
                            }

                        if !customIcon.isEmpty {
                            Button {
                                customIcon = ""
                                selectedIcon = "folder"
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                        }
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
            .padding(20)
        }
        .navigationTitle(isEditing ? "Edit Category".localized : "New Category".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) {
                        saveCategory()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .frame(width: 400, height: 420)
        .onAppear {
            loadCategoryData()
        }
    }
    
    private func loadCategoryData() {
        guard let category = category else { return }
        
        categoryName = category.name
        selectedColor = category.color
        
        if availableIcons.contains(category.iconName) {
            selectedIcon = category.iconName
            customIcon = ""
        } else {
            selectedIcon = category.iconName
            customIcon = category.iconName
        }
        
        customColor = colorForName(category.color)
    }
    
    private func saveCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let finalIcon = customIcon.isEmpty ? selectedIcon : customIcon
        
        if let existingCategory = category {
            existingCategory.name = trimmedName
            existingCategory.color = selectedColor
            existingCategory.iconName = finalIcon
        } else {
            let newCategory = Category(
                name: trimmedName,
                color: selectedColor,
                iconName: finalIcon,
                isDefault: false
            )
            modelContext.insert(newCategory)
        }
        
        do {
            try modelContext.save()
            print(isEditing ? "Category updated successfully" : "New category saved: \(trimmedName)")
        } catch {
            print(isEditing ? "Failed to update category: \(error)" : "Failed to save category: \(error)")
        }
        
        dismiss()
    }
    
    // 颜色选择区域（拆分以解决编译器超时问题）
    private var colorSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color".localized)
                .font(.headline)
                .foregroundColor(.primary)

            colorGridView
        }
    }
    
    // 颜色网格视图
    private var colorGridView: some View {
        let columns = Array(repeating: GridItem(.flexible()), count: 7)
        
        return LazyVGrid(columns: columns, spacing: 12) {
            colorButtonsSection
            customColorPickerButton
        }
    }
    
    // 预设颜色按钮
    private var colorButtonsSection: some View {
        ForEach(availableColors, id: \.self) { colorName in
            colorButton(for: colorName)
        }
    }
    
    // 单个颜色按钮
    private func colorButton(for colorName: String) -> some View {
        Button {
            selectedColor = colorName
            customColor = colorForName(colorName)
        } label: {
            colorCircle(for: colorName)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
    
    // 颜色圆圈
    private func colorCircle(for colorName: String) -> some View {
        Circle()
            .fill(colorForName(colorName))
            .frame(width: 32, height: 32)
            .overlay(
                Circle()
                    .stroke(selectedColor == colorName ? Color.primary : Color.clear, lineWidth: 2)
            )
    }
    
    // 自定义颜色选择器按钮
    private var customColorPickerButton: some View {
        Button(action: {
            customColor = colorForName(selectedColor)
            showingColorPickerPopover = true
        }) {
            customColorCircle
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingColorPickerPopover, arrowEdge: .bottom) {
            ColorPicker("Select Color", selection: $customColor, supportsOpacity: false)
                .labelsHidden()
                .padding()
                .onChange(of: customColor) { _, newValue in
                    selectedColor = newValue.toHex()
                }
        }
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
    
    // 自定义颜色圆圈
    private var customColorCircle: some View {
        let isCustomColor = selectedColor.hasPrefix("#")
        
        return ZStack {
            Circle()
                .fill(isCustomColor ? colorForName(selectedColor) : Color(NSColor.controlBackgroundColor))
                .frame(width: 32, height: 32)
                .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                .overlay(Circle().stroke(isCustomColor ? Color.primary : Color.clear, lineWidth: 2))

            if !isCustomColor {
                Image(systemName: "plus")
                    .foregroundColor(.secondary)
            }
        }
    }
} 
