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

# Backup existing files
cp -R "$PROJECT_ROOT/Sources" "$BACKUP_DIR/" 2>/dev/null || true
cp -R "$PROJECT_ROOT/Resources" "$BACKUP_DIR/" 2>/dev/null || true
cp -R "$PROJECT_ROOT/.github" "$BACKUP_DIR/" 2>/dev/null || true
cp -R "$PROJECT_ROOT/Tests" "$BACKUP_DIR/" 2>/dev/null || true

# Clean existing structure
echo "🧹 Cleaning existing structure..."
rm -rf "$PROJECT_ROOT/Sources" 2>/dev/null || true
rm -rf "$PROJECT_ROOT/Resources" 2>/dev/null || true
rm -rf "$PROJECT_ROOT/Tests" 2>/dev/null || true

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p "$PROJECT_ROOT/Sources/"{App,Widget,Models,Views,Controllers,Utils,Extensions,Services}
mkdir -p "$PROJECT_ROOT/Resources/"{Assets,Configs,Localization}
mkdir -p "$PROJECT_ROOT/Tests/YeelightControlTests"

# Restore from backup
echo "📥 Restoring files from backup..."
if [ -d "$BACKUP_DIR/Sources" ]; then
    cp -R "$BACKUP_DIR/Sources/"* "$PROJECT_ROOT/Sources/" 2>/dev/null || true
fi

if [ -d "$BACKUP_DIR/Resources" ]; then
    cp -R "$BACKUP_DIR/Resources/"* "$PROJECT_ROOT/Resources/" 2>/dev/null || true
fi

if [ -d "$BACKUP_DIR/.github" ]; then
    cp -R "$BACKUP_DIR/.github" "$PROJECT_ROOT/" 2>/dev/null || true
fi

if [ -d "$BACKUP_DIR/Tests" ]; then
    cp -R "$BACKUP_DIR/Tests/"* "$PROJECT_ROOT/Tests/" 2>/dev/null || true
fi

# Move any root configuration files to Resources/Configs
echo "📝 Moving configuration files..."
[ -f "$PROJECT_ROOT/Package.swift" ] && mv "$PROJECT_ROOT/Package.swift" "$PROJECT_ROOT/Resources/Configs/" 2>/dev/null || true
[ -f "$PROJECT_ROOT/project.yml" ] && mv "$PROJECT_ROOT/project.yml" "$PROJECT_ROOT/Resources/Configs/" 2>/dev/null || true

# Clean up empty directories
echo "🧹 Cleaning empty directories..."
find "$PROJECT_ROOT" -type d -empty -delete 2>/dev/null || true

# Set permissions for scripts
echo "🔒 Setting permissions..."
chmod +x "$PROJECT_ROOT/Scripts/"*.sh 2>/dev/null || true

echo "✨ Project reorganization complete!"
echo "💾 Backup saved to: $BACKUP_DIR"
echo "ℹ️  Run ./Scripts/setup_xcode_project.sh to regenerate the Xcode project" 