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
    
    // add: detail panel related state
    @State private var selectedPrompt: Prompt?
    @State private var showCopySuccess = false
    

    
    // tag search related state
    @State private var selectedTags: Set<String> = []
    @State private var cachedTagsWithCount: [(tag: String, count: Int)] = []
    
    // filtered prompts
    private var filteredPrompts: [Prompt] {
        var filtered = prompts
        
        // filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category?.id == category.id }
        }
        
        // only show favorites
        if showingOnlyFavorites {
            filtered = filtered.filter { $0.isFavorite }
        }
        
        // filter by tags
        if !selectedTags.isEmpty {
            filtered = filtered.filter { prompt in
                // check if the prompt contains all selected tags (AND logic)
                selectedTags.allSatisfy { selectedTag in
                    prompt.tags.contains { tag in
                        tag.localizedCaseInsensitiveContains(selectedTag)
                    }
                }
            }
        }
        
        // filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { prompt in
                prompt.title.localizedCaseInsensitiveContains(searchText) ||
                prompt.promptDescription.localizedCaseInsensitiveContains(searchText) ||
                prompt.tags.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // sort by creation time
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
            // Main app contentla
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
        .sheet(item: $selectedPrompt) { prompt in
            PromptViewer(
                prompt: prompt,
                onClose: {
                    selectedPrompt = nil
                },
                onCopy: copyPromptContent
            )
            .frame(minWidth: 800, minHeight: 600)
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
            PromptListView(
                prompts: filteredPrompts,
                onPromptSelected: { prompt in
                    selectedPrompt = prompt
                },
                onCreatePrompt: {
                    showingAddPrompt = true
                }
            )
            .background(Color(NSColor.windowBackgroundColor))
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
            queue: nil // listen on any thread
        ) { _ in
            // switch to main thread to update UI state
            Task { @MainActor in
                self.showingAddPrompt = true
            }
        }
        
        // listen to show favorites shortcut
        NotificationCenter.default.addObserver(
            forName: .showFavorites,
            object: nil,
            queue: nil // listen on any thread
        ) { _ in
            // switch to main thread to update UI state
            Task { @MainActor in
                self.showingOnlyFavorites = true
                self.selectedCategory = nil
            }
        }
        
        // listen to search field focus shortcut
        NotificationCenter.default.addObserver(
            forName: .focusSearch,
            object: nil,
            queue: nil // listen on any thread
        ) { _ in
            // switch to main thread to update UI state
            Task { @MainActor in
                self.isSearchFocused = true
            }
        }
        
        // listen to quick access switch
        NotificationCenter.default.addObserver(
            forName: .toggleQuickAccess,
            object: nil,
            queue: nil // listen on any thread
        ) { _ in
            // switch to main thread to call the main thread method
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
    
    // check if the category is in use
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
