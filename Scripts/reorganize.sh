#!/bin/bash

# Set strict mode
set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }
success() { log "${GREEN}✅ $1${NC}"; }
warning() { log "${YELLOW}WARNING: $1${NC}"; }
error() { log "${RED}ERROR: $1${NC}"; exit 1; }

# Create backup of current state
create_backup() {
    local backup_dir="temp_backup/backup_$(date +'%Y%m%d_%H%M%S')"
    log "Creating backup in $(pwd)/${backup_dir}"
    mkdir -p "${backup_dir}"
    cp -R Sources "${backup_dir}/" 2>/dev/null || true
    success "Backup created successfully"
}

# Restore files from GitHub if missing
restore_from_github() {
    log "Checking for missing files from GitHub..."
    
    # Store list of files from GitHub
    git ls-tree -r --name-only origin/main Sources/ > github_files.txt
    
    # Store list of current files
    find Sources -type f > current_files.txt
    
    # Compare and restore missing files
    while IFS= read -r file; do
        if ! grep -q "^$file$" current_files.txt; then
            warning "Restoring missing file from GitHub: $file"
            git checkout origin/main -- "$file"
        fi
    done < github_files.txt
    
    # Cleanup temporary files
    rm -f github_files.txt current_files.txt
}

# Clean build artifacts (only .build and .swiftmodule files)
clean_build_artifacts() {
    log "Cleaning build artifacts..."
    find . -type f -name "*.build" -delete
    find . -type f -name "*.swiftmodule" -delete
    find . -type d -name ".build" -exec rm -rf {} + 2>/dev/null || true
}

# Verify and create directory structure (only creates missing directories)
verify_directory_structure() {
    log "Verifying directory structure..."
    
    local -a directories=(
        "Core/Device/Discovery" "Core/Device/Management"
        "Core/Effect/Patterns" "Core/Effect/Transitions"
        "Core/Network/Protocol" "Core/Network/Socket"
        "Core/Scene/Templates"
        "Core/Security/Encryption"
        "Core/Services/Interfaces" "Core/Services/Implementation"
        "Core/Storage/CoreData" "Core/Storage/UserDefaults"
        "Features/Automation/Rules" "Features/Automation/Triggers"
        "Features/Effects" "Features/Effects/Music" "Features/Effects/Presets"
        "Features/Rooms" "Features/Rooms/Management"
        "Features/Scenes/Templates"
        "UI/Components/Buttons" "UI/Components/Cards" "UI/Components/Lists"
        "UI/Views/Device" "UI/Views/Scene" "UI/Views/Settings"
        "Controllers" "Controllers/Navigation"
        "Extensions" "Extensions/Foundation" "Extensions/SwiftUI" "Extensions/UIKit"
        "Models" "Models/Device" "Models/Scene" "Models/Settings"
        "Services" "Services/Analytics" "Services/Network" "Services/Storage"
        "Utils" "Utils/Constants" "Utils/Helpers" "Utils/Protocols"
        "Views" "Views/Common" "Views/Custom"
        "Tests/UITests/Screens" "Tests/UITests/Flows"
        "Tests/UnitTests/Core" "Tests/UnitTests/Features" "Tests/UnitTests/Services"
        "Widget/Views" "Widget/Models"
    )

    for dir in "${directories[@]}"; do
        if [[ ! -d "Sources/${dir}" ]]; then
            mkdir -p "Sources/${dir}"
            warning "Created missing directory: ${dir}"
        fi
    done
}

# Verify required files exist (only creates if missing and not in GitHub)
verify_required_files() {
    log "Verifying required files..."
    local -a required_files=(
        "Core/Services/ServiceProtocols.swift"
        "Core/Device/YeelightModels.swift"
        "Core/Error/DomainErrors.swift"
        "Core/Error/LoggingTypes.swift"
        "UI/Views/MainView.swift"
        "Widget/YeelightWidget.swift"
    )

    for file in "${required_files[@]}"; do
        if [[ ! -f "Sources/${file}" ]]; then
            # Check if file exists in GitHub first
            if git ls-tree -r --name-only origin/main | grep -q "^Sources/${file}$"; then
                warning "Restoring missing file from GitHub: Sources/${file}"
                git checkout origin/main -- "Sources/${file}"
            else
                log "Creating new file: Sources/${file}"
                create_swift_file_template "Sources/${file}"
            fi
        fi
    done
}

