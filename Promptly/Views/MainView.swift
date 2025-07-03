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
    
    @StateObject private var updateManager = UpdateManager()
    
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
    
    // 全屏相关状态
    @State private var isFullScreen = false
    @State private var fullScreenPrompt: Prompt?
    
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
        ZStack {
            // Main app content
            HSplitView {
                // left sidebar
                SidebarView(
                    selectedCategory: $selectedCategory,
                    showingOnlyFavorites: $showingOnlyFavorites,
                    editingCategory: $editingCategory,
                    categoryToDelete: $categoryToDelete,
                    categoryCannotDelete: $categoryCannotDelete,
                    showingCannotDeleteAlert: $showingCannotDeleteAlert,
                    showingDeleteAlert: $showingDeleteAlert,
                    showingAddCategory: $showingAddCategory,
                    prompts: prompts,
                    categories: categories,
                    promptCount: promptCount,
                    isCategoryInUse: isCategoryInUse
                )
                .frame(minWidth: 250, maxWidth: 350)
                
                // right main content
                mainContent
                    .frame(minWidth: 500)
            }
            
            // Full screen overlay (covers entire window)
            if isFullScreen, let prompt = fullScreenPrompt {
                FullScreenPromptView(
                    prompt: prompt,
                    isPresented: $isFullScreen,
                    onCopy: copyPromptContent,
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showDetailPanel = false
                            selectedPrompt = nil
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1000) // Ensure it's on top
            }
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
        .alert("Update Available".localized, isPresented: $updateManager.isUpdateAvailable) {
            Button("Update Now".localized) {
                if let url = updateManager.latestReleaseURL {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Later".localized, role: .cancel) {}
        } message: {
            Text("A new version of Promptly is available. Do you want to update now?".localized)
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
            
            // check for updates
            updateManager.checkForUpdates()
            
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
    
    // right main content
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Search bar and Tag area
            SearchHeaderView(
                searchText: $searchText,
                selectedTags: $selectedTags,
                isSearchFocused: _isSearchFocused,
                tagsWithCount: cachedTagsWithCount
            )
            
            Divider()
            
            // Main content area
            if showDetailPanel {
                // When the detail panel is displayed, use VSplitView to split up and down
                VSplitView {
                    // Upper part: Prompt list
                    PromptListView(
                        prompts: filteredPrompts,
                        onPromptSelected: { prompt in
                            selectedPrompt = prompt
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDetailPanel = true
                            }
                        },
                        onCreatePrompt: {
                            showingAddPrompt = true
                        }
                    )
                    .frame(minHeight: 200)
                    
                    // Lower part: Detail panel
                    PromptDetailView(
                        prompt: selectedPrompt,
                        showCopySuccess: showCopySuccess,
                        onClose: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDetailPanel = false
                                selectedPrompt = nil
                            }
                        },
                        onCopy: copyPromptContent,
                        onFullScreen: { prompt in
                            fullScreenPrompt = prompt
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isFullScreen = true
                            }
                        }
                    )
                    .frame(minHeight: 200, maxHeight: 400)
                }
            } else {
                // When the detail panel is not displayed, only display the Prompt list
                PromptListView(
                    prompts: filteredPrompts,
                    onPromptSelected: { prompt in
                        selectedPrompt = prompt
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showDetailPanel = true
                        }
                    },
                    onCreatePrompt: {
                        showingAddPrompt = true
                    }
                )
            }
        }
    }
}

// MARK: - Full Screen Prompt View (for MainView)
struct FullScreenPromptView: View {
    let prompt: Prompt
    @Binding var isPresented: Bool
    let onCopy: (String) -> Void
    let onClose: () -> Void
    
    @State private var showCopySuccess = false
    
    var body: some View {
        ZStack {
            // Background overlay with gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.75),
                    Color.black.opacity(0.85)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
            }
            
            VStack(spacing: 0) {
                // Full screen header with improved styling
                HStack(spacing: 16) {
                    Text(prompt.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .textSelection(.enabled)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Copy button
                        Button {
                            onCopy(prompt.userPrompt)
                            // Show local copy success
                            showCopySuccess = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showCopySuccess = false
                            }
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
                        
                        // Exit fullscreen button
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresented = false
                            }
                        } label: {
                            Image(systemName: "arrow.down.right.and.arrow.up.left")
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
                        
                        // Close detail view button
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresented = false
                            }
                            onClose()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title3)
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
                }
                .padding(.horizontal, 40)
                .padding(.top, 28)
                .padding(.bottom, 20)
                .background(
                    Color(NSColor.controlBackgroundColor)
                        .opacity(0.95)
                )
                
                // Subtle divider
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
                
                // Full screen content with improved styling and syntax highlighting
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ContentRenderer.highlightTextForFullScreen(prompt.userPrompt)
                            .lineSpacing(6)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 28)
                    .padding(.bottom, 40)
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(NSColor.textBackgroundColor).opacity(0.98),
                            Color(NSColor.textBackgroundColor).opacity(0.95)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(maxWidth: 950, maxHeight: .infinity)  // Slightly wider for better reading
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(NSColor.windowBackgroundColor).opacity(0.98))
                    .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 10)
            )
            .overlay(
                // Copy success toast for full screen
                fullScreenCopySuccessToast
                    .allowsHitTesting(false)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var fullScreenCopySuccessToast: some View {
        if showCopySuccess {
            VStack {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                    Text("Copied to Clipboard")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                )
                
                Spacer()
            }
            .padding(.top, 80)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
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
