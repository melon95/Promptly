#!/bin/bash

# Version Update Script
# Automatically update Promptly project version numbers
#
# Usage:
#   ./scripts/version.sh patch              # Increment patch version (1.0.0 -> 1.0.1)
#   ./scripts/version.sh minor              # Increment minor version (1.0.0 -> 1.1.0)
#   ./scripts/version.sh major              # Increment major version (1.0.0 -> 2.0.0)
#   ./scripts/version.sh set 1.2.3          # Set specific version
#   ./scripts/version.sh build              # Only increment build number
#   ./scripts/version.sh current            # Show current version

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PBXPROJ_PATH="$PROJECT_ROOT/Promptly.xcodeproj/project.pbxproj"

# Check if project file exists
if [ ! -f "$PBXPROJ_PATH" ]; then
    echo "❌ Error: Project file not found: $PBXPROJ_PATH"
    exit 1
fi

# Function to get current version
get_current_version() {
    local app_version build_version
    
    # Get MARKETING_VERSION (app version)
    app_version=$(grep -o 'MARKETING_VERSION = [^;]*' "$PBXPROJ_PATH" | head -1 | sed 's/MARKETING_VERSION = //' | tr -d ' ')
    if [ -z "$app_version" ]; then
        app_version="1.0.0"
    fi
    
    # Get CURRENT_PROJECT_VERSION (build number)
    build_version=$(grep -o 'CURRENT_PROJECT_VERSION = [^;]*' "$PBXPROJ_PATH" | head -1 | sed 's/CURRENT_PROJECT_VERSION = //' | tr -d ' ')
    if [ -z "$build_version" ]; then
        build_version="1"
    fi
    
    echo "$app_version $build_version"
}

# Function to parse version string into components
parse_version() {
    local version_str="$1"
    # Remove quotes
    version_str=$(echo "$version_str" | tr -d '"'"'"'')
    
    local major minor patch
    IFS='.' read -r major minor patch <<< "$version_str"
    
    major=${major:-0}
    minor=${minor:-0}
    patch=${patch:-0}
    
    echo "$major $minor $patch"
}

# Function to increment version
increment_version() {
    local version_str="$1"
    local increment_type="$2"
    
    read -r major minor patch <<< "$(parse_version "$version_str")"
    
    case "$increment_type" in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            echo "❌ Error: Unknown increment type: $increment_type" >&2
            return 1
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

# Function to update version in pbxproj file
update_version() {
    local new_app_version="$1"
    local new_build_version="$2"
    
    if [ -n "$new_app_version" ]; then
        sed -i '' "s/MARKETING_VERSION = [^;]*/MARKETING_VERSION = $new_app_version/g" "$PBXPROJ_PATH"
    fi
    
    if [ -n "$new_build_version" ]; then
        sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*/CURRENT_PROJECT_VERSION = $new_build_version/g" "$PBXPROJ_PATH"
    fi
}

# Function to increment build number only
increment_build_number() {
    read -r current_app_version current_build_version <<< "$(get_current_version)"
    
    # Remove quotes and increment
    current_build_num=$(echo "$current_build_version" | tr -d '"'"'"'')
    new_build_num=$((current_build_num + 1))
    
    update_version "" "$new_build_num"
    echo "$new_build_num"
}

# Function to print usage
print_usage() {
    cat << 'EOF'
Version Update Script
Automatically update Promptly project version numbers

Usage:
  ./scripts/version.sh patch              # Increment patch version (1.0.0 -> 1.0.1)
  ./scripts/version.sh minor              # Increment minor version (1.0.0 -> 1.1.0)
  ./scripts/version.sh major              # Increment major version (1.0.0 -> 2.0.0)
  ./scripts/version.sh set 1.2.3          # Set specific version
  ./scripts/version.sh build              # Only increment build number
  ./scripts/version.sh current            # Show current version
EOF
}

# Main script logic
main() {
    if [ $# -lt 1 ]; then
        print_usage
        exit 1
    fi
    
    local command="$1"
    command=$(echo "$command" | tr '[:upper:]' '[:lower:]')
    
    read -r current_app_version current_build_version <<< "$(get_current_version)"
    
    echo "🔍 Current version: $current_app_version (build: $current_build_version)"
    
    case "$command" in
        "current")
            echo "✅ App version: $current_app_version"
            echo "✅ Build version: $current_build_version"
            ;;
        
        "build")
            new_build=$(increment_build_number)
            echo "🔨 Build number updated: $current_build_version -> $new_build"
            echo "✅ New version: $current_app_version (build: $new_build)"
            ;;
        
        "major"|"minor"|"patch")
            new_app_version=$(increment_version "$current_app_version" "$command")
            if [ $? -ne 0 ]; then
                exit 1
            fi
            new_build=$(increment_build_number)
            update_version "$new_app_version" ""
            echo "🚀 Version updated: $current_app_version -> $new_app_version"
            echo "🔨 Build number updated: $current_build_version -> $new_build"
            echo "✅ New version: $new_app_version (build: $new_build)"
            ;;
        
        "set")
            if [ $# -lt 2 ]; then
                echo "❌ Error: Please specify the version number to set"
                echo "   Example: ./scripts/version.sh set 1.2.3"
                exit 1
            fi
            
            new_version="$2"
            new_build=$(increment_build_number)
            update_version "$new_version" ""
            echo "🎯 Version set: $current_app_version -> $new_version"
            echo "🔨 Build number updated: $current_build_version -> $new_build"
            echo "✅ New version: $new_version (build: $new_build)"
            ;;
        
        *)
            echo "❌ Unknown command: $command"
            print_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 