# Create Swift file template (only for new files)
create_swift_file_template() {
    local file_path="$1"
    local file_name=$(basename "${file_path}")
    local module_name=$(echo "${file_path}" | cut -d'/' -f2)
    
    # Only create if file doesn't exist
    if [[ ! -f "${file_path}" ]]; then
        mkdir -p "$(dirname "${file_path}")"
        
        cat > "${file_path}" << EOF
//
//  ${file_name}
//  YeelightControl
//
//  Created by YeelightControl on $(date +'%Y-%m-%d')
//  Copyright © $(date +'%Y') YeelightControl. All rights reserved.
//

import Foundation
import SwiftUI

// TODO: Implement ${file_name%.*}
EOF
    fi
}

# Verify module structure (only creates missing READMEs)
verify_module_structure() {
    log "Verifying module structure..."
    local -a modules=("App" "Core" "Features" "UI" "Widget" "Tests")
    
    for module in "${modules[@]}"; do
        if [[ ! -f "Sources/${module}/README.md" ]]; then
            # Check if README exists in GitHub first
            if git ls-tree -r --name-only origin/main | grep -q "^Sources/${module}/README.md$"; then
                warning "Restoring README from GitHub: Sources/${module}/README.md"
                git checkout origin/main -- "Sources/${module}/README.md"
            else
                local module_lower=$(echo "$module" | tr '[:upper:]' '[:lower:]')
                cat > "Sources/${module}/README.md" << EOF
# ${module} Module

This module contains the ${module_lower} components of the YeelightControl application.

## Overview

TODO: Add module overview and documentation.
EOF
            fi
        fi
    done
}

# Verify configuration files (only creates if missing)
verify_config_files() {
    log "Verifying configuration files..."
    
    if [[ ! -f ".swiftlint.yml" ]]; then
        if git ls-tree -r --name-only origin/main | grep -q "^.swiftlint.yml$"; then
            warning "Restoring .swiftlint.yml from GitHub"
            git checkout origin/main -- ".swiftlint.yml"
        else
            cat > ".swiftlint.yml" << EOF
disabled_rules:
  - trailing_whitespace
  - line_length
  
opt_in_rules:
  - empty_count
  - missing_docs
  
included:
  - Sources
excluded:
  - Tests
EOF
        fi
    fi
    
    if [[ ! -f "project.yml" ]]; then
        if git ls-tree -r --name-only origin/main | grep -q "^project.yml$"; then
            warning "Restoring project.yml from GitHub"
            git checkout origin/main -- "project.yml"
        else
            cat > "project.yml" << EOF
name: YeelightControl
options:
  bundleIdPrefix: com.yeelightcontrol
  deploymentTarget:
    iOS: 15.0
    macOS: 12.0
  
targets:
  YeelightControl:
    type: application
    platform: iOS
    sources: [Sources/App]
    dependencies:
      - target: Core
      - target: UI
      - target: Features
      
  Core:
    type: framework
    platform: iOS
    sources: [Sources/Core]
    
  UI:
    type: framework
    platform: iOS
    sources: [Sources/UI]
    dependencies:
      - target: Core
      
  Features:
    type: framework
    platform: iOS
    sources: [Sources/Features]
    dependencies:
      - target: Core
      - target: UI
      
  Widget:
    type: app-extension
    platform: iOS
    sources: [Sources/Widget]
    dependencies:
      - target: Core
EOF
        fi
    fi
}

# Verify Swift files (only reports issues, never deletes)
verify_swift_files() {
    log "Verifying Swift files..."
    find Sources -name "*.swift" -type f | while read -r file; do
        if [[ ! -s "$file" ]]; then
            warning "Empty Swift file found: $file"
        elif ! grep -q "import" "$file"; then
            warning "No imports found in: $file"
        fi
        
        if grep -q "TODO:" "$file"; then
            warning "TODO comment found in: $file"
        fi
    done
}

# Verify file permissions
verify_file_permissions() {
    log "Verifying file permissions..."
    find Sources -type f -exec chmod 644 {} \;
    find Sources -type d -exec chmod 755 {} \;
}

# Main execution
main() {
    log "Starting project reorganization..."
    
    create_backup
    restore_from_github
    clean_build_artifacts
    verify_directory_structure
    verify_required_files
    verify_module_structure
    verify_config_files
    verify_swift_files
    verify_file_permissions
    
    success "Project reorganization completed successfully"
    success "All tasks completed successfully"
}

main 