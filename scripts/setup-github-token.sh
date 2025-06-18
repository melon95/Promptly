#!/bin/bash

# 设置 GitHub Token 用于本地测试
# 这样可以让 act 工具下载 GitHub Actions

set -e

echo "🔐 设置 GitHub Token 用于本地 CI/CD 测试"
echo "=========================================="

# 检查是否已有 token
if [ -n "$GITHUB_TOKEN" ]; then
    echo "✅ 已设置 GITHUB_TOKEN 环境变量"
    echo "Token 长度: ${#GITHUB_TOKEN} 字符"
    exit 0
fi

echo ""
echo "📋 需要创建 GitHub Personal Access Token (PAT)"
echo "步骤："
echo "1. 访问 https://github.com/settings/tokens"
echo "2. 点击 'Generate new token' > 'Generate new token (classic)'"
echo "3. 设置以下权限："
echo "   - repo (全部)"
echo "   - workflow"
echo "   - read:org"
echo "4. 生成并复制 token"

echo ""
echo "⚠️  注意: Token 只会显示一次，请妥善保存"

echo ""
read -p "是否已经创建了 GitHub Token? (y/N): " created_token

if [[ "$created_token" != "y" && "$created_token" != "Y" ]]; then
    echo "请先创建 GitHub Token，然后重新运行此脚本"
    exit 1
fi

echo ""
echo "请输入您的 GitHub Token:"
read -s github_token

if [ -z "$github_token" ]; then
    echo "❌ Token 不能为空"
    exit 1
fi

# 验证 token 格式
if [[ ! "$github_token" =~ ^gh[ps]_[A-Za-z0-9_]{36,}$ ]]; then
    echo "⚠️  Token 格式可能不正确，但继续设置..."
fi

# 创建 .env 文件
echo "GITHUB_TOKEN=$github_token" > .env.local

# 更新 .secrets 文件
if [ -f ".secrets" ]; then
    # 更新现有的 .secrets 文件
    if grep -q "GITHUB_TOKEN=" .secrets; then
        sed -i.bak "s/GITHUB_TOKEN=.*/GITHUB_TOKEN=$github_token/" .secrets
    else
        echo "GITHUB_TOKEN=$github_token" >> .secrets
    fi
else
    # 创建新的 .secrets 文件
    echo "GITHUB_TOKEN=$github_token" > .secrets
fi

echo ""
echo "✅ GitHub Token 已设置"
echo "📁 保存位置:"
echo "   - .env.local (用于环境变量)"
echo "   - .secrets (用于 act 工具)"

echo ""
echo "🔧 使用方法:"
echo "   # 加载环境变量"
echo "   source .env.local"
echo ""
echo "   # 或者一次性使用"
echo "   GITHUB_TOKEN=\$(cat .env.local | grep GITHUB_TOKEN | cut -d= -f2) ./scripts/test-workflows.sh basic"

echo ""
echo "⚠️  安全提醒:"
echo "   - .env.local 和 .secrets 已加入 .gitignore"
echo "   - 不要将 token 提交到代码库"
echo "   - 定期轮换 token" 