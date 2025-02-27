#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "🔄 Starting project reorganization..."

# Create backup with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$PROJECT_ROOT/temp_backup/backup_$TIMESTAMP"
echo "📦 Creating backup in $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"

# Function to backup a directory
backup_directory() {
    local src="$1"
    local dst="$2"
    if [ -d "$src" ]; then
        echo "📦 Backing up $src..."
        cp -a "$src" "$dst"
        echo "✓ $(basename "$src") directory backed up"
        echo "  Found $(find "$src" -name "*.swift" | wc -l | tr -d ' ') Swift files"
    fi
}

# Function to restore a directory
restore_directory() {
    local src="$1"
    local dst="$2"
    if [ -d "$src" ]; then
        echo "📥 Restoring from $src to $dst..."
        cp -a "$src/." "$dst/"
        echo "✓ $(basename "$dst") directory restored"
        echo "  Restored $(find "$dst" -name "*.swift" | wc -l | tr -d ' ') Swift files"
        
        # Set permissions
        find "$dst" -type f -exec chmod 644 {} \;
        find "$dst" -type d -exec chmod 755 {} \;
    fi
}

# Backup existing files with full structure
echo "💾 Starting backup process..."
backup_directory "$PROJECT_ROOT/Sources" "$BACKUP_DIR/Sources"
backup_directory "$PROJECT_ROOT/Resources" "$BACKUP_DIR/Resources"
backup_directory "$PROJECT_ROOT/.github" "$BACKUP_DIR/.github"
backup_directory "$PROJECT_ROOT/Tests" "$BACKUP_DIR/Tests"

# Create directory structure (only if directories don't exist)
echo "📁 Ensuring directory structure exists..."
mkdir -p "$PROJECT_ROOT/Sources/"{Core,Features,UI,Tests}
mkdir -p "$PROJECT_ROOT/Sources/Core/"{Analytics,Background,Configuration,Device,Effect,Error,Location,Network,Notification,Permission,Scene,Security,Services,State,Storage}
mkdir -p "$PROJECT_ROOT/Sources/Features/"{Automation,Effects,Rooms,Scenes}
mkdir -p "$PROJECT_ROOT/Sources/UI/"{Components,Views,Widgets}
mkdir -p "$PROJECT_ROOT/Sources/UI/Components/Common"
mkdir -p "$PROJECT_ROOT/Sources/Tests/"{UITests,UnitTests}
mkdir -p "$PROJECT_ROOT/Resources/"{Assets,Configs,Localization}
mkdir -p "$PROJECT_ROOT/Tests/YeelightControlTests"

# Restore from backup with proper permissions
echo "📥 Starting restore process..."
restore_directory "$BACKUP_DIR/Sources" "$PROJECT_ROOT/Sources"
restore_directory "$BACKUP_DIR/Resources" "$PROJECT_ROOT/Resources"
restore_directory "$BACKUP_DIR/.github" "$PROJECT_ROOT/.github"
restore_directory "$BACKUP_DIR/Tests" "$PROJECT_ROOT/Tests"

# Move any root configuration files to Resources/Configs
echo "📝 Moving configuration files..."
if [ -f "$PROJECT_ROOT/Package.swift" ]; then
    mv "$PROJECT_ROOT/Package.swift" "$PROJECT_ROOT/Resources/Configs/"
    echo "✓ Moved Package.swift to Resources/Configs"
fi

if [ -f "$PROJECT_ROOT/project.yml" ]; then
    mv "$PROJECT_ROOT/project.yml" "$PROJECT_ROOT/Resources/Configs/"
    echo "✓ Moved project.yml to Resources/Configs"
fi

# Clean up empty directories
echo "🧹 Cleaning empty directories..."
find "$PROJECT_ROOT" -type d -empty -delete 2>/dev/null || true

# Set permissions for scripts
echo "🔒 Setting permissions..."
chmod +x "$PROJECT_ROOT/Scripts/"*.sh 2>/dev/null || true
echo "✓ Script permissions updated"

# Final verification
echo "🔍 Verifying file restoration..."
echo "Swift files in Sources: $(find "$PROJECT_ROOT/Sources" -name "*.swift" | wc -l | tr -d ' ')"
echo "Directory structure:"
find "$PROJECT_ROOT/Sources" -type d -maxdepth 3 -mindepth 1 | sed 's|[^/]*/|  |g'

echo "✨ Project reorganization complete!"
echo "💾 Backup saved to: $BACKUP_DIR"
echo "ℹ️  Run ./Scripts/setup_xcode_project.sh to regenerate the Xcode project" 