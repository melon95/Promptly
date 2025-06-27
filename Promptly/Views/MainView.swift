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
    
    // 新增：详情面板相关状态
    @State private var selectedPrompt: Prompt?
    @State private var showDetailPanel = false
    @State private var showCopySuccess = false
    
    // Tag搜索相关状态
    @State private var selectedTags: Set<String> = []
    @State private var cachedTagsWithCount: [(tag: String, count: Int)] = []
    
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
        
        // Tag筛选
        if !selectedTags.isEmpty {
            filtered = filtered.filter { prompt in
                // 检查prompt是否包含所有选中的tags（AND逻辑）
                selectedTags.allSatisfy { selectedTag in
                    prompt.tags.contains { tag in
                        tag.localizedCaseInsensitiveContains(selectedTag)
                    }
                }
            }
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
    
    // Because all available tags and their usage count
    private var allTagsWithCount: [(tag: String, count: Int)] {
        var tagCounts: [String: Int] = [:]
        
        // Count the usage of each tag
        for prompt in prompts {
            for tag in prompt.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        // Convert to array and sort by alphabet
        return tagCounts.map { (tag: $0.key, count: $0.value) }
            .sorted { $0.tag < $1.tag }
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
            PromptEditorView()
        }
        .sheet(isPresented: $showingAddCategory) {
            CategoryEditorView()
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditorView(category: category)
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
            
            // Initialize tags cache
            updateTagsCache()
        }
        .onChange(of: prompts) { _, _ in
            // When prompts change, update tags cache
            updateTagsCache()
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
            // All Prompts and Favorites
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
            
            // Category list
            VStack(alignment: .leading, spacing: 12) {
                Text("Categories".localized)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                
                LazyVStack(spacing: 4) {
                    // All categories (no longer distinguish fixed and custom)
                    ForEach(categories.sorted { $0.createdAt < $1.createdAt }) { category in
                        CategoryRow(
                            category: category,
                            count: promptCount(for: category),
                            isSelected: selectedCategory?.id == category.id && !showingOnlyFavorites,
                            onEdit: {
                                editingCategory = category
                            },
                            onDelete: {
                                // Check if there is a prompt using this category
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
            
            // New category button
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
            // Search bar and Tag area
            VStack(spacing: 8) {
                searchHeader
                
                // Tag visualization area
                if !cachedTagsWithCount.isEmpty {
                    tagVisualizationSection
                }
            }
            .padding(20)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Main content area
            if showDetailPanel {
                // When the detail panel is displayed, use VSplitView to split up and down
                VSplitView {
                    // Upper part: Prompt list
                    promptListSection
                        .frame(minHeight: 200)
                    
                    // Lower part: Detail panel
                    promptDetailPanel
                        .frame(minHeight: 200, maxHeight: 400)
                }
            } else {
                // When the detail panel is not displayed, only display the Prompt list
                promptListSection
            }
        }
    }
    
    // prompt list section
    private var promptListSection: some View {
        Group {
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
                        // When clicked, display the detail panel
                        selectedPrompt = prompt
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showDetailPanel = true
                        }
                    }
                }
            }
            .padding(20)
        }
    }
    
    // Detail panel
    private var promptDetailPanel: some View {
        VStack(spacing: 0) {
            // Detail panel title bar (display prompt title + copy button + close button)
            HStack {
                if let prompt = selectedPrompt {
                    Text(prompt.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .textSelection(.enabled)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button {
                        copyPromptContent(prompt.userPrompt)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                } else {
                    Text("Prompt Details".localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showDetailPanel = false
                        selectedPrompt = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
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
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Detail content
            if let prompt = selectedPrompt {
                // Prompt content
                ScrollView {
                    Text(prompt.userPrompt)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .font(.system(.body, design: .monospaced))
                        .padding(20)
                }
            } else {
                VStack {
                    Spacer()
                    Text("No prompt selected".localized)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            // Copy success toast
            copySuccessToast
                .allowsHitTesting(false)
        )
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
                // Display Emoji or SF Symbol
                if let firstChar = category.iconName.first, String(firstChar).emojis == String(firstChar) {
                    Text(category.iconName)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: category.iconName)
                        .font(.body)
                        .frame(width: 16, height: 16)
                        .foregroundColor(colorForName(category.color))
                }
                
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
            queue: nil // 在任意线程监听
        ) { _ in
            // 切换到主线程来更新UI状态
            Task { @MainActor in
                self.showingAddPrompt = true
            }
        }
        
        // listen to show favorites shortcut
        NotificationCenter.default.addObserver(
            forName: .showFavorites,
            object: nil,
            queue: nil // 在任意线程监听
        ) { _ in
            // 切换到主线程来更新UI状态
            Task { @MainActor in
                self.showingOnlyFavorites = true
                self.selectedCategory = nil
            }
        }
        
        // listen to search field focus shortcut
        NotificationCenter.default.addObserver(
            forName: .focusSearch,
            object: nil,
            queue: nil // 在任意线程监听
        ) { _ in
            // 切换到主线程来更新UI状态
            Task { @MainActor in
                self.isSearchFocused = true
            }
        }
        
        // listen to quick access switch
        NotificationCenter.default.addObserver(
            forName: .toggleQuickAccess,
            object: nil,
            queue: nil // Listen on any thread
        ) { _ in
            // Switch to the main thread to call the main thread method
            Task { @MainActor in
                self.showQuickAccessWindow()
            }
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
    
    // 复制成功提示
    @ViewBuilder
    private var copySuccessToast: some View {
        if showCopySuccess {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("prompt.copied".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(.regularMaterial)
            .cornerRadius(20)
            .shadow(radius: 5)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
    
    // tag可视化区域
    private var tagVisualizationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("Tags".localized)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                if !selectedTags.isEmpty {
                    Button("main.tags.search.clear".localized) {
                        selectedTags.removeAll()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
                
                Spacer()
            }
            
            // Tag cloud display - stream layout
            SimpleTagFlowLayout(spacing: 8) {
                ForEach(cachedTagsWithCount, id: \.tag) { tagInfo in
                    TagButton(
                        tag: tagInfo.tag,
                        count: tagInfo.count,
                        isSelected: selectedTags.contains(tagInfo.tag)
                    ) {
                        toggleTag(tagInfo.tag)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // Switch tag selection state
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    // Update tags cache
    private func updateTagsCache() {
        cachedTagsWithCount = allTagsWithCount
    }
    
    // Copy prompt content to clipboard
    private func copyPromptContent(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        
        // Show copy success toast
        withAnimation(.spring()) {
            showCopySuccess = true
        }
        
        // Hide the toast after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring()) {
                showCopySuccess = false
            }
        }
    }
}

// MARK: - TagButton component
struct TagButton: View {
    let tag: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(tag)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)
                
                Text("(\(count))")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.secondary.opacity(0.15))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Stream layout
struct SimpleTagFlowLayout: Layout {
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
