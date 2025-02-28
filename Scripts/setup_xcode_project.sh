#!/bin/bash

set -e

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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/Build"
SOURCES_DIR="$PROJECT_ROOT/Sources"
CONFIGS_DIR="$BUILD_DIR/Configs"
MODULES_DIR="$BUILD_DIR/Modules"

# Create build directory if it doesn't exist
mkdir -p "$BUILD_DIR"
mkdir -p "$CONFIGS_DIR"
mkdir -p "$BUILD_DIR/Sources"
mkdir -p "$MODULES_DIR"

# Clean up previous build files but preserve symlinks
find "$BUILD_DIR" -type f -not -name "*.symlink" -delete

# Function to create Swift module
create_swift_module() {
    local module_name=$1
    local source_dir=$2
    local target_dir="$BUILD_DIR/Sources/$module_name"
    
    echo "Set up Swift module $module_name at $target_dir"
    mkdir -p "$target_dir"
    
    # Create symlinks for Swift files
    find "$source_dir" -type f -name "*.swift" | while read -r source_file; do
        relative_path=${source_file#$source_dir/}
        target_path="$target_dir/$relative_path"
        mkdir -p "$(dirname "$target_path")"
        ln -sf "$source_file" "$target_path"
        echo "Created symlink for $relative_path"
    done
}

# Set up modules
create_swift_module "Core" "$SOURCES_DIR/Core"
create_swift_module "UI" "$SOURCES_DIR/UI"
create_swift_module "Features" "$SOURCES_DIR/Features"

# Function to create Info.plist
create_info_plist() {
    local name=$1
    local bundle_id=$2
    local output_file="$CONFIGS_DIR/$name-Info.plist"
    
    cat > "$output_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>\$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$bundle_id</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>\$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>\$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
EOF
    echo "Created $name-Info.plist"
}

# Create Info.plist files
create_info_plist "App" "de.knng.app.yeelightcontrol"
create_info_plist "Core" "de.knng.app.yeelightcontrol.core"
create_info_plist "UI" "de.knng.app.yeelightcontrol.ui"
create_info_plist "Features" "de.knng.app.yeelightcontrol.features"
create_info_plist "Widget" "de.knng.app.yeelightcontrol.widget"

# Create symlinks for App and Widget modules
create_swift_module "App" "$SOURCES_DIR/App"
create_swift_module "Widget" "$SOURCES_DIR/Widget"
create_swift_module "Tests" "$SOURCES_DIR/Tests"

echo "📝 Creating XcodeGen configuration..."

# Generate project.yml
cat > "$BUILD_DIR/project.yml" << EOF
name: YeelightControl
options:
  bundleIdPrefix: de.knng.app
  deploymentTarget: 
    iOS: 15.0
  xcodeVersion: 15.2
  generateEmptyDirectories: true
  createIntermediateGroups: true
settings:
  base:
    SWIFT_VERSION: 5.0
    DEVELOPMENT_TEAM: \${DEVELOPMENT_TEAM}
    CODE_SIGN_STYLE: Automatic
    ENABLE_BITCODE: NO
    ENABLE_TESTABILITY: YES
    SWIFT_OPTIMIZATION_LEVEL: "-Onone"
targets:
  YeelightControl:
    type: application
    platform: iOS
    sources: 
      - path: Sources/App
    dependencies:
      - target: Core
      - target: UI
      - target: Features
    info:
      path: Configs/App-Info.plist
      properties:
        UILaunchStoryboardName: LaunchScreen
        UIApplicationSceneManifest:
          UIApplicationSupportsMultipleScenes: true
  Core:
    type: framework
    platform: iOS
    sources:
      - path: Sources/Core
    info:
      path: Configs/Core-Info.plist
  UI:
    type: framework
    platform: iOS
    sources:
      - path: Sources/UI
    dependencies:
      - target: Core
    info:
      path: Configs/UI-Info.plist
  Features:
    type: framework
    platform: iOS
    sources:
      - path: Sources/Features
    dependencies:
      - target: Core
      - target: UI
    info:
      path: Configs/Features-Info.plist
  Widget:
    type: app-extension
    platform: iOS
    sources:
      - path: Sources/Widget
    dependencies:
      - target: Core
    info:
      path: Configs/Widget-Info.plist
      properties:
        NSExtension:
          NSExtensionPointIdentifier: com.apple.widgetkit-extension
EOF

echo "🛠 Running XcodeGen..."
cd "$BUILD_DIR" && xcodegen generate

echo "✅ Setup complete!"

# Verify generated files
echo -e "\nVerifying generated files:"
echo "Project files:"
ls -la "$BUILD_DIR/YeelightControl.xcodeproj"
echo -e "\nConfig files:"
ls -la "$CONFIGS_DIR"
echo -e "\nModule files:"
ls -la "$MODULES_DIR"
echo -e "\nSymlinks:"
find "$BUILD_DIR/Sources" -type l -ls 