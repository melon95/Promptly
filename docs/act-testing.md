# 使用 act 本地测试 GitHub Actions

本文档介绍如何使用 `act` 工具在本地验证 GitHub Actions workflow。

## 安装依赖

### 1. 安装 act
```bash
# 在 macOS 上使用 Homebrew
brew install act

# 或者使用 curl 安装
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

### 2. 安装 Docker
确保 Docker Desktop 已安装并运行。

## 项目配置

项目已经配置好了以下文件：

- `.actrc` - act 配置文件
- `.secrets` - 模拟的 secrets（用于测试）
- `scripts/final-validation.sh` - 完整验证脚本

## 使用方法

### 一键完整验证（推荐）

```bash
# 运行完整的最终验证
./scripts/final-validation.sh
```

这个脚本会执行：
- ✅ GitHub Actions 语法验证
- ✅ 本地 Debug 和 Release 构建测试
- ✅ 单元测试运行
- ✅ act 工具验证
- ✅ 配置文件检查

### 手动 act 命令

```bash
# 列出所有可用的 workflows
act --list

# 验证特定 workflow 语法
act --list --workflows .github/workflows/build-macos.yml

# 验证特定 workflow（dryrun 模式）
act push --workflows .github/workflows/build-macos.yml --dryrun --container-architecture linux/amd64
```

### 手动本地构建测试

```bash
# Debug 构建
xcodebuild -scheme PromptPal -destination 'platform=macOS' -configuration Debug build

# Release 构建
xcodebuild -scheme PromptPal -destination 'platform=macOS' -configuration Release build

# 运行测试
xcodebuild -scheme PromptPal -destination 'platform=macOS' test
```

## 验证能力和限制

### act 可以验证的
- ✅ Workflow 语法正确性
- ✅ 步骤执行顺序
- ✅ 环境变量配置
- ✅ 条件逻辑（if 语句）
- ✅ Secrets 引用

### act 无法验证的
- ❌ 实际的 Xcode 构建（需要 macOS 环境）
- ❌ 真实的代码签名和公证

### 我们的解决方案
结合使用：
1. **act** - 语法和逻辑验证
2. **本地 xcodebuild** - 实际构建测试
3. **GitHub Actions** - 最终完整测试

## 常见问题

### Q: act 运行很慢？
A: 首次运行时 act 需要下载 Docker 镜像，后续运行会更快。

### Q: Docker 相关错误？
A: 确保 Docker Desktop 正在运行，并且有足够的磁盘空间。

### Q: 权限错误？
A: 确保脚本有执行权限：`chmod +x scripts/final-validation.sh`

### Q: Apple M-series 芯片警告？
A: 使用 `--container-architecture linux/amd64` 参数可以避免兼容性问题。

## 推荐的工作流程

1. **开发完成后**：运行 `./scripts/final-validation.sh` 进行完整验证
2. **验证通过后**：提交并推送代码
   ```bash
   git add .
   git commit -m "Update workflows"
   git push
   ```
3. **最终确认**：在 GitHub 查看 Actions 执行结果

## 验证结果示例

成功的验证应该显示：
```
🎉 最终验证完成！
==================================================
✅ GitHub Actions 语法验证通过
✅ 本地构建测试通过（Debug + Release）
✅ act 工具可以正确解析 workflows
✅ 所有关键配置文件就绪
```

这确保了您的 GitHub Actions 在推送到远程仓库后能够正常工作。 