#!/bin/bash

# Firebase plist 原始内容设置脚本
# 用于为GitHub Actions生成原始XML内容的GoogleService-Info.plist

set -e

echo "🔥 Firebase Plist 原始内容配置设置"
echo "===================================="

# 检查GoogleService-Info.plist文件是否存在
PLIST_PATH="./Promptly/GoogleService-Info.plist"

if [ ! -f "$PLIST_PATH" ]; then
    echo "❌ 错误: 找不到 GoogleService-Info.plist 文件"
    echo "   请确保文件位于: $PLIST_PATH"
    echo ""
    echo "💡 提示: 您需要先从Firebase Console下载此文件"
    exit 1
fi

echo "✅ 找到 GoogleService-Info.plist 文件"

# 读取plist文件原始内容
echo ""
echo "🔄 读取plist文件原始内容..."
PLIST_CONTENT=$(cat "$PLIST_PATH")

# 复制到剪贴板
echo "$PLIST_CONTENT" | pbcopy
echo "✅ plist文件原始内容已复制到剪贴板"

echo ""
echo "📋 下一步操作:"
echo "1. 打开GitHub仓库页面"
echo "2. 进入 Settings → Secrets and variables → Actions"
echo "3. 点击 'New repository secret'"
echo "4. Secret名称: GOOGLE_SERVICE_INFO_PLIST"
echo "5. Secret值: 粘贴剪贴板内容 (Cmd+V)"
echo "6. 点击 'Add secret'"

echo ""
echo "⚠️  重要提醒:"
echo "- 确保粘贴完整的XML内容，包括所有换行符"
echo "- 检查Secret中的内容格式正确"
echo "- XML开头应该是: <?xml version=\"1.0\" encoding=\"UTF-8\"?>"

echo ""
echo "🔒 安全提醒:"
echo "- 设置Secret后，请删除本地的 GoogleService-Info.plist 文件"
echo "- 确保该文件已在 .gitignore 中"
echo "- 从此以后，CI/CD将自动从Secret生成此文件"

echo ""
echo "🧹 清理本地文件:"
read -p "是否现在删除本地的 GoogleService-Info.plist 文件? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm "$PLIST_PATH"
    echo "✅ 已删除本地 GoogleService-Info.plist 文件"
else
    echo "⚠️  请记住手动删除该文件以确保安全"
fi

echo ""
echo "🎉 原始plist内容设置完成！"
echo "现在您的CI/CD工作流将直接使用原始XML内容。" 