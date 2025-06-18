#!/bin/bash

# 本地构建测试脚本
# 直接运行 xcodebuild 命令，不依赖 Docker 或 act

set -e

SCHEME_NAME="PromptPal"
PRODUCT_NAME="PromptPal"

echo "🏗️  PromptPal 本地构建测试"
echo "==========================="

# 检查 Xcode
check_xcode() {
    echo "📋 检查 Xcode 环境..."
    
    if ! command -v xcodebuild &> /dev/null; then
        echo "❌ xcodebuild 未找到，请安装 Xcode"
        exit 1
    fi
    
    echo "✅ Xcode 版本:"
    xcodebuild -version
    
    echo ""
    echo "✅ 可用的 SDK:"
    xcodebuild -showsdks | grep macOS
}

# 列出可用的 schemes
list_schemes() {
    echo ""
    echo "📋 项目 Schemes:"
    xcodebuild -list
}

# 测试依赖解析
test_dependencies() {
    echo ""
    echo "📦 测试依赖解析..."
    
    if [ -f "Package.swift" ]; then
        echo "发现 Swift Package，解析依赖..."
        xcodebuild -resolvePackageDependencies -scheme "$SCHEME_NAME"
        echo "✅ 依赖解析成功"
    else
        echo "✅ 无 Swift Package 依赖"
    fi
}

# 测试编译
test_build() {
    echo ""
    echo "🔨 测试 Debug 构建..."
    
    xcodebuild \
        -scheme "$SCHEME_NAME" \
        -destination 'platform=macOS' \
        -configuration Debug \
        build
        
    echo "✅ Debug 构建成功"
}

# 测试 Release 构建
test_release_build() {
    echo ""
    echo "🚀 测试 Release 构建..."
    
    xcodebuild \
        -scheme "$SCHEME_NAME" \
        -destination 'platform=macOS' \
        -configuration Release \
        build
        
    echo "✅ Release 构建成功"
}

# 测试运行单元测试
test_unit_tests() {
    echo ""
    echo "🧪 运行单元测试..."
    
    xcodebuild \
        -scheme "$SCHEME_NAME" \
        -destination 'platform=macOS' \
        -configuration Debug \
        test
        
    echo "✅ 单元测试通过"
}

# 测试 Archive
test_archive() {
    echo ""
    echo "📦 测试 Archive..."
    
    ARCHIVE_PATH="./build/${PRODUCT_NAME}.xcarchive"
    
    # 清理之前的构建
    rm -rf ./build
    mkdir -p ./build
    
    xcodebuild \
        -scheme "$SCHEME_NAME" \
        -destination 'platform=macOS' \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH" \
        archive
        
    echo "✅ Archive 创建成功: $ARCHIVE_PATH"
    
    # 检查 Archive 内容
    if [ -d "$ARCHIVE_PATH" ]; then
        echo ""
        echo "📋 Archive 内容:"
        find "$ARCHIVE_PATH" -name "*.app" -type d
    fi
}

# 测试导出 App
test_export() {
    echo ""
    echo "📤 测试导出 App..."
    
    ARCHIVE_PATH="./build/${PRODUCT_NAME}.xcarchive"
    EXPORT_PATH="./build/export"
    
    if [ ! -d "$ARCHIVE_PATH" ]; then
        echo "❌ Archive 不存在，请先运行 archive 测试"
        return 1
    fi
    
    # 创建临时的 ExportOptions.plist（用于开发版本）
    cat > ./build/ExportOptionsLocal.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>destination</key>
    <string>export</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadSymbols</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF
    
    xcodebuild \
        -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist ./build/ExportOptionsLocal.plist
        
    echo "✅ App 导出成功: $EXPORT_PATH"
    
    # 检查导出的 App
    if [ -d "$EXPORT_PATH/${PRODUCT_NAME}.app" ]; then
        echo ""
        echo "📱 导出的 App 信息:"
        ls -la "$EXPORT_PATH/${PRODUCT_NAME}.app"
        
        echo ""
        echo "🔍 App 签名信息:"
        codesign -dv "$EXPORT_PATH/${PRODUCT_NAME}.app" 2>&1 || echo "❌ 无签名或签名验证失败"
    fi
}

