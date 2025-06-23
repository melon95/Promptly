//
//  MainView.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import SwiftData
import SwiftUI

// main view
struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var prompts: [Prompt]
    @Query private var categories: [Category]
    
    @State private var selectedCategory: Category?
    @State private var searchText = ""
    @State private var showingAddPrompt = false
    @State private var showingOnlyFavorites = false
    @State private var showingAddCategory = false
    @State private var editingCategory: Category?
    @State private var showingDeleteAlert = false
    @State private var showingCannotDeleteAlert = false
    @State private var categoryToDelete: Category?
    @State private var categoryCannotDelete: Category?
    @FocusState private var isSearchFocused: Bool
    
    // filtered prompts
    private var filteredPrompts: [Prompt] {
        var filtered = prompts
        
        // 按分类筛选
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category?.id == category.id }
        }
        
        // 只显示收藏
        if showingOnlyFavorites {
            filtered = filtered.filter { $0.isFavorite }
        }
        
        // 搜索筛选
        if !searchText.isEmpty {
            filtered = filtered.filter { prompt in
                prompt.title.localizedCaseInsensitiveContains(searchText) ||
                prompt.promptDescription.localizedCaseInsensitiveContains(searchText) ||
                prompt.tags.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 按创建时间排序
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }
    
    // prompt count for each category
    private func promptCount(for category: Category) -> Int {
        prompts.filter { $0.category?.id == category.id }.count
    }
    
    var body: some View {
        HSplitView {
            // left sidebar
            sidebar
                .frame(minWidth: 250, maxWidth: 350)
            
            // right main content
            mainContent
                .frame(minWidth: 500)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddPrompt = true
                } label: {
                    Label("New Prompt".localized, systemImage: "plus")
                }
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddPrompt) {
            AddPromptView()
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView()
        }
        .sheet(item: $editingCategory) { category in
            EditCategoryView(category: category)
        }
        .alert("Delete Category".localized, isPresented: $showingDeleteAlert) {
            Button("Cancel".localized, role: .cancel) { }
            Button("Delete".localized, role: .destructive) {
                if let category = categoryToDelete {
                    deleteCategory(category)
                }
            }
        } message: {
            if let category = categoryToDelete {
                Text("Are you sure you want to delete the category \"%@\"?".localized(with: category.name))
            }
        }
        .alert("Cannot Delete Category".localized, isPresented: $showingCannotDeleteAlert) {
            Button("OK".localized, role: .cancel) { }
        } message: {
            if let category = categoryCannotDelete {
                Text("Cannot delete category \"%@\" because it contains prompts. Please move or delete the prompts first.".localized(with: category.name))
            }
        }
        .onAppear {
            // create default categories first, then sample data
            SampleData.createDefaultCategories(in: modelContext)
            SampleData.createSamplePrompts(in: modelContext)
            
            // set keyboard shortcuts
            setupKeyboardShortcuts()
        }
        .onDisappear {
            // clean up notification listeners
            // swiftlint:disable:next notification_center_detachment
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    // left sidebar
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // All Prompts 和 Favorites
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 8) {
                    NavigationButton(
                        title: "All Prompts".localized,
                        icon: "tray.full",
                        isSelected: selectedCategory == nil && !showingOnlyFavorites,
                        count: prompts.count
                    ) {
                        selectedCategory = nil
                        showingOnlyFavorites = false
                    }
                    
                    NavigationButton(
                        title: "Favorites".localized,
                        icon: "heart.fill",
                        isSelected: showingOnlyFavorites,
                        count: prompts.filter { $0.isFavorite }.count,
                        iconColor: .red
                    ) {
                        showingOnlyFavorites = true
                        selectedCategory = nil
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 20)
            
            Divider()
                .padding(.vertical, 20)
            
            // 分类列表
            VStack(alignment: .leading, spacing: 12) {
                Text("Categories".localized)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                
                LazyVStack(spacing: 4) {
                    // 所有分类（不再区分固定和自定义）
                    ForEach(categories.sorted { $0.createdAt < $1.createdAt }) { category in
                        CategoryRow(
                            category: category,
                            count: promptCount(for: category),
                            isSelected: selectedCategory?.id == category.id && !showingOnlyFavorites,
                            onEdit: {
                                editingCategory = category
                            },
                            onDelete: {
                                // 检查是否有 prompt 使用该分类
                                if isCategoryInUse(category) {
                                    categoryCannotDelete = category
                                    showingCannotDeleteAlert = true
                                } else {
                                    categoryToDelete = category
                                    showingDeleteAlert = true
                                }
                            },
                            action: {
                                selectedCategory = category
                                showingOnlyFavorites = false
                            }
                        )
                    }
                }
            }
            
            Spacer()
            
            // 新建分类按钮
            Button {
                showingAddCategory = true
            } label: {
                Label("New Category".localized, systemImage: "plus")
            }
            .buttonStyle(SidebarButtonStyle())
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // right main content
    private var mainContent: some View {
        VStack(spacing: 0) {
            // 搜索栏
            searchHeader
                .padding(20)
                .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Prompt 列表
            if filteredPrompts.isEmpty {
                emptyStateView
            } else {
                promptList
            }
        }
    }
    
    // search header
    private var searchHeader: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search Prompts...".localized, text: $searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // prompt list
    private var promptList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredPrompts) { prompt in
                    PromptCard(prompt: prompt) {
                        // 空闭包，因为编辑功能现在在 PromptCard 内部处理
                    }
                }
            }
            .padding(20)
        }
    }
    
    // empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Prompts Found".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create your first prompt or adjust your search criteria.".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button {
                showingAddPrompt = true
            } label: {
                Label("Create Prompt".localized, systemImage: "plus")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// navigation button
struct NavigationButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    var iconColor: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isSelected ? .white : iconColor)
                    .frame(width: 20)
                
                Text(title)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Spacer()
                
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.2) : Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(NavigationButtonStyle(isSelected: isSelected))
        .onHover { isHovering in
            if isHovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// category row
struct CategoryRow: View {
    let category: Category
    let count: Int
    let isSelected: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(colorForCategory(category.color))
                    .frame(width: 12, height: 12)
                
                Text(category.name)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Spacer()
                
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(CategoryButtonStyle(isSelected: isSelected))
        .contextMenu {
            Button("Edit".localized) {
                onEdit()
            }
            
            Divider()
            
            Button("Delete".localized, role: .destructive) {
                onDelete()
            }
        }
        .onHover { isHovering in
            if isHovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
    
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

// custom button style
struct SidebarButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    let cornerRadius: CGFloat
    
    init(backgroundColor: Color = Color.blue.opacity(0.1), 
         foregroundColor: Color = .blue, 
         cornerRadius: CGFloat = 8) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.cornerRadius = cornerRadius
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// primary button style
struct PrimaryButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    let cornerRadius: CGFloat
    
    init(backgroundColor: Color = .blue, 
         foregroundColor: Color = .white, 
         cornerRadius: CGFloat = 8) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.cornerRadius = cornerRadius
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// navigation button style
struct NavigationButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// category button style
struct CategoryButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - MainView extension - keyboard shortcuts
extension MainView {
    // set keyboard shortcuts
    private func setupKeyboardShortcuts() {
        // listen to new prompt shortcut
        NotificationCenter.default.addObserver(
            forName: .showAddPrompt,
            object: nil,
            queue: .main
        ) { _ in
            showingAddPrompt = true
        }
        
        // listen to show favorites shortcut
        NotificationCenter.default.addObserver(
            forName: .showFavorites,
            object: nil,
            queue: .main
        ) { _ in
            showingOnlyFavorites = true
            selectedCategory = nil
        }
        
        // listen to search field focus shortcut
        NotificationCenter.default.addObserver(
            forName: .focusSearch,
            object: nil,
            queue: .main
        ) { _ in
            isSearchFocused = true
        }
        
        // listen to quick access switch
        NotificationCenter.default.addObserver(
            forName: .toggleQuickAccess,
            object: nil,
            queue: .main
        ) { _ in
            // implement quick access function - can show a floating window
            showQuickAccessWindow()
        }
    }
    
    // show quick access window
    private func showQuickAccessWindow() {
        // implement quick access window logic
        // for example, show a search field or recently used prompts
        print("show quick access window")
    }
    
    // delete category
    private func deleteCategory(_ category: Category) {
        modelContext.delete(category)
        
        do {
            try modelContext.save()
            print("Category deleted successfully")
            
            // if the deleted category was selected, clear selection
            if selectedCategory?.id == category.id {
                selectedCategory = nil
            }
        } catch {
            print("Failed to delete category: \(error)")
        }
    }
    
    // 检查分类是否被使用
    private func isCategoryInUse(_ category: Category) -> Bool {
        return prompts.contains { $0.category?.id == category.id }
    }
}

// MARK: - Add Category View
struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var categoryName = ""
    @State private var selectedColor: String = "blue"
    @State private var selectedIcon: String = "folder"
    
    private let availableColors = ["blue", "green", "orange", "pink", "red", "gray"]
    private let availableIcons = ["folder", "pencil", "chevron.left.forwardslash.chevron.right", "megaphone", "paintbrush", "briefcase", "star", "heart", "bookmark", "tag"]
    
    private var canSave: Bool {
        !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // category name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category Name".localized)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Enter category name...".localized, text: $categoryName)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                }
                
                // color selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color".localized)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(colorForName(color))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // icon selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Icon".localized)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color.blue.opacity(0.1) : Color.clear)
                                    .foregroundColor(selectedIcon == icon ? .blue : .primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("New Category".localized)
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
        .frame(width: 400, height: 500)
    }
    
    private func colorForName(_ colorName: String) -> Color {
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
    
    private func saveCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 创建新的自定义分类
        let newCategory = Category(
            name: trimmedName,
            color: selectedColor,
            iconName: selectedIcon,
            isDefault: false
        )
        
        // 保存到数据库
        modelContext.insert(newCategory)
        
        do {
            try modelContext.save()
            print("New category saved: \(trimmedName)")
        } catch {
            print("Failed to save category: \(error)")
        }
        
        dismiss()
    }
}

// MARK: - Edit Category View
struct EditCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let category: Category
    
    @State private var categoryName: String
    @State private var selectedColor: String 
    @State private var selectedIcon: String
    
    private let availableColors = ["blue", "green", "orange", "pink", "red", "gray"]
    private let availableIcons = ["folder", "pencil", "chevron.left.forwardslash.chevron.right", "megaphone", "paintbrush", "briefcase", "star", "heart", "bookmark", "tag"]
    
    init(category: Category) {
        self.category = category
        self._categoryName = State(initialValue: category.name)
        self._selectedColor = State(initialValue: category.color)
        self._selectedIcon = State(initialValue: category.iconName)
    }
    
    private var canSave: Bool {
        !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // category name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category Name".localized)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Enter category name...".localized, text: $categoryName)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                }
                
                // color selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color".localized)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(colorForName(color))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // icon selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Icon".localized)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color.blue.opacity(0.1) : Color.clear)
                                    .foregroundColor(selectedIcon == icon ? .blue : .primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Edit Category".localized)
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
        .frame(width: 400, height: 500)
    }
    
    private func colorForName(_ colorName: String) -> Color {
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
    
    private func saveCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 更新分类属性
        category.name = trimmedName
        category.color = selectedColor
        category.iconName = selectedIcon
        
        do {
            try modelContext.save()
            print("Category updated successfully")
        } catch {
            print("Failed to update category: \(error)")
        }
        
        dismiss()
    }
}
