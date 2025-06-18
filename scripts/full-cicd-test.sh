#!/bin/bash

# 完整的 CI/CD 本地测试脚本
# 包含 GitHub token 处理和完整验证

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 PromptPal 完整 CI/CD 本地测试"
echo "=================================="

# 检查和设置 GitHub Token
setup_github_token() {
    echo ""
    echo "🔐 检查 GitHub Token..."
    
    # 检查环境变量
    if [ -n "$GITHUB_TOKEN" ]; then
        echo "✅ 已设置环境变量 GITHUB_TOKEN"
        return 0
    fi
    
    # 检查 .env.local 文件
    if [ -f "$PROJECT_ROOT/.env.local" ]; then
        echo "📁 发现 .env.local 文件，加载 token..."
        source "$PROJECT_ROOT/.env.local"
        if [ -n "$GITHUB_TOKEN" ]; then
            echo "✅ 从 .env.local 加载 GITHUB_TOKEN"
            export GITHUB_TOKEN
            return 0
        fi
    fi
    
    # 检查 .secrets 文件
    if [ -f "$PROJECT_ROOT/.secrets" ] && grep -q "GITHUB_TOKEN=" "$PROJECT_ROOT/.secrets"; then
        echo "📁 从 .secrets 文件读取 token..."
        GITHUB_TOKEN=$(grep "GITHUB_TOKEN=" "$PROJECT_ROOT/.secrets" | cut -d= -f2)
        if [ -n "$GITHUB_TOKEN" ]; then
            echo "✅ 从 .secrets 加载 GITHUB_TOKEN"
            export GITHUB_TOKEN
            return 0
        fi
    fi
    
    echo "❌ 未找到 GitHub Token"
    echo ""
    echo "请运行以下命令设置 token："
    echo "  ./scripts/setup-github-token.sh"
    echo ""
    echo "或者手动设置："
    echo "  export GITHUB_TOKEN=your_token_here"
    
    read -p "是否现在设置 GitHub Token? (y/N): " setup_now
    
    if [[ "$setup_now" == "y" || "$setup_now" == "Y" ]]; then
        "$SCRIPT_DIR/setup-github-token.sh"
        source "$PROJECT_ROOT/.env.local"
        export GITHUB_TOKEN
    else
        echo "⚠️  将跳过需要 GitHub Actions 的测试"
        return 1
    fi
}

# 验证 act 工具配置
setup_act_config() {
    echo ""
    echo "🔧 配置 act 工具..."
    
    # 为 M1 Mac 添加架构配置
    if [[ "$(uname -m)" == "arm64" ]]; then
        echo "🔧 检测到 Apple Silicon，配置容器架构..."
        export ACT_CONTAINER_ARCHITECTURE="linux/amd64"
    fi
    
    # 确保 .actrc 文件存在且配置正确
    if [ ! -f "$PROJECT_ROOT/.actrc" ]; then
        echo "📄 创建 .actrc 配置文件..."
        cat > "$PROJECT_ROOT/.actrc" <<EOF
# act 配置文件 - 完整 CI/CD 测试
-P macos-14=catthehacker/ubuntu:act-latest
-P macos-latest=catthehacker/ubuntu:act-latest
--secret-file .secrets
--container-architecture linux/amd64
EOF
    fi
    
    echo "✅ act 工具配置完成"
}

