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
CONFIGS_DIR="$BUILD_DIR/Configs"

# Create build directory if it doesn't exist
mkdir -p "$BUILD_DIR"
mkdir -p "$CONFIGS_DIR"

# Clean up previous build files
if [ -d "$BUILD_DIR" ]; then
    # Only remove non-symlink files and directories to preserve our symlinks
    find "$BUILD_DIR" -type f -not -name "project.yml" -delete
    find "$BUILD_DIR" -type l -delete  # Remove old symlinks
fi

# Create Sources directory in Build
mkdir -p "$BUILD_DIR/Sources"

# Create symbolic links recursively
create_symlinks() {
    local source_dir="$1"
    local build_dir="$2"
    local relative_path="$3"
    
    # Create the directory in build if it doesn't exist
    mkdir -p "$build_dir"
    
    # Loop through all items in the source directory
    for item in "$source_dir"/*; do
        # Skip if the item doesn't exist
        [ ! -e "$item" ] && continue
        
        # Get the base name of the item
        local name=$(basename "$item")
        local build_path="$build_dir/$name"
        local source_path="$item"
        
        # Skip if the item is .DS_Store
        if [ "$name" = ".DS_Store" ]; then
            continue
        fi
        
        # Remove existing symlink or directory
        rm -rf "$build_path"
        
        # If it's a directory, create it and recurse
        if [ -d "$item" ]; then
            mkdir -p "$build_path"
            create_symlinks "$source_path" "$build_path" "$relative_path/$name"
        else
            # If it's a file, create a symbolic link
            if [ -f "$item" ]; then
                # Create relative symlink
                ln -s "../../../Sources$relative_path/$name" "$build_path"
                echo "Created symlink: Sources$relative_path/$name -> Build/Sources$relative_path/$name"
            fi
        fi
    done
}

# Create Info.plist files
echo "📄 Creating Info.plist files..."

# Create main app Info.plist
cat > "$CONFIGS_DIR/App-Info.plist" << 'EOL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>YeelightControl</string>
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
    <key>NSLocalNetworkUsageDescription</key>
    <string>YeelightControl needs access to your local network to discover and control Yeelight devices.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>YeelightControl uses your location for automation features.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>YeelightControl needs microphone access for music visualization features.</string>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
    </dict>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>
EOL

# Create widget Info.plist
cat > "$CONFIGS_DIR/Widget-Info.plist" << 'EOL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>YeelightWidget</string>
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

# Create Core framework Info.plist
cat > "$CONFIGS_DIR/Core-Info.plist" << 'EOL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
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
</dict>
</plist>
EOL

# Create UI framework Info.plist
cat > "$CONFIGS_DIR/UI-Info.plist" << 'EOL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
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
</dict>
</plist>
EOL

# Create Features framework Info.plist
cat > "$CONFIGS_DIR/Features-Info.plist" << 'EOL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
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
</dict>
</plist>
EOL

# Create project.yml
echo "📝 Creating XcodeGen configuration..."
cat > "$BUILD_DIR/project.yml" << 'EOL'
name: YeelightControl
options:
  bundleIdPrefix: de.knng.app
  deploymentTarget:
    iOS: 15.0
  xcodeVersion: "15.2"
  generateEmptyDirectories: true
  createIntermediateGroups: true
  useBaseInternationalization: true
  groupSortPosition: top
  indentWidth: 4
  tabWidth: 4
  defaultConfig: Debug

settings:
  base:
    DEVELOPMENT_TEAM: ""
    CODE_SIGN_STYLE: Automatic
    MARKETING_VERSION: 1.0.0
    CURRENT_PROJECT_VERSION: 1
    SWIFT_VERSION: 5.0
    ENABLE_BITCODE: NO
    CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED: YES
    CLANG_ANALYZER_NONNULL: YES
    CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION: YES_AGGRESSIVE
    CLANG_CXX_LANGUAGE_STANDARD: gnu++20
    CLANG_ENABLE_MODULES: YES
    CLANG_ENABLE_OBJC_ARC: YES
    CLANG_ENABLE_OBJC_WEAK: YES
    CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING: YES
    CLANG_WARN_BOOL_CONVERSION: YES
    CLANG_WARN_COMMA: YES
    CLANG_WARN_CONSTANT_CONVERSION: YES
    CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS: YES
    CLANG_WARN_DIRECT_OBJC_ISA_USAGE: YES_ERROR
    CLANG_WARN_DOCUMENTATION_COMMENTS: YES
    CLANG_WARN_EMPTY_BODY: YES
    CLANG_WARN_ENUM_CONVERSION: YES
    CLANG_WARN_INFINITE_RECURSION: YES
    CLANG_WARN_INT_CONVERSION: YES
    CLANG_WARN_NON_LITERAL_NULL_CONVERSION: YES
    CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF: YES
    CLANG_WARN_OBJC_LITERAL_CONVERSION: YES
    CLANG_WARN_OBJC_ROOT_CLASS: YES_ERROR
    CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER: YES
    CLANG_WARN_RANGE_LOOP_ANALYSIS: YES
    CLANG_WARN_STRICT_PROTOTYPES: YES
    CLANG_WARN_SUSPICIOUS_MOVE: YES
    CLANG_WARN_UNGUARDED_AVAILABILITY: YES_AGGRESSIVE
    CLANG_WARN_UNREACHABLE_CODE: YES
    CLANG_WARN__DUPLICATE_METHOD_MATCH: YES
    ENABLE_STRICT_OBJC_MSGSEND: YES
    ENABLE_TESTABILITY: YES
    GCC_NO_COMMON_BLOCKS: YES
    GCC_WARN_64_TO_32_BIT_CONVERSION: YES
    GCC_WARN_ABOUT_RETURN_TYPE: YES_ERROR
    GCC_WARN_UNDECLARED_SELECTOR: YES
    GCC_WARN_UNINITIALIZED_AUTOS: YES_AGGRESSIVE
    GCC_WARN_UNUSED_FUNCTION: YES
    GCC_WARN_UNUSED_VARIABLE: YES
    SWIFT_ACTIVE_COMPILATION_CONDITIONS: DEBUG
    SWIFT_OPTIMIZATION_LEVEL: "-Onone"
    SWIFT_STRICT_CONCURRENCY: complete

targets:
  Core:
    type: framework
    platform: iOS
    sources:
      - path: Sources/Core
    info:
      path: Configs/Core-Info.plist
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: de.knng.app.yeelightcontrol.core
        TARGETED_DEVICE_FAMILY: 1
        ENABLE_PREVIEWS: YES
        DEFINES_MODULE: YES
        GENERATE_INFOPLIST_FILE: YES
        PRODUCT_NAME: Core
        SWIFT_INSTALL_OBJC_HEADER: NO
        SWIFT_EMIT_MODULE_INTERFACE: YES
    dependencies:
      - framework: SwiftUI
      - framework: Foundation
      - framework: CoreLocation
      - framework: Network
      - framework: Combine
      - framework: CoreData
      - framework: Security
      - framework: UniformTypeIdentifiers

  UI:
    type: framework
    platform: iOS
    sources:
      - path: Sources/UI
    info:
      path: Configs/UI-Info.plist
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: de.knng.app.yeelightcontrol.ui
        TARGETED_DEVICE_FAMILY: 1
        ENABLE_PREVIEWS: YES
        DEFINES_MODULE: YES
        GENERATE_INFOPLIST_FILE: YES
        PRODUCT_NAME: UI
        SWIFT_INSTALL_OBJC_HEADER: NO
        SWIFT_EMIT_MODULE_INTERFACE: YES
    dependencies:
      - target: Core
      - framework: SwiftUI

  Features:
    type: framework
    platform: iOS
    sources:
      - path: Sources/Features
    info:
      path: Configs/Features-Info.plist
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: de.knng.app.yeelightcontrol.features
        TARGETED_DEVICE_FAMILY: 1
        ENABLE_PREVIEWS: YES
        DEFINES_MODULE: YES
        GENERATE_INFOPLIST_FILE: YES
        PRODUCT_NAME: Features
        SWIFT_INSTALL_OBJC_HEADER: NO
        SWIFT_EMIT_MODULE_INTERFACE: YES
    dependencies:
      - target: Core
      - target: UI
      - framework: SwiftUI

  YeelightControl:
    type: application
    platform: iOS
    sources:
      - path: Sources/App
    info:
      path: Configs/App-Info.plist
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: de.knng.app.yeelightcontrol
        TARGETED_DEVICE_FAMILY: 1
        ENABLE_PREVIEWS: YES
        SWIFT_TREAT_WARNINGS_AS_ERRORS: NO
        OTHER_LDFLAGS: [-ObjC]
        SWIFT_OPTIMIZATION_LEVEL: "-Onone"
        DEBUG_INFORMATION_FORMAT: dwarf-with-dsym
        CLANG_ENABLE_MODULES: YES
        DEFINES_MODULE: YES
        SWIFT_INSTALL_OBJC_HEADER: NO
        SWIFT_EMIT_MODULE_INTERFACE: YES
    dependencies:
      - target: Core
      - target: UI
      - target: Features
      - framework: SwiftUI
        
  YeelightWidget:
    type: app-extension
    platform: iOS
    sources:
      - path: Sources/Widget
    info:
      path: Configs/Widget-Info.plist
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: de.knng.app.yeelightcontrol.widget
        TARGETED_DEVICE_FAMILY: 1
        ENABLE_PREVIEWS: YES
        SWIFT_TREAT_WARNINGS_AS_ERRORS: NO
        SWIFT_INSTALL_OBJC_HEADER: NO
        SWIFT_EMIT_MODULE_INTERFACE: YES
    dependencies:
      - target: Core
      - target: UI
      - framework: SwiftUI
      - framework: WidgetKit

schemes:
  YeelightControl:
    build:
      targets:
        Core: [run, test]
        UI: [run, test]
        Features: [run, test]
        YeelightControl: all
        YeelightWidget: [run, test]
    run:
      config: Debug
      environmentVariables:
        - SWIFT_DEBUG_CONCURRENCY: 1
    test:
      config: Debug
      targets:
        - Core
        - UI
        - Features
    profile:
      config: Release
    analyze:
      config: Debug
    archive:
      config: Release
EOL

# Create symbolic links
echo "🔗 Creating symbolic links..."
create_symlinks "$SOURCES_DIR" "$BUILD_DIR/Sources" ""

# Run XcodeGen
echo "🛠 Running XcodeGen..."
cd "$BUILD_DIR" && xcodegen generate

echo "✅ Setup complete!"

# Try to open the Xcode project
if [ -d "$BUILD_DIR/YeelightControl.xcodeproj" ]; then
    echo "Opening Xcode project..."
    open "$BUILD_DIR/YeelightControl.xcodeproj"
fi

# Verify generated files
echo -e "\nVerifying generated files:"
echo "Project files:"
ls -la "$BUILD_DIR/YeelightControl.xcodeproj"
echo -e "\nConfig files:"
ls -la "$CONFIGS_DIR"
echo -e "\nSymlinks:"
find "$BUILD_DIR/Sources" -type l -exec ls -l {} \; 