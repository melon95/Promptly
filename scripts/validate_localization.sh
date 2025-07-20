#!/bin/bash

# Localization Validation Script
# Validate the completeness of translation files for all supported languages

# Supported languages list
SUPPORTED_LANGUAGES=("en" "zh-Hans")

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESOURCES_DIR="$PROJECT_ROOT/Promptly/Resources"

# Function to parse .strings file and extract keys
parse_strings_file() {
    local file_path="$1"
    local temp_file="$2"
    
    if [ ! -f "$file_path" ]; then
        return 1
    fi
    
    # Extract key-value pairs using grep and sed
    # Pattern: "key" = "value";
    grep -o '"[^"]*"[[:space:]]*=[[:space:]]*"[^"]*";' "$file_path" | \
    sed 's/^"\([^"]*\)"[[:space:]]*=[[:space:]]*"\([^"]*\)";$/\1|\2/' > "$temp_file"
    
    return 0
}

# Function to get keys from a temp file
get_keys_from_file() {
    local temp_file="$1"
    if [ -f "$temp_file" ]; then
        cut -d'|' -f1 "$temp_file" | sort
    fi
}

# Function to get empty keys from a temp file
get_empty_keys() {
    local temp_file="$1"
    if [ -f "$temp_file" ]; then
        awk -F'|' '$2 == "" || $2 ~ /^[[:space:]]*$/ {print $1}' "$temp_file" | sort
    fi
}

# Function to validate localization
validate_localization() {
    echo "🔍 Starting localization validation..."
    echo "📁 Resources directory: $RESOURCES_DIR"
    
    # Check if resources directory exists
    if [ ! -d "$RESOURCES_DIR" ]; then
        echo "❌ Resources directory does not exist: $RESOURCES_DIR"
        return 1
    fi
    
    # Create temporary directory for processing
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    local has_files=false
    local all_valid=true
    
    # Parse string files for all languages
    for lang in "${SUPPORTED_LANGUAGES[@]}"; do
        local lang_dir="$RESOURCES_DIR/${lang}.lproj"
        local strings_file="$lang_dir/Localizable.strings"
        local temp_file="$temp_dir/${lang}.temp"
        
        echo ""
        echo "🌍 Checking language: $lang"
        echo "📄 File path: $strings_file"
        
        if [ ! -f "$strings_file" ]; then
            echo "❌ File does not exist: $strings_file"
            continue
        fi
        
        if parse_strings_file "$strings_file" "$temp_file"; then
            local key_count=$(wc -l < "$temp_file" 2>/dev/null || echo "0")
            echo "✅ Found $key_count translation keys"
            has_files=true
        else
            echo "❌ Failed to parse file: $strings_file"
            continue
        fi
    done
    
    if [ "$has_files" = false ]; then
        echo "❌ No localization files found"
        return 1
    fi
    
    # Check for missing keys using English as base
    local base_lang="en"
    local base_temp_file="$temp_dir/${base_lang}.temp"
    
    if [ ! -f "$base_temp_file" ]; then
        echo "❌ Base language $base_lang does not exist"
        return 1
    fi
    
    local base_keys_file="$temp_dir/base_keys.txt"
    get_keys_from_file "$base_temp_file" > "$base_keys_file"
    local base_key_count=$(wc -l < "$base_keys_file")
    
    echo ""
    echo "📊 Base language ($base_lang) contains $base_key_count keys"
    
    # Check completeness for each language
    for lang in "${SUPPORTED_LANGUAGES[@]}"; do
        if [ "$lang" = "$base_lang" ]; then
            continue
        fi
        
        local lang_temp_file="$temp_dir/${lang}.temp"
        if [ ! -f "$lang_temp_file" ]; then
            continue
        fi
        
        local lang_keys_file="$temp_dir/${lang}_keys.txt"
        get_keys_from_file "$lang_temp_file" > "$lang_keys_file"
        
        echo ""
        echo "🔍 Checking language: $lang"
        
        # Find missing keys (in base but not in current language)
        local missing_keys_file="$temp_dir/missing_${lang}.txt"
        comm -23 "$base_keys_file" "$lang_keys_file" > "$missing_keys_file"
        
        if [ -s "$missing_keys_file" ]; then
            local missing_count=$(wc -l < "$missing_keys_file")
            echo "❌ Missing $missing_count keys:"
            while IFS= read -r key; do
                echo "   • $key"
            done < "$missing_keys_file"
            all_valid=false
        fi
        
        # Find extra keys (in current language but not in base)
        local extra_keys_file="$temp_dir/extra_${lang}.txt"
        comm -13 "$base_keys_file" "$lang_keys_file" > "$extra_keys_file"
        
        if [ -s "$extra_keys_file" ]; then
            local extra_count=$(wc -l < "$extra_keys_file")
            echo "⚠️  Extra $extra_count keys:"
            while IFS= read -r key; do
                echo "   • $key"
            done < "$extra_keys_file"
        fi
        
        if [ ! -s "$missing_keys_file" ] && [ ! -s "$extra_keys_file" ]; then
            echo "✅ Translation complete"
        fi
    done
    
    # Check for empty values
    echo ""
    echo "🔍 Checking empty translations..."
    for lang in "${SUPPORTED_LANGUAGES[@]}"; do
        local lang_temp_file="$temp_dir/${lang}.temp"
        if [ ! -f "$lang_temp_file" ]; then
            continue
        fi
        
        local empty_keys_file="$temp_dir/empty_${lang}.txt"
        get_empty_keys "$lang_temp_file" > "$empty_keys_file"
        
        if [ -s "$empty_keys_file" ]; then
            local empty_count=$(wc -l < "$empty_keys_file")
            echo "❌ $lang has $empty_count empty translations:"
            while IFS= read -r key; do
                echo "   • $key"
            done < "$empty_keys_file"
            all_valid=false
        else
            echo "✅ $lang has no empty translations"
        fi
    done
    
    # Summary
    echo ""
    echo "=================================================="
    if [ "$all_valid" = true ]; then
        echo "🎉 All localization files validated successfully!"
        return 0
    else
        echo "❌ Found localization issues, please fix and retry"
        return 1
    fi
}

# Main function
main() {
    echo "🌍 Promptly Localization Validation Tool"
    echo "=================================================="
    
    if validate_localization; then
        echo ""
        echo "🚀 Localization validation completed!"
        exit 0
    else
        echo ""
        echo "💡 Suggestions:"
        echo "1. Check missing translation keys"
        echo "2. Remove extra keys"
        echo "3. Fill in empty translation values"
        echo "4. Run script again to re-validate"
        exit 1
    fi
}

# Run main function
main "$@"