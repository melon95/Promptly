import Foundation
import SwiftData
import SwiftUI

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String
    var iconName: String
    var isDefault: Bool
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Prompt.category)
    var prompts: [Prompt]?
    
    init(name: String, color: String, iconName: String, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.iconName = iconName
        self.isDefault = isDefault
        self.createdAt = Date()
    }
} 