#!/bin/bash

# Exit on any error
set -e

# Script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Directory paths
SOURCES_DIR="$PROJECT_ROOT/Sources"
BUILD_DIR="$PROJECT_ROOT/Build"
BACKUP_DIR="$PROJECT_ROOT/temp_backup/backup_$(date +%Y%m%d_%H%M%S)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log messages
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Function to create backup
create_backup() {
    log "Creating backup in $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp -R "$SOURCES_DIR" "$BACKUP_DIR/"
    
    # Verify backup
    if [ ! -d "$BACKUP_DIR/Sources" ]; then
        error "Backup creation failed"
    fi
    log "Backup created successfully"
}

# Function to verify directory structure
verify_directory_structure() {
    local expected_dirs=(
        "App"
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
        "Tests/UITests"
        "Widget"
    )
    
    log "Verifying directory structure..."
    for dir in "${expected_dirs[@]}"; do
        if [ ! -d "$SOURCES_DIR/$dir" ]; then
            mkdir -p "$SOURCES_DIR/$dir"
            warn "Created missing directory: $dir"
        fi
    done
}

# Function to clean build artifacts
clean_build_artifacts() {
    log "Cleaning build artifacts..."
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
    
    # Clean old backups (keep last 5)
    cd "$PROJECT_ROOT"
    if [ -d "temp_backup" ]; then
        cd temp_backup
        ls -t | tail -n +6 | xargs -I {} rm -rf {}
    fi
}

# Function to verify Swift files
verify_swift_files() {
    log "Verifying Swift files..."
    local swift_files=$(find "$SOURCES_DIR" -name "*.swift")
    local swift_count=$(echo "$swift_files" | wc -l)
    
    if [ "$swift_count" -lt 1 ]; then
        error "No Swift files found in the project"
    fi
    
    # Check for basic Swift file validity
    for file in $swift_files; do
        if [ ! -s "$file" ]; then
            warn "Empty Swift file found: $file"
        fi
        
        # Check for import statements
        if ! grep -q "^import" "$file"; then
            warn "No import statements found in: $file"
        fi
    done
}

# Function to verify file permissions
verify_permissions() {
    log "Verifying file permissions..."
    find "$SOURCES_DIR" -type f -name "*.swift" -exec chmod 644 {} \;
    find "$SOURCES_DIR" -type d -exec chmod 755 {} \;
    
    if [ -d "$SCRIPT_DIR" ]; then
        find "$SCRIPT_DIR" -type f -name "*.sh" -exec chmod +x {} \;
    fi
}

# Function to clean empty directories
clean_empty_dirs() {
    log "Cleaning empty directories..."
    find "$SOURCES_DIR" -type d -empty -delete
}

# Function to verify symlinks
verify_symlinks() {
    log "Verifying symlinks..."
    find "$SOURCES_DIR" -type l | while read symlink; do
        if [ ! -e "$symlink" ]; then
            warn "Broken symlink found: $symlink"
            rm "$symlink"
        fi
    done
}

# Main execution
main() {
    log "Starting project reorganization..."
    
    # Create backup first
    create_backup
    
    # Clean and verify
    clean_build_artifacts
    verify_directory_structure
    verify_swift_files
    verify_symlinks
    clean_empty_dirs
    verify_permissions
    
    log "Project reorganization completed successfully"
}

# Execute main function with error handling
if main; then
    log "✅ All tasks completed successfully"
else
    error "❌ Reorganization failed"
    # Restore from backup if something went wrong
    if [ -d "$BACKUP_DIR" ]; then
        warn "Restoring from backup..."
        rm -rf "$SOURCES_DIR"
        cp -R "$BACKUP_DIR/Sources" "$PROJECT_ROOT/"
        verify_permissions
        log "Restored from backup"
    fi
    exit 1
fi 