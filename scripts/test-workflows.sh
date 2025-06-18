#!/bin/bash

# 本地测试 GitHub Actions workflows
# 使用 act 工具运行

set -e

echo "🚀 PromptPal Workflows 本地测试"
echo "================================"

# 检查依赖
check_dependencies() {
    echo "📋 检查依赖工具..."
    
    if ! command -v act &> /dev/null; then
        echo "❌ act 未安装，请运行: brew install act"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker 未安装，act 需要 Docker 运行"
        exit 1
    fi
    
    echo "✅ 依赖检查通过"
}

# 测试基础构建流程
test_basic_build() {
    echo ""
    echo "🔨 测试基础构建流程..."
    echo "------------------------"
    
    echo "📋 分析 workflow 结构..."
    act push \
        --workflows .github/workflows/build-macos.yml \
        --list
    
    echo ""
    echo "🔍 Dry run 测试（可能会因为GitHub Actions依赖而失败，这是正常的）..."
    act push \
        --workflows .github/workflows/build-macos.yml \
        --platform macos-14=catthehacker/ubuntu:act-latest \
        --env GITHUB_REF=refs/heads/main \
        --env GITHUB_EVENT_NAME=push \
        --dryrun || echo "⚠️  Dry run 失败（通常因为需要下载 GitHub Actions），但这不影响 workflow 语法验证"
}

# 测试标签构建流程
test_tag_build() {
    echo ""
    echo "🏷️  测试标签构建流程..."
    echo "------------------------"
    
    echo "📋 分析标签触发的 workflow..."
    act push \
        --workflows .github/workflows/build-macos.yml \
        --env GITHUB_REF=refs/tags/v1.0.0 \
        --list
    
    echo ""
    echo "🔍 模拟标签推送事件..."
    act push \
        --workflows .github/workflows/build-macos.yml \
        --platform macos-14=catthehacker/ubuntu:act-latest \
        --env GITHUB_REF=refs/tags/v1.0.0 \
        --env GITHUB_REF_NAME=v1.0.0 \
        --env GITHUB_EVENT_NAME=push \
        --dryrun || echo "⚠️  预期的失败（需要 GitHub Actions 依赖）"
}

# 测试签名构建流程
test_signed_build() {
    echo ""
    echo "🔐 测试签名构建流程..."
    echo "------------------------"
    
    # 模拟 tag push 事件（仅显示计划）
    act push \
        --workflows .github/workflows/build-signed.yml \
        --platform macos-14=catthehacker/ubuntu:act-latest \
        --env GITHUB_REF=refs/tags/v1.0.0 \
        --env GITHUB_REF_NAME=v1.0.0 \
        --env GITHUB_EVENT_NAME=push \
        --dryrun
}

# 手动测试构建命令
test_build_commands() {
    echo ""
    echo "⚙️  测试构建命令..."
    echo "-------------------"
    
    echo "测试 Xcode 版本:"
    xcodebuild -version || echo "❌ Xcode 不可用"
    
    echo ""
    echo "测试项目编译:"
    xcodebuild \
        -scheme PromptPal \
        -destination 'platform=macOS' \
        -configuration Debug \
        -dry-run || echo "❌ 编译测试失败"
    
    echo ""
    echo "测试依赖解析:"
    if [ -f "Package.swift" ]; then
        xcodebuild -resolvePackageDependencies -scheme PromptPal || echo "❌ 依赖解析失败"
    else
        echo "✅ 无 Swift Package 依赖"
    fi
}

# 创建模拟的 secrets 文件
create_mock_secrets() {
    echo ""
    echo "📄 创建模拟 secrets 文件..."
    echo "----------------------------"
    
    cat > .secrets <<EOF
# 模拟的 GitHub Secrets（用于本地测试）
# 这些值不是真实的，仅用于测试 workflow 语法

GITHUB_TOKEN=mock_token
TEAM_ID=mock_team_id
CERTIFICATES_P12=mock_cert_base64
CERTIFICATES_P12_PASSWORD=mock_password
APPLE_ID=test@example.com
APPLE_ID_PASSWORD=mock_app_password
PROVISIONING_PROFILE=mock_profile_base64
EOF
    
    echo "✅ 模拟 secrets 已创建: .secrets"
    echo "⚠️  注意: 这些是模拟值，不要提交到代码库"
}

# 验证 workflow 语法
validate_workflows() {
    echo ""
    echo "✅ 验证 workflow 语法..."
    echo "------------------------"
    
    # 检查 YAML 语法
    if command -v yamllint &> /dev/null; then
        yamllint .github/workflows/*.yml && echo "✅ YAML 语法正确"
    else
        echo "⚠️  yamllint 未安装，跳过 YAML 语法检查"
    fi
    
    # 使用 act 验证语法
    echo ""
    echo "📋 验证 workflow 结构..."
    act --list && echo "✅ workflow 语法验证通过"
}

# 主函数
main() {
    case "${1:-all}" in
        "deps")
            check_dependencies
            ;;
        "basic")
            check_dependencies
            test_basic_build
            ;;
        "tag")
            check_dependencies
            test_tag_build
            ;;
        "signed")
            check_dependencies
            test_signed_build
            ;;
        "commands")
            test_build_commands
            ;;
        "secrets")
            create_mock_secrets
            ;;
        "validate")
            validate_workflows
            ;;
        "all")
            check_dependencies
            validate_workflows
            create_mock_secrets
            test_build_commands
            test_basic_build
            test_tag_build
            test_signed_build
            ;;
        *)
            echo "用法: $0 [deps|basic|tag|signed|commands|secrets|validate|all]"
            echo ""
            echo "选项:"
            echo "  deps     - 检查依赖"
            echo "  basic    - 测试基础构建"
            echo "  tag      - 测试标签构建"
            echo "  signed   - 测试签名构建"
            echo "  commands - 测试构建命令"
            echo "  secrets  - 创建模拟 secrets"
            echo "  validate - 验证 workflow 语法"
            echo "  all      - 运行所有测试（默认）"
            ;;
    esac
}

main "$@" 