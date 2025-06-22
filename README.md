# PromptPal

[![Build Status](https://github.com/melon95/PromptPal/actions/workflows/build-macos.yml/badge.svg)](https://github.com/melon95/PromptPal/actions/workflows/build-macos.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![macOS](https://img.shields.io/badge/macOS-15.5+-blue.svg)

**A professional AI prompt management tool for macOS, designed to boost your AI workflow productivity.**

PromptPal helps you efficiently manage, organize, and use AI prompts. Stop wasting time digging through notes and start building your personal, high-value prompt library.

**Website: [https://promptpal.melon95.cn/](https://promptpal.melon95.cn/)**

**[中文文档 / Chinese Documentation](README-zh.md)**

## ✨ Screenshots

| Main Interface                                     | Prompt Details                                     |
| -------------------------------------------------- | -------------------------------------------------- |
| ![Main Interface](https://promptpal.melon95.cn/screenshots/main-interface.png) | ![Prompt Details](https://promptpal.melon95.cn/screenshots/prompt-detail.png) |
| **Category Management**                            | **App Settings**                                   |
| ![Category Management](https://promptpal.melon95.cn/screenshots/category.png) | ![App Settings](https://promptpal.melon95.cn/screenshots/settings.png) |

## 🚀 Features

- ✨ **Clean Management Interface**: A modern interface built with SwiftUI, perfectly adapted to the macOS design language, supporting both light and dark modes.
- 🔍 **Smart Search**: Real-time search through prompt content, titles, and tags to quickly find what you need and boost productivity.
- 🏷️ **Flexible Category Management**: Supports custom categories and a tag system to organize prompts according to your workflow habits.
- ⚡ **Global Hotkeys**: Customizable global hotkeys to quickly access the app without interrupting your current workflow.
- 📋 **One-Click Copy**: Click to copy prompts to the clipboard, with intelligent replacement for parameterized prompts.
- ☁️ **iCloud Sync**: Seamlessly sync your prompt library across multiple Mac devices via iCloud and access it anywhere.
- 🌐 **Multi-language Support**: Complete support for Chinese and English interfaces.
- 🔒 **Privacy & Security**: All data is stored locally by default, completely protecting your privacy. Your prompts belong only to you.

## 📦 Download

You can download the latest version of PromptPal from the **[GitHub Releases](https://github.com/melon95/PromptPal/releases)** page or from our official website.

**[🚀 Download Now from Website](https://promptpal.melon95.cn/)**

## 🛠️ Development Environment

- **Xcode**: 16.4 or higher
- **macOS**: 15.5 or higher
- **Swift**: 5.0 or higher

## 📦 Building the Project

### Quick Start

```bash
# Clone the project
git clone https://github.com/melon95/PromptPal.git
cd PromptPal

# Open project with Xcode
open PromptPal.xcodeproj

# Or build with command line
xcodebuild -scheme PromptPal -destination 'platform=macOS' build
```

## 🔄 CI/CD Workflow

The project is configured with automated GitHub Actions workflows:

### Basic Build Workflow

- **Trigger**: Push to main branch or Pull Request
- **Function**: Automatic build and test
- **Artifacts**: Debug version DMG file

### Signed Build Workflow

- **Trigger**: Push version tags (e.g., `v1.0.0`)
- **Function**: Code signing, notarization, create release
- **Artifacts**: Signed DMG file and GitHub Release

### Version Release

```bash
# Create new version
git tag v1.0.0
git push origin v1.0.0

# Automatically trigger signed build and release
```

## 📁 Project Structure

```
PromptPal/
├── PromptPal/                    # Main application code
│   ├── Models/                   # Data models
│   ├── Views/                    # SwiftUI views
│   ├── Utilities/                # Utility classes
│   └── Resources/                # Resource files
├── scripts/                      # Build scripts
│   ├── local-build-test.sh      # Local build testing
│   └── test-workflows.sh        # GitHub Actions testing
├── .github/workflows/            # CI/CD configuration
│   ├── build-macos.yml          # Basic build
│   └── build-signed.yml         # Signed build
└── docs/                         # Documentation
    ├── local-testing.md          # Local testing guide
    └── ci-cd-setup.md            # CI/CD setup guide
```

## 🧪 Testing

### Unit Tests

```bash
# Run all tests
xcodebuild -scheme PromptPal -destination 'platform=macOS' test

# Or use script
./scripts/local-build-test.sh test
```

### UI Tests

```bash
# Run UI tests
xcodebuild -scheme PromptPal -destination 'platform=macOS' test -only-testing:PromptPalUITests
```

## 🐛 Troubleshooting

### Common Issues

1. **Xcode Version Issues**
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

2. **Clean Build Cache**
   ```bash
   ./scripts/local-build-test.sh clean
   ```

3. **Dependency Issues**
   ```bash
   xcodebuild -resolvePackageDependencies -scheme PromptPal
   ```

### Getting Help

- Check [Local Testing Documentation](docs/local-testing.md)
- Check [CI/CD Setup Guide](docs/ci-cd-setup.md)
- Submit [Issues](../../issues) to report problems

## 📝 License

[MIT License](LICENSE)

## 🤝 Contributing

Pull Requests and Issues are welcome!

1. Fork this project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Run local tests (`./scripts/local-build-test.sh full`)
4. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
5. Push to the branch (`git push origin feature/AmazingFeature`)
6. Open a Pull Request

---

Enjoy using it! 🎉 