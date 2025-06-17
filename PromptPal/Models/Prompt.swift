//
//  Prompt.swift
//  PromptPal
//
//  Created by Melon on 17/06/2025.
//

import Foundation
import SwiftData

/// Prompt 数据模型
@Model
final class Prompt {
    /// 唯一标识符
    var id: UUID
    
    /// 标题
    var title: String
    
    /// 描述
    var promptDescription: String
    
    /// 用户提示词内容
    var userPrompt: String
    
    /// 分类
    var category: PromptCategory
    
    /// 标签
    var tags: [String]
    
    /// 是否收藏
    var isFavorite: Bool
    
    /// 创建时间
    var createdAt: Date
    
    /// 更新时间
    var updatedAt: Date
    
    /// 使用次数
    var usageCount: Int
    
    init(
        title: String,
        description: String,
        userPrompt: String,
        category: PromptCategory = .other,
        tags: [String] = [],
        isFavorite: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.promptDescription = description
        self.userPrompt = userPrompt
        self.category = category
        self.tags = tags
        self.isFavorite = isFavorite
        self.createdAt = Date()
        self.updatedAt = Date()
        self.usageCount = 0
    }
}

/// Prompt 分类枚举
enum PromptCategory: String, CaseIterable, Codable {
    case writing = "Writing"
    case code = "Code"
    case marketing = "Marketing"
    case creative = "Creative"
    case business = "Business"
    case other = "Other"
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .writing:
            return "Writing".localized
        case .code:
            return "Code".localized
        case .marketing:
            return "Marketing".localized
        case .creative:
            return "Creative".localized
        case .business:
            return "Business".localized
        case .other:
            return "Other".localized
        }
    }
    
    /// 分类图标
    var iconName: String {
        switch self {
        case .writing:
            return "pencil"
        case .code:
            return "chevron.left.forwardslash.chevron.right"
        case .marketing:
            return "megaphone"
        case .creative:
            return "paintbrush"
        case .business:
            return "briefcase"
        case .other:
            return "folder"
        }
    }
    
    /// 分类颜色
    var color: String {
        switch self {
        case .writing:
            return "blue"
        case .code:
            return "green"
        case .marketing:
            return "orange"
        case .creative:
            return "pink"
        case .business:
            return "red"
        case .other:
            return "gray"
        }
    }
} 