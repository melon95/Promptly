技术设计文档 (TDD): Promptly for macOS
版本: 2.0
日期: 2025 年 6 月 11 日
关联文档: 产品需求文档 (PRD) v2.0

1. 概述 (Overview)

本文档旨在为 Promptly for macOS 应用程序提供全面的技术实现蓝图。它基于产品需求文档 (PRD) 中定义的功能和目标，详细阐述了系统架构、技术选型、数据模型设计以及核心功能的实现策略。

2. 系统架构 (System Architecture)

为确保代码的清晰度、可维护性和可测试性，我们将采用 MVVM (Model-View-ViewModel) 架构。该架构非常适合使用 SwiftUI 进行开发。

Model (模型): 负责应用程序的数据和业务逻辑。在本项目中，将由 SwiftData 模型来承担，负责定义 Prompt 和 Category 等数据结构，并处理所有的数据持久化、iCloud 同步和查询逻辑。

View (视图): 负责 UI 的展示。完全由 SwiftUI 构建，它将以声明方式定义用户界面。视图本身不包含任何业务逻辑，它只负责渲染数据和将用户操作传递给 ViewModel。

ViewModel (视图模型): 充当 View 和 Model 之间的桥梁。它从 Model 获取数据，并将其转换为 View 可以直接展示的格式。同时，它也处理来自 View 的用户交互（如点击按钮、输入文本），并调用 Model 的相应方法来更新数据。

架构图:

┌─────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│ View │◀─────▶│ ViewModel │◀─────▶│ Model │
│ (SwiftUI) │ │ (Observable) │ │ (SwiftData) │
└─────────────────┘ └──────────────────┘ └──────────────────┘
│ │ ▲
│ User Interactions │ Data & Logic │ Data Persistence
└───────────────────────>│ │ & iCloud Sync
└───────────────────────>│

3. 核心技术栈 (Core Technology Stack)

语言: Swift 5.9+

理由：苹果生态系统的官方语言，拥有现代化的语法、强大的性能和安全性。

UI 框架: SwiftUI

理由：苹果推荐的现代 UI 框架，采用声明式语法，可以显著提高开发效率。其跨平台能力为未来扩展到 iOS/iPadOS 奠定了基础。

数据持久化与同步: SwiftData

理由：苹果在 WWDC23 推出的全新框架，旨在简化数据持久化。它基于 Core Data，但提供了更简洁的、基于 Swift 宏的 API。最重要的是，它原生、无缝地集成了 CloudKit，可以极低成本地实现 iCloud 同步功能。

应用生命周期: SwiftUI App Life Cycle

理由：纯 SwiftUI 的方式管理应用生命周期，代码更统一、简洁。

4. 数据模型设计 (Data Model Design)

我们将使用 SwiftData 的 @Model 宏来定义核心数据模型。

4.1. Prompt 模型

import SwiftData

@Model
final class Prompt {
    var id: UUID
var title: String
    var promptDescription: String  // 描述字段
    var userPrompt: String
    var category: Category?
    var tags: [String]  // 标签数组
    var isFavorite: Bool
var createdAt: Date
    var updatedAt: Date
    var usageCount: Int

    init(
        title: String,
        description: String,
        userPrompt: String,
        category: Category? = nil,
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
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.usageCount = 0
    }
}

id: 唯一标识符，用于数据关联。

title, promptDescription, userPrompt: 核心数据字段。

createdAt, updatedAt: 用于排序和版本控制。

isFavorite: 实现收藏夹功能。

category: 定义与 Category 模型的关系。

tags: 字符串数组，存储相关标签。

usageCount: 记录使用次数，用于统计分析。

4.2. Category 模型

import SwiftData

@Model
final class Category: Identifiable {
    var id: UUID
var name: String
    var color: String
    var iconName: String
    var isDefault: Bool
    var createdAt: Date

    init(name: String, color: String = "blue", iconName: String = "folder", isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.iconName = iconName
        self.isDefault = isDefault
        self.createdAt = Date()
    }
}

name: 分类的名称。

color: 分类的显示颜色。

iconName: 分类的图标名称。

isDefault: 标识是否为默认分类。

createdAt: 创建时间。

5. 关键功能实现方案 (Key Feature Implementation)

5.1. 标准 macOS 应用架构 (Standard macOS App)

应用类型: 标准的 macOS 桌面应用程序，使用 SwiftUI 的 WindowGroup。

窗口管理: 
- 主窗口使用 WindowGroup，支持标准的 macOS 窗口操作。
- 设置窗口使用 Settings 场景，符合 macOS 设计规范。
- 支持 .windowResizability(.contentSize) 来优化窗口大小。

