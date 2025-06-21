#!/bin/bash

# Version management script wrapper
# Usage: ./scripts/version.sh [command] [args]

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Execute Python script
cd "$PROJECT_ROOT"
python3 scripts/update_version.py "$@" 