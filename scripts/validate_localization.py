#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Localization Validation Script
Validate the completeness of translation files for all supported languages
"""

import os
import re
import sys
from pathlib import Path

# Supported languages list
SUPPORTED_LANGUAGES = ['en', 'zh-Hans']

# Project root directory
PROJECT_ROOT = Path(__file__).parent.parent
RESOURCES_DIR = PROJECT_ROOT / 'PromptPal' / 'Resources'

def parse_strings_file(file_path):
    """Parse .strings file and extract key-value pairs"""
    if not file_path.exists():
        return {}
    
    strings = {}
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Regular expression to match localized key-value pairs
        pattern = r'"([^"]+)"\s*=\s*"([^"]*?)";'
        matches = re.findall(pattern, content, re.MULTILINE | re.DOTALL)
        
        for key, value in matches:
            strings[key] = value.strip()
            
    except Exception as e:
        print(f"❌ Failed to parse file {file_path}: {e}")
        
    return strings

def validate_localization():
    """Validate localization files"""
    print("🔍 Starting localization validation...")
    print(f"📁 Resources directory: {RESOURCES_DIR}")
    
    # Store keys for each language
    language_keys = {}
    
    # Parse string files for all languages
    for lang in SUPPORTED_LANGUAGES:
        lang_dir = RESOURCES_DIR / f"{lang}.lproj"
        strings_file = lang_dir / "Localizable.strings"
        
        print(f"\n🌍 Checking language: {lang}")
        print(f"📄 File path: {strings_file}")
        
        if not strings_file.exists():
            print(f"❌ File does not exist: {strings_file}")
            continue
            
        keys = parse_strings_file(strings_file)
        language_keys[lang] = keys
        print(f"✅ Found {len(keys)} translation keys")
    
    if not language_keys:
        print("❌ No localization files found")
        return False
    
    # Check for missing keys using English as base
    base_lang = 'en'
    if base_lang not in language_keys:
        print(f"❌ Base language {base_lang} does not exist")
        return False
    
    base_keys = set(language_keys[base_lang].keys())
    print(f"\n📊 Base language ({base_lang}) contains {len(base_keys)} keys")
    
    # Check completeness for each language
    all_valid = True
    
    for lang, keys in language_keys.items():
        if lang == base_lang:
            continue
            
        lang_keys = set(keys.keys())
        missing_keys = base_keys - lang_keys
        extra_keys = lang_keys - base_keys
        
        print(f"\n🔍 Checking language: {lang}")
        
        if missing_keys:
            print(f"❌ Missing {len(missing_keys)} keys:")
            for key in sorted(missing_keys):
                print(f"   • {key}")
            all_valid = False
        
        if extra_keys:
            print(f"⚠️  Extra {len(extra_keys)} keys:")
            for key in sorted(extra_keys):
                print(f"   • {key}")
        
        if not missing_keys and not extra_keys:
            print(f"✅ Translation complete")
    
    # Check for empty values
    print(f"\n🔍 Checking empty translations...")
    for lang, keys in language_keys.items():
        empty_keys = [key for key, value in keys.items() if not value.strip()]
        
        if empty_keys:
            print(f"❌ {lang} has {len(empty_keys)} empty translations:")
            for key in sorted(empty_keys):
                print(f"   • {key}")
            all_valid = False
        else:
            print(f"✅ {lang} has no empty translations")
    
    # Summary
    print(f"\n{'='*50}")
    if all_valid:
        print("🎉 All localization files validated successfully!")
        return True
    else:
        print("❌ Found localization issues, please fix and retry")
        return False

def generate_missing_keys_template():
    """Generate template for missing keys"""
    print("\n📝 Generating missing keys template...")
    
    # Logic for automatically generating missing keys template can be added here
    # For example, creating files for pending translations
    
def main():
    """Main function"""
    print("🌍 PromptPal Localization Validation Tool")
    print("="*50)
    
    if not RESOURCES_DIR.exists():
        print(f"❌ Resources directory does not exist: {RESOURCES_DIR}")
        sys.exit(1)
    
    success = validate_localization()
    
    if not success:
        print("\n💡 Suggestions:")
        print("1. Check missing translation keys")
        print("2. Remove extra keys")
        print("3. Fill in empty translation values")
        print("4. Run script again to re-validate")
        sys.exit(1)
    
    print("\n🚀 Localization validation completed!")

if __name__ == "__main__":
    main() 