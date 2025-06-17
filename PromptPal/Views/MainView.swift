//
//  MainView.swift
//  PromptPal
//
//  Created by Melon on 17/06/2025.
//

import SwiftUI
import SwiftData

/// 主界面视图
struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var prompts: [Prompt]
    
    @State private var selectedCategory: PromptCategory? = nil
    @State private var searchText = ""
    @State private var showingAddPrompt = false
    @State private var showingOnlyFavorites = false
    
    /// 过滤后的 Prompts
    private var filteredPrompts: [Prompt] {
        var filtered = prompts
        
        // 按分类筛选
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
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
        
        // 按更新时间排序
        return filtered.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    /// 各分类的Prompt数量
    private func promptCount(for category: PromptCategory) -> Int {
        prompts.filter { $0.category == category }.count
    }
    
    var body: some View {
        HSplitView {
            // 左侧边栏
            sidebar
                .frame(minWidth: 250, maxWidth: 350)
            
            // 右侧主内容区
            mainContent
                .frame(minWidth: 500)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddPrompt = true
                } label: {
                    Label("New Prompt", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPrompt) {
            AddPromptView()
        }
        .onAppear {
            // 首次启动时创建示例数据
            SampleData.createSamplePrompts(in: modelContext)
        }
    }
    
    /// 左侧边栏
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题
            VStack(alignment: .leading, spacing: 16) {
                Text("PromptPal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                
                // All Prompts 和 Favorites
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
            
            Divider()
                .padding(.vertical, 20)
            
            // 分类列表
            VStack(alignment: .leading, spacing: 12) {
                Text("Categories".localized)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                
                LazyVStack(spacing: 4) {
                    ForEach(PromptCategory.allCases, id: \.self) { category in
                        CategoryRow(
                            category: category,
                            count: promptCount(for: category),
                            isSelected: selectedCategory == category && !showingOnlyFavorites
                        ) {
                            selectedCategory = category
                            showingOnlyFavorites = false
                        }
                    }
                }
            }
            
            Spacer()
            
            // 新建分类按钮
            Button {
                // TODO: 实现新建分类
            } label: {
                Label("New Category".localized, systemImage: "plus")
            }
            .buttonStyle(SidebarButtonStyle())
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    /// 右侧主内容区
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
    
    /// 搜索头部
    private var searchHeader: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search Prompts...".localized, text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    /// Prompt 列表
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
    
    /// 空状态视图
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

/// 导航按钮组件
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
        }
        .buttonStyle(NavigationButtonStyle(isSelected: isSelected))
    }
}

/// 分类行组件
struct CategoryRow: View {
    let category: PromptCategory
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(colorForCategory(category.color))
                    .frame(width: 12, height: 12)
                
                Text(category.displayName)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Spacer()
                
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
        }
        .buttonStyle(CategoryButtonStyle(isSelected: isSelected))
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

/// 自定义按钮样式 - 解决默认内边距导致的空白间隙问题
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

/// 主要按钮样式
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

/// 导航按钮样式
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

/// 分类按钮样式
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
