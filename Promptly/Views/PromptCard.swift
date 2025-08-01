//
//  PromptCard.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import Foundation
import SwiftData
import SwiftUI

// prompt card
struct PromptCard: View {
    @Environment(\.modelContext) private var modelContext
    let prompt: Prompt
    let onEdit: () -> Void
    
    @State private var isHovered = false
    @State private var showingEditSheet = false
    @State private var showCopySuccessHint = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // title and favorite button
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
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
            
            // description
            if !prompt.promptDescription.isEmpty {
                Text(prompt.promptDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // tags
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
            
            // bottom information
            HStack {
                // date
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(prompt.updatedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // category tag
                if let category = prompt.category {
                    CategoryBadge(category: category)
                }
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
            onEdit()  // 使用传入的闭包而不是固定的编辑行为
        }
        .contextMenu {
            contextMenuItems
        }
        .sheet(isPresented: $showingEditSheet) {
            PromptEditorView(prompt: prompt)
        }
        .overlay(
            copySuccessHint
                .allowsHitTesting(false)
        )
    }
    
    // copy success hint
    @ViewBuilder
    private var copySuccessHint: some View {
        if showCopySuccessHint {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("prompt.copied".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(.regularMaterial)
            .cornerRadius(20)
            .shadow(radius: 5)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
    
    // context menu items
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
    
    // toggle favorite
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
    
    // copy prompt to clipboard
    private func copyPromptToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(prompt.userPrompt, forType: .string)
        
        withAnimation(.spring()) {
            showCopySuccessHint = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring()) {
                showCopySuccessHint = false
            }
        }
    }
    
    // delete prompt (move to recycle bin)
    private func deletePrompt() {
        let recycleBinManager = RecycleBinManager(modelContext: modelContext)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            do {
                try recycleBinManager.moveToRecycleBin(prompt)
            } catch {
                print("Failed to move prompt to recycle bin: \(error)")
            }
        }
    }
    
    // format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        // set locale based on current language
        let currentLanguage = LocalizationManager.shared.currentLanguage
        switch currentLanguage {
        case .english:
            formatter.locale = Locale(identifier: "en_US")
        case .simplifiedChinese:
            formatter.locale = Locale(identifier: "zh_CN")
        }
        
        return formatter.string(from: date)
    }
}

// tag view
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

// category badge
struct CategoryBadge: View {
    let category: Category
    
    var body: some View {
        HStack(spacing: 4) {
            // Display Emoji or SF Symbol
            if let firstChar = category.iconName.first, String(firstChar).emojis == String(firstChar) {
                Text(category.iconName)
                    .font(.caption)
            } else {
                Image(systemName: category.iconName)
                    .font(.caption)
                    .foregroundColor(colorForName(category.color))
            }
            
            Text(category.name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}
