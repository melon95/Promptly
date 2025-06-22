#!/usr/bin/env python3
"""
Version Update Script
Automatically update Promptly project version numbers

Usage:
  python3 scripts/update_version.py patch              # Increment patch version (1.0.0 -> 1.0.1)  
  python3 scripts/update_version.py minor              # Increment minor version (1.0.0 -> 1.1.0)
  python3 scripts/update_version.py major              # Increment major version (1.0.0 -> 2.0.0)
  python3 scripts/update_version.py set 1.2.3          # Set specific version
  python3 scripts/update_version.py build              # Only increment build number
  python3 scripts/update_version.py current            # Show current version
"""

import re
import sys
import os
from pathlib import Path
from typing import Tuple, Optional

class VersionUpdater:
    def __init__(self, project_root: str = None):
        if project_root is None:
            # Auto-detect project root directory
            current_dir = Path(__file__).parent.parent
            self.project_root = current_dir
        else:
            self.project_root = Path(project_root)
        
        self.pbxproj_path = self.project_root / "Promptly.xcodeproj" / "project.pbxproj"
        
        if not self.pbxproj_path.exists():
            raise FileNotFoundError(f"Project file not found: {self.pbxproj_path}")
    
    def get_current_version(self) -> Tuple[str, str]:
        """Get current version number and build number"""
        with open(self.pbxproj_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Find MARKETING_VERSION (app version)
        marketing_version_match = re.search(r'MARKETING_VERSION = ([^;]+);', content)
        if marketing_version_match:
            app_version = marketing_version_match.group(1).strip()
        else:
            app_version = "1.0.0"
        
        # Find CURRENT_PROJECT_VERSION (build number)
        build_version_match = re.search(r'CURRENT_PROJECT_VERSION = ([^;]+);', content)
        if build_version_match:
            build_version = build_version_match.group(1).strip()
        else:
            build_version = "1"
        
        return app_version, build_version
    
    def parse_version(self, version_str: str) -> Tuple[int, int, int]:
        """Parse version string"""
        # Remove quotes
        version_str = version_str.strip('"\'')
        parts = version_str.split('.')
        
        major = int(parts[0]) if len(parts) > 0 else 0
        minor = int(parts[1]) if len(parts) > 1 else 0
        patch = int(parts[2]) if len(parts) > 2 else 0
        
        return major, minor, patch
    
    def increment_version(self, version_str: str, increment_type: str) -> str:
        """Increment version number"""
        major, minor, patch = self.parse_version(version_str)
        
        if increment_type == "major":
            major += 1
            minor = 0
            patch = 0
        elif increment_type == "minor":
            minor += 1
            patch = 0
        elif increment_type == "patch":
            patch += 1
        else:
            raise ValueError(f"Unknown increment type: {increment_type}")
        
        return f"{major}.{minor}.{patch}"
    
    def update_version(self, new_app_version: Optional[str] = None, new_build_version: Optional[str] = None):
        """Update version number"""
        with open(self.pbxproj_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Update app version
        if new_app_version:
            content = re.sub(
                r'MARKETING_VERSION = [^;]+;',
                f'MARKETING_VERSION = {new_app_version};',
                content
            )
        
        # Update build number
        if new_build_version:
            content = re.sub(
                r'CURRENT_PROJECT_VERSION = [^;]+;',
                f'CURRENT_PROJECT_VERSION = {new_build_version};',
                content
            )
        
        # Write back to file
        with open(self.pbxproj_path, 'w', encoding='utf-8') as f:
            f.write(content)
    
    def increment_build_number(self):
        """Only increment build number"""
        _, current_build = self.get_current_version()
        current_build_num = int(current_build.strip('"\''))
        new_build_num = current_build_num + 1
        self.update_version(new_build_version=str(new_build_num))
        return str(new_build_num)

def print_usage():
    """Print usage instructions"""
    print(__doc__)

def main():
    if len(sys.argv) < 2:
        print_usage()
        sys.exit(1)
    
    command = sys.argv[1].lower()
    
    try:
        updater = VersionUpdater()
        current_app_version, current_build_version = updater.get_current_version()
        
        print(f"🔍 Current version: {current_app_version} (build: {current_build_version})")
        
        if command == "current":
            # Only show current version
            print(f"✅ App version: {current_app_version}")
            print(f"✅ Build version: {current_build_version}")
            return
        
        elif command == "build":
            # Only increment build number
            new_build = updater.increment_build_number()
            print(f"🔨 Build number updated: {current_build_version} -> {new_build}")
            print(f"✅ New version: {current_app_version} (build: {new_build})")
        
        elif command in ["major", "minor", "patch"]:
            # Increment version number
            new_app_version = updater.increment_version(current_app_version, command)
            new_build = updater.increment_build_number()
            updater.update_version(new_app_version=new_app_version)
            print(f"🚀 Version updated: {current_app_version} -> {new_app_version}")
            print(f"🔨 Build number updated: {current_build_version} -> {new_build}")
            print(f"✅ New version: {new_app_version} (build: {new_build})")
        
        elif command == "set":
            # Set specific version
            if len(sys.argv) < 3:
                print("❌ Error: Please specify the version number to set")
                print("   Example: python3 scripts/update_version.py set 1.2.3")
                sys.exit(1)
            
            new_version = sys.argv[2]
            new_build = updater.increment_build_number()
            updater.update_version(new_app_version=new_version)
            print(f"🎯 Version set: {current_app_version} -> {new_version}")
            print(f"🔨 Build number updated: {current_build_version} -> {new_build}")
            print(f"✅ New version: {new_version} (build: {new_build})")
        
        else:
            print(f"❌ Unknown command: {command}")
            print_usage()
            sys.exit(1)
    
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 