# 创建 DMG（简化版本）
test_dmg() {
    echo ""
    echo "💿 测试 DMG 创建..."
    
    EXPORT_PATH="./build/export"
    APP_PATH="$EXPORT_PATH/${PRODUCT_NAME}.app"
    
    if [ ! -d "$APP_PATH" ]; then
        echo "❌ App 不存在，请先运行 export 测试"
        return 1
    fi
    
    # 创建 DMG 临时目录
    DMG_TEMP="./build/dmg_temp"
    rm -rf "$DMG_TEMP"
    mkdir -p "$DMG_TEMP"
    
    # 复制 App 到临时目录
    cp -R "$APP_PATH" "$DMG_TEMP/"
    
    # 创建应用程序快捷方式
    ln -s /Applications "$DMG_TEMP/Applications"
    
    # 创建 DMG
    DMG_NAME="${PRODUCT_NAME}-local-test.dmg"
    hdiutil create \
        -volname "$PRODUCT_NAME" \
        -srcfolder "$DMG_TEMP" \
        -ov \
        -format UDZO \
        "./build/$DMG_NAME"
        
    echo "✅ DMG 创建成功: ./build/$DMG_NAME"
    
    # 验证 DMG
    echo ""
    echo "🔍 验证 DMG:"
    hdiutil verify "./build/$DMG_NAME" && echo "✅ DMG 验证通过"
}

# 清理构建产物
clean_build() {
    echo ""
    echo "🧹 清理构建产物..."
    
    rm -rf ./build
    
    # 清理 Xcode DerivedData
    if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
        echo "清理 DerivedData..."
        rm -rf ~/Library/Developer/Xcode/DerivedData/*PromptPal*
    fi
    
    echo "✅ 清理完成"
}

# 显示构建总结
show_summary() {
    echo ""
    echo "📊 构建总结"
    echo "============"
    
    if [ -d "./build" ]; then
        echo "构建产物:"
        find ./build -type f -name "*.app" -o -name "*.xcarchive" -o -name "*.dmg" | while read file; do
            echo "  📁 $file"
            echo "     大小: $(du -h "$file" | cut -f1)"
        done
    else
        echo "无构建产物"
    fi
}

# 主函数
main() {
    case "${1:-all}" in
        "check")
            check_xcode
            list_schemes
            ;;
        "deps")
            check_xcode
            test_dependencies
            ;;
        "build")
            check_xcode
            test_dependencies
            test_build
            ;;
        "release")
            check_xcode
            test_dependencies
            test_release_build
            ;;
        "test")
            check_xcode
            test_dependencies
            test_unit_tests
            ;;
        "archive")
            check_xcode
            test_dependencies
            test_archive
            ;;
        "export")
            test_export
            ;;
        "dmg")
            test_dmg
            ;;
        "clean")
            clean_build
            ;;
        "full")
            check_xcode
            test_dependencies
            test_build
            test_release_build
            test_unit_tests
            test_archive
            test_export
            test_dmg
            show_summary
            ;;
        "all"|"")
            check_xcode
            list_schemes
            test_dependencies
            test_build
            show_summary
            ;;
        *)
            echo "用法: $0 [check|deps|build|release|test|archive|export|dmg|clean|full|all]"
            echo ""
            echo "选项:"
            echo "  check    - 检查 Xcode 环境"
            echo "  deps     - 测试依赖解析"
            echo "  build    - 测试 Debug 构建"
            echo "  release  - 测试 Release 构建"
            echo "  test     - 运行单元测试"
            echo "  archive  - 测试 Archive"
            echo "  export   - 测试导出 App"
            echo "  dmg      - 测试创建 DMG"
            echo "  clean    - 清理构建产物"
            echo "  full     - 完整构建流程"
            echo "  all      - 基础测试（默认）"
            ;;
    esac
}

main "$@" 