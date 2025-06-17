//
//  PromptCard.swift
//  PromptPal
//
//  Created by Melon on 17/06/2025.
//

import SwiftUI
import SwiftData

/// Prompt 卡片组件
struct PromptCard: View {
    @Environment(\.modelContext) private var modelContext
    let prompt: Prompt
    let onEdit: () -> Void
    
    @State private var isHovered = false
    @State private var showingEditSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和收藏按钮
            HStack(alignment: .top) {
                Text(prompt.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Spacer()
                
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: prompt.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(prompt.isFavorite ? .red : .secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .opacity(isHovered ? 1 : (prompt.isFavorite ? 1 : 0.6))
            }
            
            // 描述
            if !prompt.promptDescription.isEmpty {
                Text(prompt.promptDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // 标签
            if !prompt.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(prompt.tags, id: \.self) { tag in
                            TagView(text: tag)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            
            Spacer()
            
            // 底部信息
            HStack {
                // 日期
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(prompt.updatedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 分类标签
                CategoryBadge(category: prompt.category)
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            showingEditSheet = true
        }
        .contextMenu {
            contextMenuItems
        }
        .sheet(isPresented: $showingEditSheet) {
            AddPromptView(prompt: prompt)
        }
    }
    
    /// 上下文菜单项
    private var contextMenuItems: some View {
        Group {
            Button {
                showingEditSheet = true
            } label: {
                Label("Edit".localized, systemImage: "pencil")
            }
            
            Button {
                copyPromptToClipboard()
            } label: {
                Label("Copy Prompt".localized, systemImage: "doc.on.doc")
            }
            
            Button {
                toggleFavorite()
            } label: {
                Label(
                    prompt.isFavorite ? "Remove from Favorites".localized : "Add to Favorites".localized,
                    systemImage: prompt.isFavorite ? "heart.slash" : "heart"
                )
            }
            
            Divider()
            
            Button(role: .destructive) {
                deletePrompt()
            } label: {
                Label("Delete".localized, systemImage: "trash")
            }
        }
    }
    
    /// 切换收藏状态
    private func toggleFavorite() {
        withAnimation(.easeInOut(duration: 0.2)) {
            prompt.isFavorite.toggle()
            prompt.updatedAt = Date()
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to toggle favorite: \(error)")
        }
    }
    
    /// 复制 Prompt 到剪贴板
    private func copyPromptToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(prompt.userPrompt, forType: .string)
        
        // TODO: 显示复制成功提示
    }
    
    /// 删除 Prompt
    private func deletePrompt() {
        withAnimation(.easeInOut(duration: 0.3)) {
            modelContext.delete(prompt)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete prompt: \(error)")
        }
    }
    
    /// 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

/// 标签视图
struct TagView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(12)
    }
}

/// 分类徽章
struct CategoryBadge: View {
    let category: PromptCategory
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(colorForCategory(category.color))
                .frame(width: 6, height: 6)
            
            Text(category.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
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