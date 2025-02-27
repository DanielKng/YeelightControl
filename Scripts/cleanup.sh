#!/bin/bash

# cleanup.sh
# Script to clean up temporary files and maintain project cleanliness

echo "🧹 Starting project cleanup..."

# Store the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Function to display step information
display_step() {
    echo "📋 $1..."
}

# Clean Build directory
display_step "Removing Build directory"
rm -rf Build/

# Clean Xcode derived data and build artifacts
display_step "Cleaning Xcode artifacts"
rm -rf ~/Library/Developer/Xcode/DerivedData/*YeelightControl*

# Remove temporary and system files
display_step "Removing temporary and system files"
find . -name "*.DS_Store" -type f -delete
find . -name "*.swp" -type f -delete
find . -name "*~" -type f -delete
find . -name "*.bak" -type f -delete
find . -name "*.old" -type f -delete
find . -name "*.tmp" -type f -delete
find . -name "*.temp" -type f -delete
find . -name "\#*\#" -type f -delete
find . -name ".\#*" -type f -delete

# Clean up empty directories
display_step "Removing empty directories"
find . -type d -empty -not -path "*/\.*" -delete

# Clean editor specific files
display_step "Cleaning editor files"
rm -rf .vscode/
rm -rf .idea/
rm -rf .atom/
rm -rf *.sublime-workspace
rm -rf *.sublime-project

# Clean build artifacts
display_step "Cleaning build artifacts"
find . -name "*.dSYM" -type d -exec rm -rf {} +
find . -name "*.profraw" -type f -delete
find . -name "*.gcda" -type f -delete
find . -name "*.gcno" -type f -delete

# Clean up legacy framework files
display_step "Removing legacy framework files"
rm -rf Frameworks/
rm -rf Pods/
rm -rf Carthage/
rm -rf Dependencies/
rm -rf .accio/

# Git cleanup
display_step "Cleaning Git repository"
git clean -fdx
git gc --aggressive --prune=now

echo "✨ Cleanup complete!"
echo "Note: Run './setup_xcode_project.sh' to regenerate the Xcode project." 