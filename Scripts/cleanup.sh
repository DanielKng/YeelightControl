#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "🧹 Starting project cleanup..."

# Clean Build directory
echo "📦 Cleaning Build directory..."
if [ -d "$PROJECT_ROOT/Build" ]; then
    rm -rf "$PROJECT_ROOT/Build"/*
fi

# Clean DerivedData
echo "🗑️ Cleaning Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*YeelightControl*

# Clean temporary files
echo "🧮 Cleaning temporary files..."
find "$PROJECT_ROOT" -name ".DS_Store" -delete
find "$PROJECT_ROOT" -name "*.swp" -delete
find "$PROJECT_ROOT" -name "*.swo" -delete
find "$PROJECT_ROOT" -name "*~" -delete

# Clean Xcode user data
echo "📱 Cleaning Xcode user data..."
rm -rf "$PROJECT_ROOT"/*.xcodeproj/xcuserdata
rm -rf "$PROJECT_ROOT"/*.xcworkspace/xcuserdata

# Clean temp_backup older than 7 days
echo "📂 Cleaning old backups..."
if [ -d "$PROJECT_ROOT/temp_backup" ]; then
    find "$PROJECT_ROOT/temp_backup" -type d -mtime +7 -exec rm -rf {} \;
fi

echo "✨ Cleanup complete!" 