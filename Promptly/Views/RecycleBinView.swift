//
//  RecycleBinView.swift
//  Promptly
//
//  Created by Claude on 15/07/2025.
//

import SwiftData
import SwiftUI

struct RecycleBinView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var recycleBinItems: [RecycleBinItem]
    
    @State private var selectedItems: Set<UUID> = []
    @State private var showingEmptyAlert = false
    @State private var showingDeleteAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var recycleBinManager: RecycleBinManager {
        RecycleBinManager(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if recycleBinItems.isEmpty {
                    emptyState
                } else {
                    recycleBinContent
                }
            }
            .navigationTitle("Recycle Bin".localized)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        if !recycleBinItems.isEmpty {
                            Button("Empty Recycle Bin".localized) {
                                showingEmptyAlert = true
                            }
                            .foregroundColor(.red)
                        }
                        
                        Button("Close".localized) {
                            dismiss()
                        }
                    }
                }
            }
        }
        .frame(minWidth: 900, minHeight: 650)
        .alert("Empty Recycle Bin".localized, isPresented: $showingEmptyAlert) {
            Button("Cancel".localized, role: .cancel) { }
            Button("Empty".localized, role: .destructive) {
                emptyRecycleBin()
            }
        } message: {
            Text("Are you sure you want to permanently delete all items in the recycle bin? This action cannot be undone.".localized)
        }
        .alert("Delete Items".localized, isPresented: $showingDeleteAlert) {
            Button("Cancel".localized, role: .cancel) { }
            Button("Delete".localized, role: .destructive) {
                deleteSelectedItems()
            }
        } message: {
            Text("Are you sure you want to permanently delete the selected items? This action cannot be undone.".localized)
        }
        .alert("Error".localized, isPresented: $showingError) {
            Button("OK".localized) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            cleanupExpiredItems()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "trash")
                .font(.system(size: 80))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Recycle Bin is Empty".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Deleted prompts will appear here and be automatically removed after 30 days.".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }
    
    private var recycleBinContent: some View {
        VStack(spacing: 0) {
            // toolbar
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("%d items".localized(with: recycleBinItems.count))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !selectedItems.isEmpty {
                    HStack(spacing: 12) {
                        Button("Restore Selected".localized) {
                            restoreSelectedItems()
                        }
                        .buttonStyle(.bordered)
                        .disabled(selectedItems.isEmpty)
                        
                        Button("Delete Selected".localized) {
                            showingDeleteAlert = true
                        }
                        .buttonStyle(.bordered)
                        .disabled(selectedItems.isEmpty)
                        .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // items list
            List(recycleBinItems, id: \.id) { item in
                VStack(spacing: 0) {
                    RecycleBinItemRow(
                        item: item,
                        isSelected: selectedItems.contains(item.id),
                        onToggleSelection: { toggleSelection(item) },
                        onRestore: { restoreItem(item) },
                        onDelete: { deleteItem(item) }
                    )
                    
                    if item.id != recycleBinItems.last?.id {
                        Divider()
                            .padding(.leading, 20)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                .listRowSeparator(.hidden)
            }
            .listStyle(PlainListStyle())
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        }
    }
    
    // MARK: - Actions
    
    private func toggleSelection(_ item: RecycleBinItem) {
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
        } else {
            selectedItems.insert(item.id)
        }
    }
    
    private func restoreItem(_ item: RecycleBinItem) {
        do {
            try recycleBinManager.restorePrompt(item)
        } catch {
            showError("Failed to restore prompt: \(error.localizedDescription)")
        }
    }
    
    private func deleteItem(_ item: RecycleBinItem) {
        do {
            try recycleBinManager.permanentlyDelete(item)
        } catch {
            showError("Failed to delete prompt: \(error.localizedDescription)")
        }
    }
    
    private func restoreSelectedItems() {
        let itemsToRestore = recycleBinItems.filter { selectedItems.contains($0.id) }
        
        do {
            try recycleBinManager.restorePrompts(itemsToRestore)
            selectedItems.removeAll()
        } catch {
            showError("Failed to restore prompts: \(error.localizedDescription)")
        }
    }
    
    private func deleteSelectedItems() {
        let itemsToDelete = recycleBinItems.filter { selectedItems.contains($0.id) }
        
        do {
            try recycleBinManager.permanentlyDelete(itemsToDelete)
            selectedItems.removeAll()
        } catch {
            showError("Failed to delete prompts: \(error.localizedDescription)")
        }
    }
    
    private func emptyRecycleBin() {
        do {
            try recycleBinManager.emptyRecycleBin()
        } catch {
            showError("Failed to empty recycle bin: \(error.localizedDescription)")
        }
    }
    
    private func cleanupExpiredItems() {
        do {
            try recycleBinManager.cleanupExpiredItems()
        } catch {
            print("Failed to cleanup expired items: \(error)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

struct RecycleBinItemRow: View {
    let item: RecycleBinItem
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onRestore: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if !item.promptDescription.isEmpty {
                        Text(item.promptDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 8) {
                        Button("Restore".localized) {
                            onRestore()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Delete".localized) {
                            onDelete()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .foregroundColor(.red)
                    }
                    .opacity(isHovered ? 1 : 0.7)
                }
            }
            
            HStack(spacing: 12) {
                // Add spacer to align with title (checkbox width + spacing)
                Spacer()
                    .frame(width: 22)
                
                if let categoryName = item.categoryName {
                    HStack(spacing: 4) {
                        Image(systemName: item.categoryIconName ?? "folder")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(categoryName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                }
                
                let daysRemaining = item.daysUntilAutoDelete
                if daysRemaining < 11 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("%d days left".localized(with: daysRemaining))
                            .font(.caption)
                    }
                    .foregroundColor(daysRemaining <= 3 ? .red : (daysRemaining <= 7 ? .orange : .secondary))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((daysRemaining <= 3 ? Color.red : (daysRemaining <= 7 ? Color.orange : Color.secondary)).opacity(0.1))
                    .cornerRadius(4)
                }
                
                Spacer()
                
                Text("Deleted %@".localized(with: formatDate(item.deletedAt)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovered ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button("Restore".localized) {
                onRestore()
            }
            
            Button("Delete Permanently".localized) {
                onDelete()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    RecycleBinView()
}