# Firebase 安全配置指南

## 🚨 紧急情况：API 密钥泄露处理

如果您发现 Firebase API 密钥已经泄露到公开仓库，请立即采取以下行动：

### 1. 立即行动 (必须在 24 小时内完成)

1. **撤销泄露的 API 密钥**：

   - 登录 [Firebase Console](https://console.firebase.google.com/)
   - 进入您的项目设置
   - 在"Web API Key"部分撤销当前密钥
   - 生成新的 API 密钥

2. **更新 GitHub Secrets**：

   ```bash
   # 使用提供的脚本设置新的secrets
   chmod +x scripts/setup_github_secrets.sh
   ./scripts/setup_github_secrets.sh
   ```

3. **清理 Git 历史**：
   ```bash
   # 从Git历史中移除敏感文件
   git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch Promptly/GoogleService-Info.plist' --prune-empty --tag-name-filter cat -- --all
   rm -rf .git/refs/original/
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   git push --force --all
   git push --force --tags
   ```

## 📋 所需的 GitHub Secrets

在 GitHub 仓库设置中添加以下 Secrets（Settings → Secrets and variables → Actions）：

### 方法 1: Base64 编码的 plist 文件 (推荐) 🌟

| Secret 名称                        | 描述                             | 生成方法                            |
| ---------------------------------- | -------------------------------- | ----------------------------------- |
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | Base64 编码的完整 plist 文件内容 | 使用 `scripts/setup_firebase_base64.sh` |

**优势**：
- ✅ 保持原始 plist 文件格式和结构
- ✅ 避免手动输入配置可能产生的错误
- ✅ 更简单的 CI/CD 配置
- ✅ 一次性设置，无需多个 Secret

**设置步骤**：
```bash
# 1. 确保您有 GoogleService-Info.plist 文件
# 2. 运行自动化脚本
chmod +x scripts/setup_firebase_base64.sh
./scripts/setup_firebase_base64.sh

# 3. 按照脚本提示在 GitHub 中创建 Secret
```

### 方法 2: 单独的环境变量

| Secret 名称               | 描述                  | 示例值                     |
| ------------------------- | --------------------- | -------------------------- |
| `FIREBASE_API_KEY`        | Firebase Web API 密钥 | `AIzaSy...`                |
| `FIREBASE_GCM_SENDER_ID`  | GCM 发送者 ID         | `123456789`                |
| `FIREBASE_BUNDLE_ID`      | iOS 应用 Bundle ID    | `melon95.Promptly`         |
| `FIREBASE_PROJECT_ID`     | Firebase 项目 ID      | `your-project-id`          |
| `FIREBASE_STORAGE_BUCKET` | Firebase 存储桶       | `your-project.appspot.com` |
| `FIREBASE_GOOGLE_APP_ID`  | Google 应用 ID        | `1:123:ios:abc123`         |

## 🛠️ 本地开发设置

1. **创建本地环境文件**：

   ```bash
   chmod +x scripts/setup_local_dev.sh
   ./scripts/setup_local_dev.sh
   ```

2. **手动设置** (如果脚本失败)：
   - 复制 `Promptly/GoogleService-Info.plist.template` 到 `Promptly/GoogleService-Info.plist`
   - 替换所有 `${VARIABLE_NAME}` 为实际值

## 🔒 安全最佳实践

### 1. 文件保护

- ✅ **GoogleService-Info.plist** 已添加到 `.gitignore`
- ✅ **其他敏感文件** 已被保护
- ❌ **绝不提交** 包含真实 API 密钥的文件

### 2. CI/CD 安全

- ✅ 使用 GitHub Secrets 存储敏感信息
- ✅ 在构建时动态生成配置文件
- ✅ 构建后自动清理敏感文件

### 3. 访问控制

- 限制 Firebase 项目的访问权限
- 定期轮换 API 密钥
- 监控 API 使用情况

## 🚀 CI/CD 工作流程

GitHub Actions 现在会：

### Base64 方法 (推荐)：
1. 📥 从 `GOOGLE_SERVICE_INFO_PLIST_BASE64` Secret 读取 Base64 编码内容
2. 🔓 解码 Base64 内容并创建 `GoogleService-Info.plist` 文件
3. 🔨 构建应用
4. 🧹 构建完成后自动清理敏感文件

**关键步骤**：
```yaml
- name: Create GoogleService-Info.plist from Secret
  run: |
    echo "${{ secrets.GOOGLE_SERVICE_INFO_PLIST_BASE64 }}" | base64 --decode > Promptly/GoogleService-Info.plist

- name: Clean up sensitive files
  run: |
    rm -f Promptly/GoogleService-Info.plist
```

### 环境变量方法：
1. 📥 从多个 Secrets 读取 Firebase 配置
2. 🔧 使用模板生成实际配置文件  
3. 🔨 构建应用
4. 🧹 清理临时文件

## 📞 紧急联系

如果遇到安全问题：

1. 立即撤销泄露的密钥
2. 通知团队成员
3. 检查 Firebase 使用情况是否异常
4. 更新所有相关系统

## 🔄 恢复流程

如果需要恢复到安全状态：

1. 确认所有敏感文件已从 Git 历史移除
2. 验证新的 API 密钥正常工作
3. 确认 CI/CD 流程正常运行
4. 监控 Firebase 使用情况
