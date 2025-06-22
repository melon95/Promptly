# PromptPal

[![构建状态](https://github.com/melon95/PromptPal/actions/workflows/build-macos.yml/badge.svg)](https://github.com/melon95/PromptPal/actions/workflows/build-macos.yml)
[![许可证: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![macOS](https://img.shields.io/badge/macOS-15.5+-blue.svg)

**一款专业的 AI 提示词管理工具，专为 macOS 设计，旨在提升您的 AI 工作流效率。**

PromptPal 帮助您高效管理、组织和使用 AI 提示词。告别在繁杂笔记中寻找提示词的烦恼，开始构建您自己的高价值个人提示词库。

**网站: [https://promptpal.melon95.cn/zh/](https://promptpal.melon95.cn/zh/)**

**[English Documentation](README.md)**

## ✨ 产品预览

| 主界面                                     | 提示词详情                                     |
| -------------------------------------------------- | -------------------------------------------------- |
| ![主界面](https://promptpal.melon95.cn/screenshots/main-interface.png) | ![提示词详情](https://promptpal.melon95.cn/screenshots/prompt-detail.png) |
| **分类管理**                            | **应用设置**                                   |
| ![分类管理](https://promptpal.melon95.cn/screenshots/category.png) | ![应用设置](https://promptpal.melon95.cn/screenshots/settings.png) |

## 🚀 功能特性

- ✨ **简洁的管理界面**: 基于 SwiftUI 构建的现代化界面，完美适配 macOS 设计语言，支持深色和浅色模式。
- 🔍 **智能搜索功能**: 实时搜索提示词内容、标题和标签，快速找到您需要的提示词，提升工作效率。
- 🏷️ **灵活分类管理**: 支持自定义分类和标签系统，按照您的工作习惯组织管理提示词。
- ⚡ **全局快捷键**: 自定义全局热键快速调出应用，无需中断当前工作流程，随时随地使用提示词。
- 📋 **一键复制使用**: 点击即可复制提示词到剪贴板，支持参数化提示词的智能替换功能。
- ☁️ **iCloud 同步**: 通过 iCloud 在多个 Mac 设备之间无缝同步您的提示词库，随时随地访问。
- 🌐 **多语言支持**: 完整支持中文和英文界面，为不同语言用户提供最佳的使用体验。
- 🔒 **隐私安全**: 所有数据默认本地存储，完全保护您的隐私，您的提示词只属于您自己。

## 📦 下载

您可以从 **[GitHub Releases](https://github.com/melon95/PromptPal/releases)** 页面或官方网站下载最新版本的 PromptPal。

**[🚀 前往官网下载](https://promptpal.melon95.cn/zh/)**

## 🛠️ 开发环境

- **Xcode**: 16.4 或更高版本
- **macOS**: 15.5 或更高版本
- **Swift**: 5.0 或更高版本

## 📦 构建项目

### 快速开始

```bash
# 克隆项目
git clone https://github.com/melon95/PromptPal.git
cd PromptPal

# 使用 Xcode 打开项目
open PromptPal.xcodeproj

# 或使用命令行构建
xcodebuild -scheme PromptPal -destination 'platform=macOS' build
```

## 🔄 CI/CD 流程

项目配置了自动化的 GitHub Actions 工作流：

### 基础构建流程

- **触发条件**: 推送到主分支或 Pull Request
- **功能**: 自动构建和测试
- **产物**: Debug 版本的 DMG 文件

### 签名构建流程

- **触发条件**: 推送版本标签 (如 `v1.0.0`)
- **功能**: 代码签名、公证、创建发布版本
- **产物**: 签名的 DMG 文件和 GitHub Release

### 版本发布

```bash
# 创建新版本
git tag v1.0.0
git push origin v1.0.0

# 自动触发签名构建和发布
```

## 📁 项目结构

```
PromptPal/
├── PromptPal/                    # 主应用代码
│   ├── Models/                   # 数据模型
│   ├── Views/                    # SwiftUI 视图
│   ├── Utilities/                # 工具类
│   └── Resources/                # 资源文件
├── scripts/                      # 构建脚本
│   ├── local-build-test.sh      # 本地构建测试
│   └── test-workflows.sh        # GitHub Actions 测试
├── .github/workflows/            # CI/CD 配置
│   ├── build-macos.yml          # 基础构建
│   └── build-signed.yml         # 签名构建
└── docs/                         # 文档
    ├── local-testing.md          # 本地测试说明
    └── ci-cd-setup.md            # CI/CD 配置说明
```

## 🧪 测试

### 单元测试

```bash
# 运行所有测试
xcodebuild -scheme PromptPal -destination 'platform=macOS' test

# 或使用脚本
./scripts/local-build-test.sh test
```

### UI 测试

```bash
# 运行 UI 测试
xcodebuild -scheme PromptPal -destination 'platform=macOS' test -only-testing:PromptPalUITests
```

## 🐛 故障排除

### 常见问题

1. **Xcode 版本问题**
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

2. **清理构建缓存**
   ```bash
   ./scripts/local-build-test.sh clean
   ```

3. **依赖问题**
   ```bash
   xcodebuild -resolvePackageDependencies -scheme PromptPal
   ```

### 获取帮助

- 查看 [本地测试文档](docs/local-testing.md)
- 查看 [CI/CD 配置说明](docs/ci-cd-setup.md)
- 提交 [Issue](../../issues) 报告问题

## 📝 许可证

[MIT License](LICENSE)

## 🤝 贡献

欢迎提交 Pull Request 和 Issue！

1. Fork 这个项目
2. 创建你的功能分支 (`git checkout -b feature/AmazingFeature`)
3. 运行本地测试 (`./scripts/local-build-test.sh full`)
4. 提交你的修改 (`git commit -m 'Add some AmazingFeature'`)
5. 推送到分支 (`git push origin feature/AmazingFeature`)
6. 打开一个 Pull Request

---

使用愉快！ 🎉 