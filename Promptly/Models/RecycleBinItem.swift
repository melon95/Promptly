//
//  RecycleBinItem.swift
//  Promptly
//
//  Created by Claude on 15/07/2025.
//

import Foundation
import SwiftData

@Model
final class RecycleBinItem {
    // unique identifier
    var id: UUID
    
    // original prompt data
    var originalPromptId: UUID
    var title: String
    var promptDescription: String
    var userPrompt: String
    var tags: [String]
    var isFavorite: Bool
    var usageCount: Int
    
    // category information (stored as separate fields since category might be deleted)
    var categoryId: UUID?
    var categoryName: String?
    var categoryColor: String?
    var categoryIconName: String?
    
    // timestamps
    var originalCreatedAt: Date
    var originalUpdatedAt: Date
    var deletedAt: Date
    
    // auto-deletion date (30 days after deletion)
    var autoDeleteAt: Date
    
    init(from prompt: Prompt) {
        self.id = UUID()
        self.originalPromptId = prompt.id
        self.title = prompt.title
        self.promptDescription = prompt.promptDescription
        self.userPrompt = prompt.userPrompt
        self.tags = prompt.tags
        self.isFavorite = prompt.isFavorite
        self.usageCount = prompt.usageCount
        
        // store category information
        self.categoryId = prompt.category?.id
        self.categoryName = prompt.category?.name
        self.categoryColor = prompt.category?.color
        self.categoryIconName = prompt.category?.iconName
        
        self.originalCreatedAt = prompt.createdAt
        self.originalUpdatedAt = prompt.updatedAt
        self.deletedAt = Date()
        
        // set auto-deletion date to 30 days from now
        self.autoDeleteAt = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    }
    
    // create a new Prompt from this recycle bin item (for restoration)
    func restoreToPrompt(with category: Category?) -> Prompt {
        let prompt = Prompt(
            title: self.title,
            description: self.promptDescription,
            userPrompt: self.userPrompt,
            category: category,
            tags: self.tags,
            isFavorite: self.isFavorite
        )
        
        // restore original timestamps and usage count
        prompt.createdAt = self.originalCreatedAt
        prompt.updatedAt = self.originalUpdatedAt
        prompt.usageCount = self.usageCount
        
        return prompt
    }
    
    // check if this item should be auto-deleted
    var shouldAutoDelete: Bool {
        return Date() >= autoDeleteAt
    }
    
    // get days remaining before auto-deletion
    var daysUntilAutoDelete: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: autoDeleteAt).day ?? 0
        return max(0, days)
    }
}