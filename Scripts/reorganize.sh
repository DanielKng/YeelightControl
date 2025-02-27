#!/bin/bash

# reorganize.sh
# Script to maintain consistent project structure

echo "🏗️ Starting project reorganization..."

# Store the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Base directories
SOURCES_DIR="Sources"
RESOURCES_DIR="Resources"
SCRIPTS_DIR="Scripts"
GITHUB_DIR=".github"

# Create backup
echo "📦 Creating backup..."
BACKUP_DIR="temp_backup/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
for dir in "$SOURCES_DIR" "$RESOURCES_DIR" "$SCRIPTS_DIR" "$GITHUB_DIR"; do
    if [ -d "$dir" ]; then
        cp -R "$dir" "$BACKUP_DIR/"
    fi
done

# Clean existing structure
echo "🧹 Cleaning existing structure..."
rm -rf Build/  # Remove Build directory first
for dir in "$SOURCES_DIR" "$RESOURCES_DIR" "$SCRIPTS_DIR"; do
    rm -rf "$dir"
done

# Create main directories
echo "📁 Creating directory structure..."
mkdir -p "$SOURCES_DIR" "$RESOURCES_DIR" "$SCRIPTS_DIR"

# Create Sources subdirectories
SOURCES_SUBDIRS=(
    "Core/Analytics"
    "Core/Background"
    "Core/Configuration"
    "Core/Device"
    "Core/Effect"
    "Core/Error"
    "Core/Location"
    "Core/Network"
    "Core/Notification"
    "Core/Permission"
    "Core/Scene"
    "Core/Security"
    "Core/Services"
    "Core/State"
    "Core/Storage"
    "Features/Automation"
    "Features/Effects"
    "Features/Rooms"
    "Features/Scenes"
    "UI/Components"
    "UI/Views"
    "Tests/UnitTests"
    "Tests/UITests"
    "Tests/IntegrationTests"
)

for dir in "${SOURCES_SUBDIRS[@]}"; do
    mkdir -p "$SOURCES_DIR/$dir"
done

# Create Resources subdirectories
RESOURCES_SUBDIRS=(
    "Screenshots"
    "Assets"
    "Localization"
)

for dir in "${RESOURCES_SUBDIRS[@]}"; do
    mkdir -p "$RESOURCES_DIR/$dir"
done

# Move Scripts
mkdir -p "$SCRIPTS_DIR"
for script in setup_xcode_project.sh cleanup.sh reorganize.sh; do
    if [ -f "$script" ]; then
        mv "$script" "$SCRIPTS_DIR/"
        ln -sf "$SCRIPTS_DIR/$script" "$script"
    fi
done

# Restore from backup if exists
echo "📋 Restoring files from backup..."
if [ -d "$BACKUP_DIR" ]; then
    # Function to safely restore files
    safe_restore() {
        local src="$BACKUP_DIR/$1"
        local dest="$2"
        if [ -e "$src" ]; then
            mkdir -p "$(dirname "$dest")"
            cp -R "$src" "$dest"
            echo "✓ Restored: $1"
        fi
    }

    # Restore directories
    for dir in Sources Resources .github; do
        if [ -d "$BACKUP_DIR/$dir" ]; then
            safe_restore "$dir" "$dir"
        fi
    done
fi

# Clean up empty directories
echo "🧹 Cleaning up empty directories..."
find . -type d -empty -not -path "*/\.*" -delete

# Ensure scripts are executable
echo "🔧 Setting permissions..."
chmod +x Scripts/*.sh
for script in setup_xcode_project.sh cleanup.sh reorganize.sh; do
    if [ -L "$script" ]; then
        chmod +x "$script"
    fi
done

echo "✨ Project reorganization complete!"
echo "📦 Backup saved to: $BACKUP_DIR"
echo "Note: Run './setup_xcode_project.sh' to regenerate the Xcode project." 