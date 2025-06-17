#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
本地化验证脚本
验证所有支持语言的翻译文件完整性
"""

import os
import re
import sys
from pathlib import Path

# 支持的语言列表
SUPPORTED_LANGUAGES = ['en', 'zh-Hans']

# 项目根目录
PROJECT_ROOT = Path(__file__).parent.parent
RESOURCES_DIR = PROJECT_ROOT / 'PromptPal' / 'Resources'

def parse_strings_file(file_path):
    """解析 .strings 文件，提取键值对"""
    if not file_path.exists():
        return {}
    
    strings = {}
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # 匹配本地化键值对的正则表达式
        pattern = r'"([^"]+)"\s*=\s*"([^"]*?)";'
        matches = re.findall(pattern, content, re.MULTILINE | re.DOTALL)
        
        for key, value in matches:
            strings[key] = value.strip()
            
    except Exception as e:
        print(f"❌ 解析文件失败 {file_path}: {e}")
        
    return strings

def validate_localization():
    """验证本地化文件"""
    print("🔍 开始验证本地化文件...")
    print(f"📁 资源目录: {RESOURCES_DIR}")
    
    # 存储每种语言的键
    language_keys = {}
    
    # 解析所有语言的字符串文件
    for lang in SUPPORTED_LANGUAGES:
        lang_dir = RESOURCES_DIR / f"{lang}.lproj"
        strings_file = lang_dir / "Localizable.strings"
        
        print(f"\n🌍 检查语言: {lang}")
        print(f"📄 文件路径: {strings_file}")
        
        if not strings_file.exists():
            print(f"❌ 文件不存在: {strings_file}")
            continue
            
        keys = parse_strings_file(strings_file)
        language_keys[lang] = keys
        print(f"✅ 找到 {len(keys)} 个翻译键")
    
    if not language_keys:
        print("❌ 未找到任何本地化文件")
        return False
    
    # 以英文为基准检查缺失的键
    base_lang = 'en'
    if base_lang not in language_keys:
        print(f"❌ 基准语言 {base_lang} 不存在")
        return False
    
    base_keys = set(language_keys[base_lang].keys())
    print(f"\n📊 基准语言 ({base_lang}) 包含 {len(base_keys)} 个键")
    
    # 检查每种语言的完整性
    all_valid = True
    
    for lang, keys in language_keys.items():
        if lang == base_lang:
            continue
            
        lang_keys = set(keys.keys())
        missing_keys = base_keys - lang_keys
        extra_keys = lang_keys - base_keys
        
        print(f"\n🔍 检查语言: {lang}")
        
        if missing_keys:
            print(f"❌ 缺失 {len(missing_keys)} 个键:")
            for key in sorted(missing_keys):
                print(f"   • {key}")
            all_valid = False
        
        if extra_keys:
            print(f"⚠️  多余 {len(extra_keys)} 个键:")
            for key in sorted(extra_keys):
                print(f"   • {key}")
        
        if not missing_keys and not extra_keys:
            print(f"✅ 翻译完整")
    
    # 检查空值
    print(f"\n🔍 检查空翻译...")
    for lang, keys in language_keys.items():
        empty_keys = [key for key, value in keys.items() if not value.strip()]
        
        if empty_keys:
            print(f"❌ {lang} 中有 {len(empty_keys)} 个空翻译:")
            for key in sorted(empty_keys):
                print(f"   • {key}")
            all_valid = False
        else:
            print(f"✅ {lang} 无空翻译")
    
    # 总结
    print(f"\n{'='*50}")
    if all_valid:
        print("🎉 所有本地化文件验证通过！")
        return True
    else:
        print("❌ 发现本地化问题，请修复后重试")
        return False

def generate_missing_keys_template():
    """生成缺失键的模板"""
    print("\n📝 生成缺失键模板...")
    
    # 这里可以添加自动生成缺失键模板的逻辑
    # 例如创建待翻译的文件
    
def main():
    """主函数"""
    print("🌍 PromptPal 本地化验证工具")
    print("="*50)
    
    if not RESOURCES_DIR.exists():
        print(f"❌ 资源目录不存在: {RESOURCES_DIR}")
        sys.exit(1)
    
    success = validate_localization()
    
    if not success:
        print("\n💡 建议:")
        print("1. 检查缺失的翻译键")
        print("2. 删除多余的键")
        print("3. 补充空的翻译值")
        print("4. 运行脚本重新验证")
        sys.exit(1)
    
    print("\n🚀 本地化验证完成!")

if __name__ == "__main__":
    main() 