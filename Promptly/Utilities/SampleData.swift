//
//  SampleData.swift
//  Promptly
//
//  Created by Melon on 17/06/2025.
//

import Foundation
import SwiftData

// sample data generator
struct SampleData {
    // create default categories (previously fixed categories)
    static func createDefaultCategories(in context: ModelContext) {
        // check if there are existing categories
        let descriptor = FetchDescriptor<Category>()
        if let existingCategories = try? context.fetch(descriptor), !existingCategories.isEmpty {
            return // existing categories, do not create defaults
        }
        
        // create default categories (previously fixed categories)
        let defaultCategories = [
            Category(name: "Writing".localized, color: "blue", iconName: "pencil", isDefault: true),
            Category(name: "Code".localized, color: "green", iconName: "chevron.left.forwardslash.chevron.right", isDefault: true),
            Category(name: "Marketing".localized, color: "orange", iconName: "megaphone", isDefault: true),
            Category(name: "Creative".localized, color: "pink", iconName: "paintbrush", isDefault: true),
            Category(name: "Business".localized, color: "red", iconName: "briefcase", isDefault: true),
            Category(name: "Other".localized, color: "gray", iconName: "folder", isDefault: true)
        ]
        
        // insert into context
        for category in defaultCategories {
            context.insert(category)
        }
        
        // save data
        do {
            try context.save()
            print("Default categories created successfully")
        } catch {
            print("Failed to create default categories: \(error)")
        }
    }
    
    // create sample prompts
    static func createSamplePrompts(in context: ModelContext) {
        // check if there is existing data
        let promptDescriptor = FetchDescriptor<Prompt>()
        if let existingPrompts = try? context.fetch(promptDescriptor), !existingPrompts.isEmpty {
            return // existing data, do not create sample
        }
        
        // get categories to use in sample prompts
        let categoryDescriptor = FetchDescriptor<Category>()
        guard let categories = try? context.fetch(categoryDescriptor) else {
            print("No categories found for sample prompts")
            return
        }
        
        // find categories by name for sample prompts
        let businessCategory = categories.first { $0.name.contains("Business") || $0.name.contains("商务") }
        let codeCategory = categories.first { $0.name.contains("Code") || $0.name.contains("代码") }
        let marketingCategory = categories.first { $0.name.contains("Marketing") || $0.name.contains("营销") }
        let writingCategory = categories.first { $0.name.contains("Writing") || $0.name.contains("写作") }
        let creativeCategory = categories.first { $0.name.contains("Creative") || $0.name.contains("创意") }
        
        // create sample prompts
        let samplePrompts = [
            Prompt(
                title: "Email Summary",
                description: "Generate a concise summary for a long email",
                userPrompt: "Please generate a concise summary for the following email content, highlighting key information and action items:\n\n[Email Content]",
                category: businessCategory,
                tags: ["email", "summary", "office"],
                isFavorite: true
            ),
            
            Prompt(
                title: "Code Review",
                description: "Review code quality and suggest improvements",
                userPrompt: "Please review the following code and provide suggestions for improvement:\n\n1. Code quality and readability\n2. Performance optimization\n3. Security issues\n4. Best practices\n\n```\n[Code]\n```",
                category: codeCategory,
                tags: ["code", "review", "optimization"],
                isFavorite: false
            ),
            
            Prompt(
                title: "Creative Copywriting",
                description: "Create engaging copy for a product or service",
                userPrompt: "Create engaging marketing copy for the following product/service:\n\nProduct Name: [Product Name]\nTarget Audience: [Target Audience]\nKey Selling Points: [Selling Points]\n\nPlease provide 3 versions in different styles (professional, friendly, playful).",
                category: marketingCategory,
                tags: ["copywriting", "marketing", "creative"],
                isFavorite: true
            ),
            
            Prompt(
                title: "Article Outline",
                description: "Generate a detailed outline for a technical article",
                userPrompt: "Create a detailed outline for a technical article on the following topic:\n\nTopic: [Article Topic]\nTarget Audience: [Audience]\nArticle Length: [Expected Word Count]\n\nThe outline should include:\n- Introduction\n- Main sections (3-5)\n- Key points for each section\n- Conclusion\n- Suggested references",
                category: writingCategory,
                tags: ["writing", "outline", "technical"],
                isFavorite: false
            ),
            
            Prompt(
                title: "Brainstorming Session",
                description: "Generate innovative ideas for a specific problem",
                userPrompt: "Brainstorm 10 innovative solutions for the following challenge:\n\nChallenge Description: [Problem Description]\nBackground Information: [Relevant Context]\nConstraints: [Constraints]\n\nFor each idea, please provide:\n1. Core concept\n2. Implementation difficulty\n3. Expected impact\n4. Potential risks",
                category: creativeCategory,
                tags: ["brainstorming", "innovation", "solutions"],
                isFavorite: true
            )
        ]
        
        // insert into context
        for prompt in samplePrompts {
            context.insert(prompt)
        }
        
        // save data
        do {
            try context.save()
            print("Sample data created successfully")
        } catch {
            print("Failed to create sample data: \(error)")
        }
    }
} 
