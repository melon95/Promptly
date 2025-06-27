//
//  SidebarView.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import SwiftData
import SwiftUI

struct SidebarView: View {
    @Binding var selectedCategory: Category?
    @Binding var showingOnlyFavorites: Bool
    @Binding var editingCategory: Category?
    @Binding var categoryToDelete: Category?
    @Binding var categoryCannotDelete: Category?
    @Binding var showingCannotDeleteAlert: Bool
    @Binding var showingDeleteAlert: Bool
    @Binding var showingAddCategory: Bool
    
    let prompts: [Prompt]
    let categories: [Category]
    let promptCount: (Category) -> Int
    let isCategoryInUse: (Category) -> Bool
    
    var body: some View {
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
                            count: promptCount(category),
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