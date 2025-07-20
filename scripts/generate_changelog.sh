#!/bin/bash

# 本地测试git-cliff生成changelog的脚本
# 使用方法: ./scripts/generate_changelog.sh

set -e

echo "🔍 检查git-cliff是否已安装..."
if ! command -v git-cliff &> /dev/null; then
    echo "❌ git-cliff 未安装。请运行以下命令安装："
    echo "cargo install git-cliff"
    echo "或者使用Homebrew: brew install git-cliff"
    exit 1
fi

echo "✅ git-cliff 已安装"

echo "📝 生成完整的changelog..."
git-cliff --output CHANGELOG.md

echo "📄 生成当前版本的release notes..."
git-cliff --latest --strip all > release_notes.md

echo "✅ 生成完成!"
echo "📋 查看生成的文件:"
echo "  - CHANGELOG.md (完整的changelog)"
echo "  - release_notes.md (当前版本的release notes)"

if [ -s release_notes.md ]; then
    echo ""
    echo "🎉 当前版本的release notes预览:"
    echo "================================"
    cat release_notes.md
    echo "================================"
else
    echo "⚠️  release_notes.md 为空，可能是因为没有新的提交或标签"
fi 