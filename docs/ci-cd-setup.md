# CI/CD 设置说明

## GitHub Actions Workflows

### 1. 基础构建 Workflow (`build-macos.yml`)

**触发条件:**
- 推送到 `main` 或 `develop` 分支
- 针对 `main` 分支的 Pull Request
- 推送以 `v` 开头的标签（如 `v1.0.0`）

**功能:**
- ✅ 编译和测试应用
- ✅ 缓存构建依赖
- ✅ 创建未签名的 DMG（仅限标签推送）
- ✅ 自动创建 GitHub Release
- ✅ 上传构建产物

### 2. 签名构建 Workflow (`build-signed.yml`)

**触发条件:**
- 推送以 `v` 开头的标签（如 `v1.0.0`）

**功能:**
- ✅ 代码签名
- ✅ 公证 (Notarization)
- ✅ 创建生产就绪的 DMG
- ✅ 自动上传到 Release

## 所需的 GitHub Secrets

### 基础构建（无需设置）
基础 workflow 无需任何 secrets 即可运行。

### 代码签名（生产发布必需）

在 GitHub 仓库的 Settings > Secrets and variables > Actions 中添加：

#### 证书相关
- `CERTIFICATES_P12`: Developer ID Application 证书的 Base64 编码
- `CERTIFICATES_P12_PASSWORD`: P12 证书文件的密码
- `TEAM_ID`: Apple Developer Team ID

#### Apple 账户
- `APPLE_ID`: Apple ID 邮箱
- `APPLE_ID_PASSWORD`: App-specific 密码

#### Provisioning Profile（如需要）
- `PROVISIONING_PROFILE`: 描述文件的 Base64 编码

## 设置步骤

### 1. 获取开发者证书

```bash
# 导出证书为 P12 格式
# 在 Keychain Access 中选择证书 > 右键 > 导出

# 转换为 Base64
base64 -i certificate.p12 -o certificate-base64.txt
```

### 2. 获取 App-specific 密码

1. 登录 [appleid.apple.com](https://appleid.apple.com)
2. 生成 App-specific 密码
3. 保存该密码作为 `APPLE_ID_PASSWORD`

### 3. 查找 Team ID

```bash
# 使用 Xcode 命令行工具
xcrun altool --list-providers -u "your-apple-id@email.com" -p "app-specific-password"
```

### 4. 本地测试构建

```bash
# 测试基础构建
xcodebuild -scheme PromptPal -destination 'platform=macOS' build

# 测试 Archive
xcodebuild -scheme PromptPal -destination 'platform=macOS' -configuration Release -archivePath PromptPal.xcarchive archive
```

## 发布流程

### 开发构建
1. 推送代码到 `main` 或 `develop` 分支
2. 自动触发构建和测试
3. 构建产物保存 7 天

### 正式发布
1. 创建并推送新的版本标签：
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
2. 自动触发两个 workflow：
   - 未签名版本（用于测试）
   - 签名版本（用于分发）
3. 自动创建 GitHub Release
4. DMG 文件自动上传到 Release

## 故障排除

### 常见问题

#### 1. 证书问题
```
Code signing failed
```
**解决方案:**
- 检查证书是否过期
- 确认 Team ID 正确
- 验证 P12 密码

#### 2. 公证失败
```
Notarization failed
```
**解决方案:**
- 检查 Apple ID 和密码
- 确认应用满足公证要求
- 检查网络连接

#### 3. 构建超时
```
Job exceeded maximum time
```
**解决方案:**
- 优化依赖缓存
- 减少并发构建
- 使用更快的 runner

### 调试命令

```bash
# 检查签名状态
codesign -dv --verbose=4 /path/to/app

# 验证公证状态
spctl -a -vvv -t install /path/to/app

# 检查 DMG
hdiutil verify /path/to/dmg
```

## 性能优化

### 1. 构建缓存
- Xcode DerivedData 缓存
- Swift Package Manager 缓存
- CocoaPods 缓存（如使用）

### 2. 并行构建
```yaml
strategy:
  matrix:
    configuration: [Debug, Release]
```

### 3. 条件构建
- 仅在 Release 时签名
- 跳过不必要的步骤

## 安全建议

1. **限制 Secrets 访问**
   - 仅在必要的 workflow 中使用
   - 定期轮换密码

2. **分离环境**
   - 开发环境使用自签名证书
   - 生产环境使用 Developer ID

3. **审计日志**
   - 监控构建历史
   - 检查异常活动

## 扩展功能

### 自动版本号
```yaml
- name: Bump version
  run: |
    agvtool next-version -all
    agvtool new-marketing-version ${{ github.event.release.tag_name }}
```

### 自动更新检查
```yaml
- name: Setup Sparkle
  run: |
    # 配置 Sparkle 自动更新
```

### 多架构支持
```yaml
- name: Build Universal Binary
  run: |
    xcodebuild -scheme PromptPal -destination 'platform=macOS,arch=x86_64' -destination 'platform=macOS,arch=arm64' build
``` 