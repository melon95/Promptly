技术设计文档 (TDD): PromptPal for macOS
版本: 1.0
日期: 2025 年 6 月 11 日
关联文档: 产品需求文档 (PRD) v1.0

1. 概述 (Overview)

本文档旨在为 PromptPal for macOS 应用程序提供全面的技术实现蓝图。它基于产品需求文档 (PRD) 中定义的功能和目标，详细阐述了系统架构、技术选型、数据模型设计以及核心功能的实现策略。

2. 系统架构 (System Architecture)

为确保代码的清晰度、可维护性和可测试性，我们将采用 MVVM (Model-View-ViewModel) 架构。该架构非常适合使用 SwiftUI 进行开发。

Model (模型): 负责应用程序的数据和业务逻辑。在本项目中，将由 SwiftData 模型来承担，负责定义 Prompt 和 Tag 等数据结构，并处理所有的数据持久化、iCloud 同步和查询逻辑。

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
@Attribute(.unique) var id: UUID
var title: String
var content: String
var createdAt: Date
var lastUsedAt: Date
var isFavorite: Bool

    // 与 Tag 的关系
    @Relationship(inverse: \Tag.prompts)
    var tags: [Tag]?

    init(title: String, content: String) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.lastUsedAt = Date() // 初始化时也更新
        self.isFavorite = false
    }

}

id: 唯一标识符，用于数据关联。

title, content: 核心数据字段。

createdAt, lastUsedAt: 用于排序和使用统计。

isFavorite: 实现收藏夹功能。

tags: 定义与 Tag 模型的 多对多 关系。

4.2. Tag 模型

import SwiftData

@Model
final class Tag {
@Attribute(.unique) var id: UUID
var name: String

    // 与 Prompt 的关系
    var prompts: [Prompt]?

    init(name: String) {
        self.id = UUID()
        self.name = name
    }

}

name: 标签的名称，应保持唯一性。

prompts: 反向关系，指向拥有此标签的所有 Prompts。

5. 关键功能实现方案 (Key Feature Implementation)

5.1. 菜单栏应用与全局热键 (Menu Bar App & Global Hotkey)

应用类型设置: 在 Info.plist 文件中，添加 Application is agent (UIElement) 并将其值设置为 YES。这将使应用成为一个没有 Dock 图标的后台应用。

菜单栏图标 (NSStatusItem):

在应用启动时（例如在 App 的 init 或 AppDelegate 中），创建一个 NSStatusItem 实例。

let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

为 statusItem.button 设置图标，并关联一个点击事件来显示/隐藏主窗口。

主窗口管理: 主窗口将通过一个 NSWindow 实例来管理。我们将使用 SwiftUI 的 WindowGroup，并获取其底层的 NSWindow 来进行操作（如居中、显示/隐藏）。

全局热键:

我们将使用 NSEvent.addGlobalMonitorForEvents(matching:handler:) 方法来监听全局键盘事件。

在应用启动时注册一个全局监视器，检查按键组合是否与用户设置的热键匹配。如果匹配，则调用显示/隐藏主窗口的逻辑。

注意: 需要处理 macOS 的辅助功能权限请求，引导用户在“系统设置 -> 隐私与安全性 -> 辅助功能”中授权。

5.2. 实时搜索 (Live Search)

在 SwiftUI 视图中，使用 @Query 属性包装器来获取 SwiftData 数据。

@Query(sort: \Prompt.createdAt, order: .reverse) private var prompts: [Prompt]

在 View 中定义一个 @State 变量来绑定搜索框的文本，例如 @State private var searchText = ""。

创建一个计算属性，根据 searchText 的值来过滤 prompts 数组。

var filteredPrompts: [Prompt] {
if searchText.isEmpty {
return prompts
} else {
return prompts.filter {
$0.title.localizedCaseInsensitiveContains(searchText) ||
$0.content.localizedCaseInsensitiveContains(searchText)
}
}
}

List 视图将迭代这个 filteredPrompts 计算属性来展示结果。SwiftUI 的响应式特性将确保列表在 searchText 改变时自动更新。

5.3. 参数化 Prompts (Parameterized Prompts)

占位符定义: 规定占位符格式，例如 {{variable_name}}。

解析: 当用户选择一个 Prompt 进行复制时，编写一个正则表达式或简单的字符串扫描函数来从 prompt.content 中提取所有 {{...}} 形式的占位符。

let regex = try! NSRegularExpression(pattern: "\\{\\{(.+?)\\}\\}")

动态生成 UI:

根据解析出的占位符列表，动态地生成一个表单视图（例如，使用 ForEach 生成一组 TextField）。

这个表单将以模态窗口（sheet）的形式呈现给用户。

替换与复制:

用户在表单中填写完所有变量后，点击“确认”按钮。

程序将遍历原始 prompt.content，用用户输入的值替换掉相应的占位符。

将最终生成的字符串复制到系统剪贴板 NSPasteboard。

5.4. iCloud 同步

项目配置: 在 Xcode 项目的 "Signing & Capabilities" 中，添加 "iCloud" 能力，并勾选 "CloudKit"。创建一个新的 CloudKit 容器或选择一个已有的。

SwiftData 配置: 在创建 ModelContainer 时，指定 ModelConfiguration 并启用 CloudKit。

let schema = Schema([Prompt.self, Tag.self])
let cloudConfiguration = ModelConfiguration("CloudStore", schema: schema, isStoredInMemoryOnly: false, allowsSave: true, groupContainer: .none, cloudKitDatabase: .private("iCloud.com.yourcompany.PromptPal"))

// 使用这个配置创建容器
let container = try ModelContainer(for: schema, configurations: [cloudConfiguration])

完成以上配置后，SwiftData 将自动处理所有本地数据与私有 iCloud 数据库之间的同步。

6. 部署与分发 (Deployment & Distribution)

渠道: Mac App Store

要求: 需要注册 Apple Developer Program。应用需要经过沙盒化 (App Sandbox) 处理，并遵循 App Store 的审核指南。
