//
//  SampleData.swift
//  PromptPal
//
//  Created by Melon on 17/06/2025.
//

import Foundation
import SwiftData

/// 示例数据生成器
struct SampleData {
    /// 创建示例 Prompts
    static func createSamplePrompts(in context: ModelContext) {
        // 检查是否已有数据
        let descriptor = FetchDescriptor<Prompt>()
        if let existingPrompts = try? context.fetch(descriptor), !existingPrompts.isEmpty {
            return // 已有数据，不创建示例
        }
        
        // 创建示例 Prompts
        let samplePrompts = [
            Prompt(
                title: "邮件摘要",
                description: "为长邮件生成简洁摘要",
                userPrompt: "请为以下邮件内容生成一个简洁的摘要，突出关键信息和行动项：\n\n[邮件内容]",
                category: .business,
                tags: ["邮件", "摘要", "办公"],
                isFavorite: true
            ),
            
            Prompt(
                title: "代码审查",
                description: "代码质量审查和改进建议",
                userPrompt: "请审查以下代码，并提供改进建议：\n\n1. 代码质量和可读性\n2. 性能优化\n3. 安全性问题\n4. 最佳实践\n\n```\n[代码]\n```",
                category: .code,
                tags: ["代码", "审查", "优化"],
                isFavorite: false
            ),
            
            Prompt(
                title: "创意文案",
                description: "为产品或服务创作吸引人的文案",
                userPrompt: "为以下产品/服务创作吸引人的营销文案：\n\n产品名称：[产品名]\n目标用户：[用户群体]\n核心卖点：[卖点]\n\n请提供3个不同风格的文案版本（专业、温馨、活泼）。",
                category: .marketing,
                tags: ["文案", "营销", "创意"],
                isFavorite: true
            ),
            
            Prompt(
                title: "文章大纲",
                description: "为技术文章生成详细大纲",
                userPrompt: "为以下主题创建一个详细的技术文章大纲：\n\n主题：[文章主题]\n目标读者：[读者群体]\n文章长度：[预期字数]\n\n大纲应包括：\n- 引言\n- 主要章节（3-5个）\n- 每个章节的要点\n- 结论\n- 参考资料建议",
                category: .writing,
                tags: ["写作", "大纲", "技术"],
                isFavorite: false
            ),
            
            Prompt(
                title: "头脑风暴",
                description: "为特定问题生成创新想法",
                userPrompt: "为以下挑战进行头脑风暴，生成10个创新的解决方案：\n\n挑战描述：[问题描述]\n背景信息：[相关背景]\n限制条件：[约束条件]\n\n请为每个想法提供：\n1. 核心概念\n2. 实施难度\n3. 预期效果\n4. 潜在风险",
                category: .creative,
                tags: ["头脑风暴", "创新", "解决方案"],
                isFavorite: true
            )
        ]
        
        // 插入到 context
        for prompt in samplePrompts {
            context.insert(prompt)
        }
        
        // 保存数据
        do {
            try context.save()
            print("Sample data created successfully")
        } catch {
            print("Failed to create sample data: \(error)")
        }
    }
} 