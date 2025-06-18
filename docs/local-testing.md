# 本地测试 GitHub Actions Workflows

## 概述

本文档介绍如何在本地测试 GitHub Actions workflows，确保在推送到 GitHub 之前验证构建流程。

## 🎯 测试方法

### 方法一：使用 act 工具（推荐）

`act` 可以在本地 Docker 容器中运行 GitHub Actions。

#### 安装 act

```bash
# macOS
brew install act

# 或者使用 curl
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

#### 基本用法

```bash
# 快速测试 workflows
./scripts/test-workflows.sh

# 或者分步测试
./scripts/test-workflows.sh validate  # 验证语法
./scripts/test-workflows.sh basic     # 测试基础构建
./scripts/test-workflows.sh tag       # 测试标签构建
```

### 方法二：直接测试构建命令（更实用）

直接运行 xcodebuild 命令，无需 Docker。

```bash
# 完整测试
./scripts/local-build-test.sh full

# 分步测试
./scripts/local-build-test.sh check    # 检查环境
./scripts/local-build-test.sh build    # 测试构建
./scripts/local-build-test.sh archive  # 测试打包
./scripts/local-build-test.sh dmg      # 测试 DMG 创建
```

## 📋 测试清单

### ✅ 基础环境检查

```bash
# 检查 Xcode 版本
xcodebuild -version

# 检查可用的 SDK
xcodebuild -showsdks

# 检查项目 schemes
xcodebuild -list
```

### ✅ 依赖解析测试

```bash
# 如果使用 Swift Package Manager
xcodebuild -resolvePackageDependencies -scheme PromptPal
```

### ✅ 构建测试

```bash
# Debug 构建
xcodebuild \
  -scheme PromptPal \
  -destination 'platform=macOS' \
  -configuration Debug \
  build

# Release 构建
xcodebuild \
  -scheme PromptPal \
  -destination 'platform=macOS' \
  -configuration Release \
  build
```

### ✅ 单元测试

```bash
# 运行所有测试
xcodebuild \
  -scheme PromptPal \
  -destination 'platform=macOS' \
  test
```

### ✅ Archive 测试

```bash
# 创建 Archive
xcodebuild \
  -scheme PromptPal \
  -destination 'platform=macOS' \
  -configuration Release \
  -archivePath ./PromptPal.xcarchive \
  archive
```

### ✅ 导出测试

```bash
# 导出应用
xcodebuild \
  -exportArchive \
  -archivePath ./PromptPal.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist
```

## 🔧 配置文件

### `.actrc` - act 工具配置

```ini
# 平台映射
-P macos-14=catthehacker/ubuntu:act-latest
-P macos-latest=catthehacker/ubuntu:act-latest

# Secrets 文件
--secret-file .secrets

# 详细输出
--verbose
```

### `.secrets` - 模拟环境变量

```bash
# 创建模拟 secrets（用于测试）
./scripts/test-workflows.sh secrets
```

## 🐛 常见问题

### 1. Xcode 版本问题

```bash
# 错误：无法找到 Xcode
Error: xcodebuild not found

# 解决方案
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### 2. Scheme 找不到

```bash
# 错误：Scheme 'PromptPal' not found
Error: Scheme "PromptPal" is not configured for the project

# 解决方案：检查可用的 schemes
xcodebuild -list
```

### 3. 依赖解析失败

```bash
# 错误：Package resolution failed
Error: Package resolution failed

# 解决方案：清理并重新解析
rm -rf .build
xcodebuild -resolvePackageDependencies -scheme PromptPal
```

### 4. 签名问题

```bash
# 错误：Code signing failed
Error: Code Sign error

# 解决方案：使用开发证书或跳过签名
CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
```

### 5. act 无法运行 macOS

```bash
# 问题：act 无法完全模拟 macOS 环境
Warning: macOS runners not fully supported

# 解决方案：使用 Ubuntu 容器 + 基础验证
# 真正的 macOS 特定功能需要在 GitHub Actions 中测试
```

## 📊 性能优化

### 构建缓存

```bash
# 清理缓存
rm -rf ~/Library/Developer/Xcode/DerivedData

# 预热缓存
xcodebuild \
  -scheme PromptPal \
  -destination 'platform=macOS' \
  -configuration Debug \
  build
```

### 并行构建

```bash
# 使用多核构建
xcodebuild \
  -scheme PromptPal \
  -destination 'platform=macOS' \
  -configuration Release \
  -jobs $(sysctl -n hw.ncpu) \
  build
```

## 🚀 最佳实践

### 1. 分层测试

```bash
# 第一层：语法和环境检查
./scripts/test-workflows.sh validate

# 第二层：基础构建测试
./scripts/local-build-test.sh build

# 第三层：完整流程测试
./scripts/local-build-test.sh full
```

### 2. 自动化脚本

```bash
# 创建快速测试别名
alias pt-quick="./scripts/local-build-test.sh build"
alias pt-full="./scripts/local-build-test.sh full"
alias pt-clean="./scripts/local-build-test.sh clean"
```

### 3. CI 预检查

```bash
# 推送前的完整检查
./scripts/local-build-test.sh full && \
./scripts/test-workflows.sh validate && \
echo "✅ 准备推送到 GitHub"
```

## 📝 测试报告

### 生成构建报告

```bash
# 运行完整测试并生成报告
./scripts/local-build-test.sh full > build-report.txt 2>&1
```

### 检查构建产物

```bash
# 检查生成的文件
find ./build -type f -name "*.app" -o -name "*.dmg" -o -name "*.xcarchive" | \
while read file; do
  echo "📁 $file"
  echo "   大小: $(du -h "$file" | cut -f1)"
  echo "   修改时间: $(stat -f %Sm "$file")"
done
```

## 🔄 集成到开发流程

### Pre-commit Hook

```bash
# .git/hooks/pre-commit
#!/bin/bash
./scripts/local-build-test.sh build || exit 1
echo "✅ 本地构建通过"
```

### VS Code 任务

```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Test Build",
      "type": "shell",
      "command": "./scripts/local-build-test.sh",
      "args": ["build"],
      "group": "build"
    },
    {
      "label": "Full Test",
      "type": "shell", 
      "command": "./scripts/local-build-test.sh",
      "args": ["full"],
      "group": "test"
    }
  ]
}
```

## ⚡ 快速开始

1. **安装依赖**
   ```bash
   brew install act
   ```

2. **运行基础测试**
   ```bash
   ./scripts/local-build-test.sh
   ```

3. **验证 workflows**
   ```bash
   ./scripts/test-workflows.sh validate
   ```

4. **推送前完整测试**
   ```bash
   ./scripts/local-build-test.sh full
   ```

这样您就可以在本地全面测试构建流程，确保 GitHub Actions 运行成功！ 