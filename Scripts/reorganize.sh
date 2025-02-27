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

# Backup existing files with full structure
echo "💾 Backing up existing files..."
if [ -d "$PROJECT_ROOT/Sources" ]; then
    cp -a "$PROJECT_ROOT/Sources" "$BACKUP_DIR/"
    echo "✓ Sources directory backed up"
fi

if [ -d "$PROJECT_ROOT/Resources" ]; then
    cp -a "$PROJECT_ROOT/Resources" "$BACKUP_DIR/"
    echo "✓ Resources directory backed up"
fi

if [ -d "$PROJECT_ROOT/.github" ]; then
    cp -a "$PROJECT_ROOT/.github" "$BACKUP_DIR/"
    echo "✓ .github directory backed up"
fi

if [ -d "$PROJECT_ROOT/Tests" ]; then
    cp -a "$PROJECT_ROOT/Tests" "$BACKUP_DIR/"
    echo "✓ Tests directory backed up"
fi

# Create directory structure (only if directories don't exist)
echo "📁 Ensuring directory structure exists..."
mkdir -p "$PROJECT_ROOT/Sources/"{App,Widget,Models,Views,Controllers,Utils,Extensions,Services}
mkdir -p "$PROJECT_ROOT/Resources/"{Assets,Configs,Localization}
mkdir -p "$PROJECT_ROOT/Tests/YeelightControlTests"

# Restore from backup with proper permissions
echo "📥 Restoring files from backup..."
if [ -d "$BACKUP_DIR/Sources" ]; then
    cp -a "$BACKUP_DIR/Sources/"* "$PROJECT_ROOT/Sources/"
    echo "✓ Sources directory restored"
    find "$PROJECT_ROOT/Sources" -type f -exec chmod 644 {} \;
    find "$PROJECT_ROOT/Sources" -type d -exec chmod 755 {} \;
fi

if [ -d "$BACKUP_DIR/Resources" ]; then
    cp -a "$BACKUP_DIR/Resources/"* "$PROJECT_ROOT/Resources/"
    echo "✓ Resources directory restored"
    find "$PROJECT_ROOT/Resources" -type f -exec chmod 644 {} \;
    find "$PROJECT_ROOT/Resources" -type d -exec chmod 755 {} \;
fi

if [ -d "$BACKUP_DIR/.github" ]; then
    cp -a "$BACKUP_DIR/.github" "$PROJECT_ROOT/"
    echo "✓ .github directory restored"
fi

if [ -d "$BACKUP_DIR/Tests" ]; then
    cp -a "$BACKUP_DIR/Tests/"* "$PROJECT_ROOT/Tests/"
    echo "✓ Tests directory restored"
    find "$PROJECT_ROOT/Tests" -type f -exec chmod 644 {} \;
    find "$PROJECT_ROOT/Tests" -type d -exec chmod 755 {} \;
fi

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

echo "✨ Project reorganization complete!"
echo "💾 Backup saved to: $BACKUP_DIR"
echo "ℹ️  Run ./Scripts/setup_xcode_project.sh to regenerate the Xcode project" 