# PromptPal

一个用于管理和使用 AI 提示词的 macOS 应用。

## 🚀 功能特性

- ✨ 简洁的提示词管理界面
- 🏷️ 标签系统
- 🔍 快速搜索
- 🌐 多语言支持（中文/英文）
- 📋 一键复制到剪贴板
- 🎨 现代化 SwiftUI 界面

## 🛠️ 开发环境

- **Xcode**: 16.4 或更高版本
- **macOS**: 15.5 或更高版本
- **Swift**: 5.0 或更高版本

## 📦 构建项目

### 快速开始

```bash
# 克隆项目
git clone <repository_url>
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