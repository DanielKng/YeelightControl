#!/bin/bash

set -e  # Exit on any error

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Safety check function
check_directory_safety() {
    local dir="$1"
    local swift_files=$(find "$dir" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$swift_files" -gt 0 ]; then
        echo -e "${GREEN}✓ Found $swift_files Swift files in $dir${NC}"
        return 0
    else
        echo -e "${RED}⚠️  No Swift files found in $dir. Stopping for safety.${NC}"
        return 1
    fi
}

# Backup function with verification
create_verified_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$PROJECT_ROOT/temp_backup/backup_$timestamp"
    
    echo "🔄 Creating verified backup..."
    
    # Count original files
    local original_swift_count=$(find "$PROJECT_ROOT/Sources" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$original_swift_count" -eq 0 ]; then
        echo -e "${RED}❌ No Swift files found in project. Cannot proceed without valid source files.${NC}"
        exit 1
    fi
    
    # Create backup
    mkdir -p "$backup_dir"
    
    # Backup with verification
    echo "📦 Backing up project files..."
    if [ -d "$PROJECT_ROOT/Sources" ]; then
        cp -a "$PROJECT_ROOT/Sources" "$backup_dir/"
        local backup_swift_count=$(find "$backup_dir/Sources" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$backup_swift_count" != "$original_swift_count" ]; then
            echo -e "${RED}❌ Backup verification failed! Expected $original_swift_count files, found $backup_swift_count${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ Sources backup verified ($backup_swift_count Swift files)${NC}"
    fi
    
    # Backup other directories
    for dir in "Resources" ".github" "Tests"; do
        if [ -d "$PROJECT_ROOT/$dir" ]; then
            cp -a "$PROJECT_ROOT/$dir" "$backup_dir/"
            echo -e "${GREEN}✓ $dir backup complete${NC}"
        fi
    done
    
    echo "$backup_dir"
}

# Restore function with verification
restore_with_verification() {
    local src="$1"
    local dst="$2"
    local name="$3"
    
    if [ -d "$src" ]; then
        local before_count=$(find "$dst" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
        cp -a "$src/." "$dst/"
        local after_count=$(find "$dst" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
        
        if [ "$after_count" -lt "$before_count" ] && [ "$before_count" -gt 0 ]; then
            echo -e "${RED}❌ Restore verification failed for $name! Files were lost in transfer.${NC}"
            echo -e "${RED}   Before: $before_count Swift files, After: $after_count Swift files${NC}"
            exit 1
        fi
        
        # Set permissions
        find "$dst" -type f -exec chmod 644 {} \;
        find "$dst" -type d -exec chmod 755 {} \;
        
        echo -e "${GREEN}✓ $name restored and verified ($after_count Swift files)${NC}"
    fi
}

echo "🔄 Starting project cleanup and reorganization..."

# Verify current state
if ! check_directory_safety "$PROJECT_ROOT/Sources"; then
    echo -e "${YELLOW}⚠️  Current state may be unsafe. Creating backup before proceeding...${NC}"
fi

# Create and verify backup
BACKUP_DIR=$(create_verified_backup)
echo -e "${GREEN}✓ Verified backup created at: $BACKUP_DIR${NC}"

# Clean derived data and temporary files
echo "🧹 Cleaning derived data and temporary files..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*YeelightControl* 2>/dev/null || true
find "$PROJECT_ROOT" -name ".DS_Store" -delete 2>/dev/null || true
find "$PROJECT_ROOT" -name "*.swp" -delete 2>/dev/null || true
find "$PROJECT_ROOT" -name "*.swo" -delete 2>/dev/null || true
find "$PROJECT_ROOT" -name "*~" -delete 2>/dev/null || true

# Clean build artifacts
echo "📦 Cleaning build artifacts..."
if [ -d "$PROJECT_ROOT/Build" ]; then
    rm -rf "$PROJECT_ROOT/Build"/*
fi
rm -f "$PROJECT_ROOT"/*.xcodeproj 2>/dev/null || true
rm -f "$PROJECT_ROOT"/*.xcworkspace 2>/dev/null || true
rm -f "$PROJECT_ROOT"/Package.resolved 2>/dev/null || true

# Clean old backups (older than 7 days)
echo "🗑️  Cleaning old backups..."
if [ -d "$PROJECT_ROOT/temp_backup" ]; then
    find "$PROJECT_ROOT/temp_backup" -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true
fi

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p "$PROJECT_ROOT/Sources/"{Core,Features,UI,Tests}
mkdir -p "$PROJECT_ROOT/Sources/Core/"{Analytics,Background,Configuration,Device,Effect,Error,Location,Network,Notification,Permission,Scene,Security,Services,State,Storage}
mkdir -p "$PROJECT_ROOT/Sources/Features/"{Automation,Effects,Rooms,Scenes}
mkdir -p "$PROJECT_ROOT/Sources/UI/"{Components,Views,Widgets}
mkdir -p "$PROJECT_ROOT/Sources/UI/Components/Common"
mkdir -p "$PROJECT_ROOT/Sources/Tests/"{UITests,UnitTests}
mkdir -p "$PROJECT_ROOT/Resources/"{Assets,Configs,Localization}
mkdir -p "$PROJECT_ROOT/Tests/YeelightControlTests"

# Restore from backup with verification
echo "📥 Restoring files with verification..."
restore_with_verification "$BACKUP_DIR/Sources" "$PROJECT_ROOT/Sources" "Sources"
restore_with_verification "$BACKUP_DIR/Resources" "$PROJECT_ROOT/Resources" "Resources"
restore_with_verification "$BACKUP_DIR/.github" "$PROJECT_ROOT/.github" ".github"
restore_with_verification "$BACKUP_DIR/Tests" "$PROJECT_ROOT/Tests" "Tests"

# Move configuration files
echo "📝 Moving configuration files..."
if [ -f "$PROJECT_ROOT/Package.swift" ]; then
    mv "$PROJECT_ROOT/Package.swift" "$PROJECT_ROOT/Resources/Configs/"
    echo -e "${GREEN}✓ Moved Package.swift to Resources/Configs${NC}"
fi

if [ -f "$PROJECT_ROOT/project.yml" ]; then
    mv "$PROJECT_ROOT/project.yml" "$PROJECT_ROOT/Resources/Configs/"
    echo -e "${GREEN}✓ Moved project.yml to Resources/Configs${NC}"
fi

# Clean empty directories
echo "🧹 Cleaning empty directories..."
find "$PROJECT_ROOT" -type d -empty -delete 2>/dev/null || true

# Set script permissions
echo "🔒 Setting script permissions..."
chmod +x "$PROJECT_ROOT/Scripts/"*.sh 2>/dev/null || true

# Final verification
echo "🔍 Final verification..."
final_swift_count=$(find "$PROJECT_ROOT/Sources" -name "*.swift" | wc -l | tr -d ' ')
if [ "$final_swift_count" -eq 0 ]; then
    echo -e "${RED}❌ CRITICAL ERROR: No Swift files found after reorganization!${NC}"
    echo -e "${YELLOW}Attempting automatic recovery from backup...${NC}"
    cp -a "$BACKUP_DIR/Sources/." "$PROJECT_ROOT/Sources/"
    recovered_count=$(find "$PROJECT_ROOT/Sources" -name "*.swift" | wc -l | tr -d ' ')
    if [ "$recovered_count" -gt 0 ]; then
        echo -e "${GREEN}✓ Recovery successful. Found $recovered_count Swift files.${NC}"
    else
        echo -e "${RED}❌ Recovery failed. Please restore from backup manually: $BACKUP_DIR${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✨ Project cleanup and reorganization complete!${NC}"
echo -e "${GREEN}💾 Backup saved to: $BACKUP_DIR${NC}"
echo -e "${GREEN}📊 Final Swift file count: $final_swift_count${NC}"
echo -e "${YELLOW}ℹ️  Run ./Scripts/setup_xcode_project.sh to regenerate the Xcode project${NC}" 