菜单栏集成:
- 使用 Commands 来自定义应用菜单。
- 实现快捷键支持，如 ⌘N 新建、⌘F 搜索等。
- 通过 NotificationCenter 实现菜单与视图的通信。

5.2. 实时搜索 (Live Search)

在 SwiftUI 视图中，使用 @Query 属性包装器来获取 SwiftData 数据。

@Query private var prompts: [Prompt]
@Query private var categories: [Category]

在 View 中定义一个 @State 变量来绑定搜索框的文本，例如 @State private var searchText = ""。

创建一个计算属性，根据 searchText 的值来过滤 prompts 数组。

private var filteredPrompts: [Prompt] {
    var filtered = prompts
    
    // 按分类筛选
    if let category = selectedCategory {
        filtered = filtered.filter { $0.category?.id == category.id }
    }
    
    // 只显示收藏
    if showingOnlyFavorites {
        filtered = filtered.filter { $0.isFavorite }
    }
    
    // 搜索筛选
    if !searchText.isEmpty {
        filtered = filtered.filter { prompt in
            prompt.title.localizedCaseInsensitiveContains(searchText) ||
            prompt.promptDescription.localizedCaseInsensitiveContains(searchText) ||
            prompt.tags.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
}
}
    
    return filtered.sorted { $0.createdAt > $1.createdAt }
}

List 视图将迭代这个 filteredPrompts 计算属性来展示结果。SwiftUI 的响应式特性将确保列表在条件改变时自动更新。

5.3. 分类管理系统 (Category Management)

分类创建: 用户可以通过 AddCategoryView 创建新的分类。

分类编辑: 通过 EditCategoryView 修改现有分类的属性。

分类删除: 实现智能删除检查，防止删除包含 Prompts 的分类。

分类筛选: 在侧边栏提供分类列表，点击可筛选相应的 Prompts。

5.4. 收藏夹系统 (Favorites System)

数据模型: 在 Prompt 模型中的 isFavorite 布尔字段。

UI 实现: 
- 在 Prompt 卡片上提供收藏按钮。
- 在侧边栏提供专门的收藏夹视图。
- 显示收藏夹中 Prompt 的数量。

筛选逻辑: 通过 showingOnlyFavorites 状态变量控制显示。

5.5. iCloud 同步 (已实现UI，需完善配置)

项目配置: 需要在 Xcode 项目的 "Signing & Capabilities" 中，添加 "iCloud" 能力，并勾选 "CloudKit"。

SwiftData 配置: 在创建 ModelContainer 时，需要指定 CloudKit 配置。

let schema = Schema([Prompt.self, Category.self])
let cloudConfiguration = ModelConfiguration(
    "CloudStore", 
    schema: schema, 
    isStoredInMemoryOnly: false, 
    allowsSave: true, 
    cloudKitDatabase: .private("iCloud.com.yourcompany.Promptly")
)

let container = try ModelContainer(for: schema, configurations: [cloudConfiguration])

设置界面: 已实现 iCloud 同步的开关设置，用户可以选择是否启用同步。

5.6. 多语言支持 (Internationalization)

实现方案:
- 使用 .localized 扩展方法来获取本地化字符串。
- 支持简体中文、英文等多种语言。
- 在 LocalizationManager 中管理语言切换逻辑。

资源文件:
- Promptly/Resources/en.lproj/Localizable.strings
- Promptly/Resources/zh-Hans.lproj/Localizable.strings

5.7. 参数化 Prompts (待实现)

占位符定义: 规定占位符格式，例如 {{variable_name}}。

解析: 当用户选择一个 Prompt 进行复制时，使用正则表达式从 prompt.userPrompt 中提取所有 {{...}} 形式的占位符。

let regex = try! NSRegularExpression(pattern: "\\{\\{(.+?)\\}\\}")

动态生成 UI: 根据解析出的占位符列表，动态地生成表单视图。

替换与复制: 将用户输入的值替换占位符后复制到系统剪贴板。

6. 未来功能展望

6.1. Prompt 生成

- **目标**: 集成 AI 模型，根据用户输入智能生成 Prompt。
- **技术挑战**: 需要调用第三方 AI 服务 API，并对结果进行处理和展示。

6.2. Prompt 测试

- **目标**: 提供一个测试环境，快速验证 Prompt 效果。
- **技术挑战**: 可能需要集成多个模型的 API，并设计清晰的对比测试界面。

7. 部署与分发 (Deployment & Distribution)

渠道: Mac App Store

要求: 需要注册 Apple Developer Program。应用需要经过沙盒化 (App Sandbox) 处理，并遵循 App Store 的审核指南。

当前配置: 应用已配置了基本的沙盒权限，支持用户选择的只读文件访问。
