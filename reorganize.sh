#!/bin/bash

# Base directories
BASE_DIR="Sources"
CORE_DIR="$BASE_DIR/Core"
FEATURES_DIR="$BASE_DIR/Features"
UI_DIR="$BASE_DIR/UI"
UTILS_DIR="$BASE_DIR/Utils"
TESTS_DIR="$BASE_DIR/Tests"
RESOURCES_DIR="$BASE_DIR/Resources"
DOCS_DIR="$BASE_DIR/Documentation"

# Backup existing structure
echo "Creating backup of current structure..."
BACKUP_DIR="../YeelightControl_backup_$(date +%Y%m%d_%H%M%S)"
cp -R "$BASE_DIR" "$BACKUP_DIR"

# Remove old directories (after backup)
echo "Cleaning up old structure..."
rm -rf "$BASE_DIR"/*

# Create main directories
echo "Creating new directory structure..."
mkdir -p "$CORE_DIR" "$FEATURES_DIR" "$UI_DIR" "$UTILS_DIR" "$TESTS_DIR" "$RESOURCES_DIR" "$DOCS_DIR"

# Create Core subdirectories
CORE_SUBDIRS=(
    "Analytics"
    "Background"
    "Configuration"
    "Device"
    "Effect"
    "Error"
    "Location"
    "Logger"
    "Network"
    "Notification"
    "Permission"
    "Room"
    "Scene"
    "Security"
    "Services"
    "State"
    "Storage"
    "Theme"
    "Database"
    "Protocols"
    "Extensions"
    "Constants"
)

for dir in "${CORE_SUBDIRS[@]}"; do
    mkdir -p "$CORE_DIR/$dir"
done

# Create Features subdirectories
FEATURES_SUBDIRS=(
    "Automation"
    "Backup"
    "Settings"
    "Rooms"
    "Scenes"
    "Effects"
    "Discovery"
    "Grouping"
    "Scheduling"
    "Statistics"
    "Updates"
)

for dir in "${FEATURES_SUBDIRS[@]}"; do
    mkdir -p "$FEATURES_DIR/$dir"
done

# Create UI subdirectories
mkdir -p "$UI_DIR/Components/Common"
mkdir -p "$UI_DIR/Components/Custom"
mkdir -p "$UI_DIR/Components/Charts"
mkdir -p "$UI_DIR/Components/Modals"
mkdir -p "$UI_DIR/Components/Forms"
mkdir -p "$UI_DIR/Screens/Automation"
mkdir -p "$UI_DIR/Screens/Device"
mkdir -p "$UI_DIR/Screens/Room"
mkdir -p "$UI_DIR/Screens/Settings"
mkdir -p "$UI_DIR/Screens/Statistics"
mkdir -p "$UI_DIR/Screens/Onboarding"
mkdir -p "$UI_DIR/Styles"
mkdir -p "$UI_DIR/Views"
mkdir -p "$UI_DIR/ViewModels"
mkdir -p "$UI_DIR/Animations"
mkdir -p "$UI_DIR/Transitions"

# Create Utils subdirectories
mkdir -p "$UTILS_DIR/Extensions"
mkdir -p "$UTILS_DIR/Helpers"
mkdir -p "$UTILS_DIR/Formatters"
mkdir -p "$UTILS_DIR/Validators"
mkdir -p "$UTILS_DIR/Converters"
mkdir -p "$UTILS_DIR/Debug"

# Create Tests subdirectories
mkdir -p "$TESTS_DIR/UnitTests/Core"
mkdir -p "$TESTS_DIR/UnitTests/Features"
mkdir -p "$TESTS_DIR/UnitTests/UI"
mkdir -p "$TESTS_DIR/UnitTests/Utils"
mkdir -p "$TESTS_DIR/UITests"
mkdir -p "$TESTS_DIR/IntegrationTests"
mkdir -p "$TESTS_DIR/PerformanceTests"
mkdir -p "$TESTS_DIR/Mocks"

# Create Resources subdirectories
mkdir -p "$RESOURCES_DIR/Assets"
mkdir -p "$RESOURCES_DIR/Fonts"
mkdir -p "$RESOURCES_DIR/Localization"
mkdir -p "$RESOURCES_DIR/JSON"
mkdir -p "$RESOURCES_DIR/Plists"
mkdir -p "$RESOURCES_DIR/Audio"

# Create Documentation subdirectories
mkdir -p "$DOCS_DIR/Architecture"
mkdir -p "$DOCS_DIR/API"
mkdir -p "$DOCS_DIR/Guides"
mkdir -p "$DOCS_DIR/Screenshots"
mkdir -p "$DOCS_DIR/Diagrams"

echo "Moving files from backup..."
# Function to safely copy files
safe_copy() {
    if [ -f "$BACKUP_DIR/$1" ]; then
        mkdir -p "$(dirname "$BASE_DIR/$2")"
        cp "$BACKUP_DIR/$1" "$BASE_DIR/$2"
        echo "Copied: $1 -> $2"
    else
        echo "Warning: Source file not found: $1"
    fi
}

# Core files
safe_copy "Core/Analytics/UnifiedAnalyticsManager.swift" "Core/Analytics/UnifiedAnalyticsManager.swift"
safe_copy "Core/Background/UnifiedBackgroundManager.swift" "Core/Background/UnifiedBackgroundManager.swift"
safe_copy "Core/Configuration/UnifiedConfigurationManager.swift" "Core/Configuration/UnifiedConfigurationManager.swift"
safe_copy "Core/Device/UnifiedDeviceManager.swift" "Core/Device/UnifiedDeviceManager.swift"
safe_copy "Core/Effect/UnifiedEffectManager.swift" "Core/Effect/UnifiedEffectManager.swift"
safe_copy "Core/Error/UnifiedErrorHandler.swift" "Core/Error/UnifiedErrorHandler.swift"
safe_copy "Core/Location/UnifiedLocationManager.swift" "Core/Location/UnifiedLocationManager.swift"
safe_copy "Core/Network/UnifiedNetworkManager.swift" "Core/Network/UnifiedNetworkManager.swift"
safe_copy "Core/Notification/UnifiedNotificationManager.swift" "Core/Notification/UnifiedNotificationManager.swift"
safe_copy "Core/Permission/UnifiedPermissionManager.swift" "Core/Permission/UnifiedPermissionManager.swift"
safe_copy "Core/Scene/UnifiedSceneManager.swift" "Core/Scene/UnifiedSceneManager.swift"
safe_copy "Core/Security/UnifiedSecurityManager.swift" "Core/Security/UnifiedSecurityManager.swift"
safe_copy "Core/Services/ServiceContainer.swift" "Core/Services/ServiceContainer.swift"
safe_copy "Core/State/UnifiedStateManager.swift" "Core/State/UnifiedStateManager.swift"
safe_copy "Core/Storage/UnifiedStorageManager.swift" "Core/Storage/UnifiedStorageManager.swift"

# UI Components
safe_copy "Core/UI/Components/UnifiedButton.swift" "UI/Components/Common/UnifiedButton.swift"
safe_copy "Core/UI/Components/UnifiedCard.swift" "UI/Components/Common/UnifiedCard.swift"
safe_copy "Core/UI/Components/UnifiedTextField.swift" "UI/Components/Common/UnifiedTextField.swift"

# Feature files
safe_copy "Features/Automation/AutomationManager.swift" "Features/Automation/AutomationManager.swift"
safe_copy "Features/Effects/EffectManager.swift" "Features/Effects/EffectManager.swift"
safe_copy "Features/Rooms/RoomManager.swift" "Features/Rooms/RoomManager.swift"
safe_copy "Features/Scenes/SceneManager.swift" "Features/Scenes/SceneManager.swift"

# Move Views
if [ -d "$BACKUP_DIR/UI/Views" ]; then
    cp -R "$BACKUP_DIR/UI/Views"/* "$UI_DIR/Views/"
    echo "Copied UI Views"
fi

# Move Tests
if [ -d "$BACKUP_DIR/Tests" ]; then
    cp -R "$BACKUP_DIR/Tests"/* "$TESTS_DIR/"
    echo "Copied Tests"
fi

echo "Cleaning up empty directories..."
find "$BASE_DIR" -type d -empty -delete

echo "Folder structure reorganization complete!"
echo "Backup of old structure saved to: $BACKUP_DIR"

# Make script executable
chmod +x reorganize.sh 