#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Create timestamp for backup
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$PROJECT_ROOT/temp_backup/backup_$TIMESTAMP"

echo "🏗️ Starting project reorganization..."

# Create backup
echo "📦 Creating backup..."
mkdir -p "$BACKUP_DIR"
if [ -d "$PROJECT_ROOT/Sources" ]; then
    cp -R "$PROJECT_ROOT/Sources/." "$BACKUP_DIR/Sources/" 2>/dev/null || true
fi
if [ -d "$PROJECT_ROOT/Resources" ]; then
    cp -R "$PROJECT_ROOT/Resources/." "$BACKUP_DIR/Resources/" 2>/dev/null || true
fi
if [ -d "$PROJECT_ROOT/.github" ]; then
    cp -R "$PROJECT_ROOT/.github" "$BACKUP_DIR/" 2>/dev/null || true
fi

# Create directory structure (without removing existing)
echo "📁 Creating directory structure..."
mkdir -p "$PROJECT_ROOT/Sources"
mkdir -p "$PROJECT_ROOT/Sources/App"
mkdir -p "$PROJECT_ROOT/Sources/Models"
mkdir -p "$PROJECT_ROOT/Sources/Views"
mkdir -p "$PROJECT_ROOT/Sources/Controllers"
mkdir -p "$PROJECT_ROOT/Sources/Utils"
mkdir -p "$PROJECT_ROOT/Sources/Extensions"
mkdir -p "$PROJECT_ROOT/Sources/Services"

mkdir -p "$PROJECT_ROOT/Resources"
mkdir -p "$PROJECT_ROOT/Resources/Assets"
mkdir -p "$PROJECT_ROOT/Resources/Configs"
mkdir -p "$PROJECT_ROOT/Resources/Localization"

mkdir -p "$PROJECT_ROOT/Scripts"

# Set proper permissions
chmod -R 755 "$PROJECT_ROOT/Sources"
chmod -R 755 "$PROJECT_ROOT/Resources"
chmod -R 755 "$PROJECT_ROOT/Scripts"

# Restore files from backup if they exist
echo "📋 Restoring files from backup..."
if [ -d "$BACKUP_DIR/Sources" ]; then
    cp -R "$BACKUP_DIR/Sources/." "$PROJECT_ROOT/Sources/" 2>/dev/null || true
    echo "✓ Restored: Sources"
fi
if [ -d "$BACKUP_DIR/Resources" ]; then
    cp -R "$BACKUP_DIR/Resources/." "$PROJECT_ROOT/Resources/" 2>/dev/null || true
    echo "✓ Restored: Resources"
fi
if [ -d "$BACKUP_DIR/.github" ]; then
    cp -R "$BACKUP_DIR/.github" "$PROJECT_ROOT/" 2>/dev/null || true
    echo "✓ Restored: .github"
fi

# Set permissions for scripts
echo "🔧 Setting permissions..."
chmod +x "$PROJECT_ROOT/Scripts/"*.sh 2>/dev/null || true

echo "✨ Project reorganization complete!"
echo "📦 Backup saved to: $BACKUP_DIR"
echo "Note: Run './setup_xcode_project.sh' to regenerate the Xcode project." 