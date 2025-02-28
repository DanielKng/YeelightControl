#!/bin/bash

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: Xcode is not installed"
    exit 1
fi

# Check if XcodeGen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "Error: XcodeGen is not installed. Please install it with 'brew install xcodegen'"
    exit 1
fi

# Directory setup
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
BUILD_DIR="$PROJECT_ROOT/Build"
SOURCES_DIR="$PROJECT_ROOT/Sources"
CONFIGS_DIR="$PROJECT_ROOT/Resources/Configs"

# Function to log with emoji
log() {
    echo "$1 $2"
}

# Function to handle errors
handle_error() {
    log "❌" "Error: $1"
    exit 1
}

# Create necessary directories
create_directories() {
    log "📁" "Creating directory structure..."
    
    # Create build directory structure
    mkdir -p "$BUILD_DIR/YeelightControl.xcodeproj"
    mkdir -p "$BUILD_DIR/Sources"
    mkdir -p "$BUILD_DIR/Resources"
    mkdir -p "$BUILD_DIR/Tests"
    
    # Create source directories if they don't exist
    directories=(
        "App"
        "Core/Network"
        "Core/Device"
        "Core/Scene"
        "Core/Security"
        "Core/Services"
        "Core/State"
        "Core/Storage"
        "Core/Effect"
        "Core/Error"
        "Core/Location"
        "Core/Notification"
        "Core/Permission"
        "Core/Analytics"
        "Core/Background"
        "Core/Configuration"
        "Features/Effects"
        "Features/Automation"
        "Features/Rooms"
        "Features/Scenes"
        "UI/Views"
        "UI/Components"
        "Widget"
        "Models"
        "Views"
        "Controllers"
        "Utils"
        "Extensions"
        "Services"
        "Tests/YeelightControlTests"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "$SOURCES_DIR/$dir"
        mkdir -p "$BUILD_DIR/Sources/$dir"
    done
}

# Clean previous build
clean_build() {
    log "🧹" "Cleaning build directory..."
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"/*
    fi
}

# Copy source files to build directory
copy_sources() {
    log "📋" "Copying source files to build directory..."
    
    # Copy all source files
    if [ -d "$SOURCES_DIR" ]; then
        cp -R "$SOURCES_DIR"/* "$BUILD_DIR/Sources/"
    else
        handle_error "Sources directory not found"
    fi
    
    # Copy resources if they exist
    if [ -d "$PROJECT_ROOT/Resources" ]; then
        cp -R "$PROJECT_ROOT/Resources" "$BUILD_DIR/"
    fi
    
    # Copy tests if they exist
    if [ -d "$PROJECT_ROOT/Tests" ]; then
        cp -R "$PROJECT_ROOT/Tests" "$BUILD_DIR/"
    fi
}

# Generate Xcode project
generate_project() {
    log "🛠" "Generating Xcode project..."
    
    # Create project.yml for XcodeGen
    cat > "$BUILD_DIR/project.yml" << EOL
name: YeelightControl
options:
  bundleIdPrefix: de.knng.app
  deploymentTarget:
    iOS: 15.0
targets:
  YeelightControl:
    type: application
    platform: iOS
    sources:
      - path: Sources
    settings:
      base:
        INFOPLIST_FILE: Resources/Info.plist
        PRODUCT_BUNDLE_IDENTIFIER: de.knng.app.yeelightcontrol
    info:
      path: Resources/Info.plist
      properties:
        CFBundleDisplayName: YeelightControl
        LSRequiresIPhoneOS: true
        UILaunchStoryboardName: LaunchScreen
        UIRequiredDeviceCapabilities: [armv7]
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
          - UIInterfaceOrientationLandscapeLeft
          - UIInterfaceOrientationLandscapeRight
        NSLocalNetworkUsageDescription: "YeelightControl needs access to your local network to discover and control Yeelight devices."
        NSLocationWhenInUseUsageDescription: "YeelightControl uses your location for automation triggers based on your presence."
        NSMicrophoneUsageDescription: "YeelightControl needs microphone access for music sync features."
  YeelightControlWidget:
    type: app-extension
    platform: iOS
    sources:
      - path: Sources/Widget
    settings:
      base:
        INFOPLIST_FILE: Resources/Widget-Info.plist
        PRODUCT_BUNDLE_IDENTIFIER: de.knng.app.yeelightcontrol.widget
    dependencies:
      - target: YeelightControl
    info:
      path: Resources/Widget-Info.plist
      properties:
        CFBundleDisplayName: YeelightControl Widget
        NSExtension:
          NSExtensionPointIdentifier: com.apple.widgetkit-extension
EOL
    
    # Generate Xcode project using XcodeGen
    cd "$BUILD_DIR" && xcodegen generate || handle_error "Failed to generate Xcode project"
}

# Create Info.plist files
create_info_plists() {
    log "📄" "Creating Info.plist files..."
    
    mkdir -p "$BUILD_DIR/Resources"
    
    # Create main app Info.plist
    cat > "$BUILD_DIR/Resources/Info.plist" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
    </dict>
</dict>
</plist>
EOL
    
    # Create widget Info.plist
    cat > "$BUILD_DIR/Resources/Widget-Info.plist" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
</dict>
</plist>
EOL
}

# Open Xcode project
open_project() {
    log "🚀" "Opening Xcode project..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d "$BUILD_DIR/YeelightControl.xcodeproj" ]; then
            open "$BUILD_DIR/YeelightControl.xcodeproj"
        else
            handle_error "Xcode project not found at $BUILD_DIR/YeelightControl.xcodeproj"
        fi
    fi
}

# Main execution
main() {
    log "🚀" "Setting up YeelightControl project..."
    
    clean_build
    create_directories
    copy_sources
    create_info_plists
    generate_project
    open_project
    
    log "✅" "Setup complete! Project opened in Xcode"
}

# Run the script
main 