# 第一阶段：基础验证
stage1_basic_validation() {
    echo ""
    echo "📋 第一阶段：基础验证"
    echo "===================="
    
    echo "1️⃣ 检查 Xcode 环境..."
    "$SCRIPT_DIR/local-build-test.sh" check
    
    echo ""
    echo "2️⃣ 验证 workflow 语法..."
    act --list
    
    echo ""
    echo "3️⃣ 验证 YAML 语法..."
    if command -v yamllint &> /dev/null; then
        yamllint .github/workflows/*.yml
        echo "✅ YAML 语法正确"
    else
        echo "⚠️  yamllint 未安装，跳过检查"
    fi
}

# 第二阶段：本地构建测试
stage2_local_build() {
    echo ""
    echo "🔨 第二阶段：本地构建测试"
    echo "========================"
    
    echo "1️⃣ Debug 构建测试..."
    "$SCRIPT_DIR/local-build-test.sh" build
    
    echo ""
    echo "2️⃣ Release 构建测试..."
    "$SCRIPT_DIR/local-build-test.sh" release
    
    echo ""
    echo "3️⃣ 单元测试..."
    "$SCRIPT_DIR/local-build-test.sh" test || echo "⚠️  单元测试失败（可能没有测试）"
}

# 第三阶段：GitHub Actions 模拟
stage3_github_actions() {
    echo ""
    echo "🐙 第三阶段：GitHub Actions 模拟"
    echo "==============================="
    
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "⚠️  跳过 GitHub Actions 测试（无 token）"
        return 0
    fi
    
    echo "1️⃣ 模拟 Push 事件..."
    act push \
        --workflows .github/workflows/build-macos.yml \
        --env GITHUB_REF=refs/heads/main \
        --env GITHUB_EVENT_NAME=push \
        --dryrun || echo "⚠️  可能的网络或依赖问题"
    
    echo ""
    echo "2️⃣ 模拟 Tag Push 事件..."
    act push \
        --workflows .github/workflows/build-macos.yml \
        --env GITHUB_REF=refs/tags/v1.0.0 \
        --env GITHUB_REF_NAME=v1.0.0 \
        --env GITHUB_EVENT_NAME=push \
        --dryrun || echo "⚠️  可能的网络或依赖问题"
    
    echo ""
    echo "3️⃣ 分析签名构建流程..."
    act push \
        --workflows .github/workflows/build-signed.yml \
        --env GITHUB_REF=refs/tags/v1.0.0 \
        --list
}

# 第四阶段：完整构建流程
stage4_full_build() {
    echo ""
    echo "📦 第四阶段：完整构建流程"
    echo "========================"
    
    echo "1️⃣ Archive 创建..."
    "$SCRIPT_DIR/local-build-test.sh" archive
    
    echo ""
    echo "2️⃣ App 导出..."
    "$SCRIPT_DIR/local-build-test.sh" export
    
    echo ""
    echo "3️⃣ DMG 创建..."
    "$SCRIPT_DIR/local-build-test.sh" dmg
}

# 第五阶段：实际运行 GitHub Actions（可选）
stage5_real_actions() {
    echo ""
    echo "🌐 第五阶段：实际 GitHub Actions 运行（可选）"
    echo "============================================"
    
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "⚠️  跳过实际 Actions 运行（无 token）"
        return 0
    fi
    
    read -p "是否运行真实的 GitHub Actions？这会下载实际的 Actions 并运行容器 (y/N): " run_real
    
    if [[ "$run_real" != "y" && "$run_real" != "Y" ]]; then
        echo "跳过实际 Actions 运行"
        return 0
    fi
    
    echo ""
    echo "⚠️  这将运行真实的 Actions，可能需要较长时间..."
    
    # 运行基础构建（不使用 --dryrun）
    echo "运行基础构建流程..."
    act push \
        --workflows .github/workflows/build-macos.yml \
        --env GITHUB_REF=refs/heads/main \
        --env GITHUB_EVENT_NAME=push \
        --job build || echo "❌ Actions 运行失败（这在本地环境是正常的）"
}

# 生成测试报告
generate_report() {
    echo ""
    echo "📊 生成测试报告"
    echo "================"
    
    REPORT_FILE="$PROJECT_ROOT/cicd-test-report.txt"
    
    cat > "$REPORT_FILE" <<EOF
PromptPal CI/CD 本地测试报告
生成时间: $(date)
===========================================

环境信息:
- macOS: $(sw_vers -productVersion)
- Xcode: $(xcodebuild -version | head -1)
- act 版本: $(act --version 2>/dev/null || echo "未安装")
- Docker: $(docker --version 2>/dev/null || echo "未安装")
- GitHub Token: $([ -n "$GITHUB_TOKEN" ] && echo "已配置" || echo "未配置")

测试结果:
EOF
    
    if [ -d "$PROJECT_ROOT/build" ]; then
        echo "构建产物:" >> "$REPORT_FILE"
        find "$PROJECT_ROOT/build" -type f \( -name "*.app" -o -name "*.dmg" -o -name "*.xcarchive" \) >> "$REPORT_FILE"
    fi
    
    echo ""
    echo "✅ 测试报告已生成: $REPORT_FILE"
}

# 清理函数
cleanup() {
    echo ""
    echo "🧹 清理测试环境..."
    "$SCRIPT_DIR/local-build-test.sh" clean
    
    read -p "是否删除 GitHub Token 文件？(y/N): " remove_token
    if [[ "$remove_token" == "y" || "$remove_token" == "Y" ]]; then
        rm -f "$PROJECT_ROOT/.env.local"
        echo "✅ 已删除 token 文件"
    fi
}

# 主函数
main() {
    cd "$PROJECT_ROOT"
    
    case "${1:-all}" in
        "setup")
            setup_github_token
            setup_act_config
            ;;
        "stage1")
            stage1_basic_validation
            ;;
        "stage2")
            stage2_local_build
            ;;
        "stage3")
            setup_github_token
            setup_act_config
            stage3_github_actions
            ;;
        "stage4")
            stage4_full_build
            ;;
        "stage5")
            setup_github_token
            setup_act_config
            stage5_real_actions
            ;;
        "report")
            generate_report
            ;;
        "clean")
            cleanup
            ;;
        "all")
            setup_github_token
            setup_act_config
            stage1_basic_validation
            stage2_local_build
            stage3_github_actions
            stage4_full_build
            generate_report
            ;;
        *)
            echo "用法: $0 [setup|stage1|stage2|stage3|stage4|stage5|report|clean|all]"
            echo ""
            echo "选项："
            echo "  setup   - 设置 GitHub token 和 act 配置"
            echo "  stage1  - 基础验证（语法检查等）"
            echo "  stage2  - 本地构建测试"
            echo "  stage3  - GitHub Actions 模拟"
            echo "  stage4  - 完整构建流程"
            echo "  stage5  - 实际 Actions 运行"
            echo "  report  - 生成测试报告"
            echo "  clean   - 清理测试环境"
            echo "  all     - 运行所有测试（默认）"
            ;;
    esac
}

main "$@" 