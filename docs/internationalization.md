# PromptPal 国际化功能实现

## 概述

PromptPal 现已支持多语言国际化，为全球用户提供本地化的使用体验。

## 支持的语言

| 语言     | 语言代码  | 状态    |
| -------- | --------- | ------- |
| English  | `en`      | ✅ 完成 |
| 简体中文 | `zh-Hans` | ✅ 完成 |

## 实现架构

### 核心组件

1. **LocalizationManager** - 本地化管理器

   - 单例模式，管理当前语言设置
   - 支持运行时语言切换
   - 自动保存用户语言偏好

2. **字符串扩展** - String Extensions

   - 提供便捷的本地化方法
   - 支持参数化字符串
   - SwiftUI Text 视图集成

3. **本地化文件结构**
   ```
   PromptPal/Resources/
   ├── en.lproj/Localizable.strings      # 英语
   └── zh-Hans.lproj/Localizable.strings # 简体中文
   ```

### 使用方法

#### 在 Swift 代码中

```swift
// 基本用法
let title = "app.name".localized

// 带参数
let message = "search.results".localized(with: count)

// 带默认值
let text = "optional.key".localized(defaultValue: "Default")
```

#### 在 SwiftUI 视图中

```swift
// 本地化文本
Text(localized: "main.empty.title")

// 输入框占位符
TextField("prompt.title.placeholder".localized, text: $title)

// 按钮标题
Button("prompt.save".localized) { /* 操作 */ }
```

#### 语言切换

```swift
// 获取本地化管理器
@StateObject private var localizationManager = LocalizationManager.shared

// 语言选择器
Picker("Language", selection: $localizationManager.currentLanguage) {
    ForEach(LocalizationManager.SupportedLanguage.allCases) { language in
        Text(language.displayName).tag(language)
    }
}
```

## 本地化键值规范

### 命名规则

- 使用点号分隔的层级结构
- 按功能模块分组
- 保持键名简洁且具有描述性

### 分组示例

```
app.*           # 应用通用
menubar.*       # 菜单栏
main.*          # 主界面
prompt.*        # Prompt 管理
tags.*          # 标签系统
parameters.*    # 参数化功能
settings.*      # 设置界面
search.*        # 搜索相关
error.*         # 错误信息
confirm.*       # 确认对话框
```

## 翻译完整性验证

使用验证脚本检查翻译完整性：

```bash
python3 scripts/validate_localization.py
```

验证内容包括：

- ✅ 检查所有语言的翻译键是否完整
- ✅ 验证是否存在空翻译
- ✅ 识别多余或缺失的键
- ✅ 确保格式正确性

## 新增语言支持

### 步骤 1：创建本地化目录

```bash
mkdir -p PromptPal/Resources/[language-code].lproj
```

### 步骤 2：复制并翻译字符串文件

```bash
cp PromptPal/Resources/en.lproj/Localizable.strings PromptPal/Resources/[language-code].lproj/
```

### 步骤 3：更新 LocalizationManager

在 `SupportedLanguage` 枚举中添加新语言：

```swift
enum SupportedLanguage: String, CaseIterable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case japanese = "ja"
    case newLanguage = "[language-code]"  // 新增语言
}
```

### 步骤 4：添加显示名称

```swift
var displayName: String {
    switch self {
    case .newLanguage:
        return "语言名称"
    // ... 其他情况
    }
}
```

### 步骤 5：验证翻译

运行验证脚本确保翻译完整性。

## 最佳实践

### 1. 开发规范

- 所有用户可见文本必须本地化
- 避免硬编码字符串
- 使用有意义的键名和注释

### 2. 文本处理

- 考虑不同语言的文本长度差异
- 设计弹性 UI 布局
- 处理复数形式和格式化参数

### 3. 测试验证

- 测试所有支持语言的界面显示
- 验证运行时语言切换功能
- 检查文本截断和布局问题

### 4. 性能优化

- 使用单例模式避免重复创建
- 合理缓存本地化字符串
- 避免频繁文件读取

## 文件清单

### 核心文件

- `PromptPal/Utilities/LocalizationManager.swift` - 本地化管理器
- `PromptPal/Views/LanguageSettingsView.swift` - 语言设置界面
- `PromptPal/ContentView.swift` - 更新后的主视图（含国际化）

### 本地化文件

- `PromptPal/Resources/en.lproj/Localizable.strings` - 英语翻译
- `PromptPal/Resources/zh-Hans.lproj/Localizable.strings` - 简体中文翻译

### 工具文件

- `scripts/validate_localization.py` - 翻译验证脚本
- `.cursor/rules/internationalization-guidelines.mdc` - 开发规范

## 未来扩展

计划支持的语言：

- 🔄 日本語 (日语)
- 🔄 Français (法语)
- 🔄 Deutsch (德语)
- 🔄 Español (西班牙语)
- 🔄 한국어 (韩语)

## 贡献翻译

我们欢迎社区贡献翻译！请参考：

1. 查看现有的 `en.lproj/Localizable.strings` 文件
2. 创建对应语言的翻译文件
3. 运行验证脚本确保完整性
4. 提交 Pull Request

---

> 💡 **提示**: 更多详细的开发规范请参考 `.cursor/rules/internationalization-guidelines.mdc`
