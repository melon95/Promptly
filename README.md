# PromptPal

A macOS application for managing and using AI prompts.

**[中文文档 / Chinese Documentation](README-zh.md)**

## 🚀 Features

- ✨ Clean prompt management interface
- 🏷️ Tag system
- 🔍 Quick search
- 🌐 Multi-language support (Chinese/English)
- 📋 One-click copy to clipboard
- 🎨 Modern SwiftUI interface

## 🛠️ Development Environment

- **Xcode**: 16.4 or higher
- **macOS**: 15.5 or higher
- **Swift**: 5.0 or higher

## 📦 Building the Project

### Quick Start

```bash
# Clone the project
git clone <repository_url>
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