//
//  RecycleBinManager.swift
//  Promptly
//
//  Created by Claude on 15/07/2025.
//

import Foundation
import SwiftData

@MainActor
class RecycleBinManager: ObservableObject {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Move to Recycle Bin
    
    /// Move a prompt to the recycle bin
    func moveToRecycleBin(_ prompt: Prompt) throws {
        // create recycle bin item
        let recycleBinItem = RecycleBinItem(from: prompt)
        
        // add to context
        modelContext.insert(recycleBinItem)
        
        // remove original prompt
        modelContext.delete(prompt)
        
        // save changes
        try modelContext.save()
    }
    
    /// Move multiple prompts to the recycle bin
    func moveToRecycleBin(_ prompts: [Prompt]) throws {
        for prompt in prompts {
            let recycleBinItem = RecycleBinItem(from: prompt)
            modelContext.insert(recycleBinItem)
            modelContext.delete(prompt)
        }
        
        try modelContext.save()
    }
    
    // MARK: - Restore from Recycle Bin
    
    /// Restore a prompt from the recycle bin
    func restorePrompt(_ recycleBinItem: RecycleBinItem) throws {
        // find the original category if it still exists
        let categoryId = recycleBinItem.categoryId
        var category: Category? = nil
        
        if let categoryId = categoryId {
            let categoryFetch = FetchDescriptor<Category>(
                predicate: #Predicate<Category> { $0.id == categoryId }
            )
            category = try modelContext.fetch(categoryFetch).first
        }
        
        // create restored prompt
        let restoredPrompt = recycleBinItem.restoreToPrompt(with: category)
        
        // add to context
        modelContext.insert(restoredPrompt)
        
        // remove from recycle bin
        modelContext.delete(recycleBinItem)
        
        // save changes
        try modelContext.save()
    }
    
    /// Restore multiple prompts from the recycle bin
    func restorePrompts(_ recycleBinItems: [RecycleBinItem]) throws {
        for item in recycleBinItems {
            let categoryId = item.categoryId
            var category: Category? = nil
            
            if let categoryId = categoryId {
                let categoryFetch = FetchDescriptor<Category>(
                    predicate: #Predicate<Category> { $0.id == categoryId }
                )
                category = try modelContext.fetch(categoryFetch).first
            }
            
            let restoredPrompt = item.restoreToPrompt(with: category)
            modelContext.insert(restoredPrompt)
            modelContext.delete(item)
        }
        
        try modelContext.save()
    }
    
    // MARK: - Permanent Deletion
    
    /// Permanently delete a prompt from the recycle bin
    func permanentlyDelete(_ recycleBinItem: RecycleBinItem) throws {
        modelContext.delete(recycleBinItem)
        try modelContext.save()
    }
    
    /// Permanently delete multiple prompts from the recycle bin
    func permanentlyDelete(_ recycleBinItems: [RecycleBinItem]) throws {
        for item in recycleBinItems {
            modelContext.delete(item)
        }
        try modelContext.save()
    }
    
    /// Empty the entire recycle bin
    func emptyRecycleBin() throws {
        let fetchDescriptor = FetchDescriptor<RecycleBinItem>()
        let allItems = try modelContext.fetch(fetchDescriptor)
        
        for item in allItems {
            modelContext.delete(item)
        }
        
        try modelContext.save()
    }
    
    // MARK: - Auto-cleanup
    
    /// Clean up expired items (items older than 30 days)
    func cleanupExpiredItems() throws {
        let fetchDescriptor = FetchDescriptor<RecycleBinItem>()
        let allItems = try modelContext.fetch(fetchDescriptor)
        
        let expiredItems = allItems.filter { $0.shouldAutoDelete }
        
        for item in expiredItems {
            modelContext.delete(item)
        }
        
        if !expiredItems.isEmpty {
            try modelContext.save()
            print("🗑️ Auto-cleaned \(expiredItems.count) expired items from recycle bin")
        }
    }
    
    // MARK: - Query Methods
    
    /// Get all recycle bin items
    func getAllRecycleBinItems() throws -> [RecycleBinItem] {
        let fetchDescriptor = FetchDescriptor<RecycleBinItem>(
            sortBy: [SortDescriptor(\.deletedAt, order: .reverse)]
        )
        return try modelContext.fetch(fetchDescriptor)
    }
    
    /// Get recycle bin items count
    func getRecycleBinCount() throws -> Int {
        let fetchDescriptor = FetchDescriptor<RecycleBinItem>()
        return try modelContext.fetch(fetchDescriptor).count
    }
    
    /// Get items that will expire soon (within 7 days)
    func getItemsExpiringSoon() throws -> [RecycleBinItem] {
        let fetchDescriptor = FetchDescriptor<RecycleBinItem>()
        let allItems = try modelContext.fetch(fetchDescriptor)
        
        return allItems.filter { item in
            let daysUntilExpiry = item.daysUntilAutoDelete
            return daysUntilExpiry <= 7 && daysUntilExpiry > 0
        }
    }
}