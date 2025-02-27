#!/bin/bash

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: Xcode is not installed"
    exit 1
fi

# Check if xcodegen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "Error: xcodegen is not installed. Please install it using 'brew install xcodegen'"
    exit 1
fi

# Directory setup
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR"
XCODE_DIR="$PROJECT_DIR/Xcode"
SOURCES_DIR="$PROJECT_DIR/Sources"

# Create Xcode directory if it doesn't exist
mkdir -p "$XCODE_DIR"

# Clean up previous Xcode project files but keep any user-specific settings
if [ -d "$XCODE_DIR/YeelightControl.xcodeproj" ]; then
    rm -rf "$XCODE_DIR/YeelightControl.xcodeproj"
fi

# Remove old Sources directory in Xcode folder if it exists
if [ -d "$XCODE_DIR/Sources" ]; then
    rm -rf "$XCODE_DIR/Sources"
fi

# Copy Sources directory to Xcode folder
echo "Copying source files to Xcode directory..."
cp -R "$SOURCES_DIR" "$XCODE_DIR/"

# Remove existing project.yml if it exists
rm -f "$XCODE_DIR/project.yml"

# Create new project.yml configuration
cat << 'EOL' > "$XCODE_DIR/project.yml"
name: YeelightControl
options:
  bundleIdPrefix: de.knng.app.yeelightcontrol
  deploymentTarget:
    iOS: 15.0
  xcodeVersion: "14.0"
  groupSortPosition: top
  generateEmptyDirectories: true
  platform: iOS
  defaultConfig: Debug

settings:
  base:
    SUPPORTED_PLATFORMS: "iphoneos iphonesimulator"
    TARGETED_DEVICE_FAMILY: 1
    SUPPORTS_MACCATALYST: NO
    SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD: NO
    SUPPORTS_VISION_OS: NO
    IPHONEOS_DEPLOYMENT_TARGET: 15.0
    ENABLE_MACCATALYST: NO
    DERIVE_MACCATALYST_PRODUCT_BUNDLE_IDENTIFIER: NO

targets:
  YeelightControl:
    type: application
    platform: iOS
    sources: 
      - path: Sources/App
    dependencies:
      - target: Core
        embed: true
      - target: Features
        embed: true
      - target: UI
        embed: true
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: de.knng.app.yeelightcontrol
        DEVELOPMENT_TEAM: ""
        CODE_SIGN_STYLE: Automatic
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations: "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        INFOPLIST_KEY_BGTaskSchedulerPermittedIdentifiers: ["de.knng.app.yeelightcontrol.refresh"]
        INFOPLIST_KEY_NSLocalNetworkUsageDescription: "YeelightControl needs access to your local network to discover and control Yeelight devices."
        INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents: YES
        TARGETED_DEVICE_FAMILY: 1
        SUPPORTS_MACCATALYST: NO
        SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD: NO
        SUPPORTS_VISION_OS: NO
        ENABLE_MACCATALYST: NO

  Core:
    type: framework
    platform: iOS
    sources:
      - path: Sources/Core
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: de.knng.app.yeelightcontrol.core
        DEVELOPMENT_TEAM: ""
        CODE_SIGN_STYLE: Automatic
        GENERATE_INFOPLIST_FILE: YES
        CURRENT_PROJECT_VERSION: 1
        MARKETING_VERSION: 1.0
        DEFINES_MODULE: YES
        TARGETED_DEVICE_FAMILY: 1
        SUPPORTS_MACCATALYST: NO
        SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD: NO
        SUPPORTS_VISION_OS: NO
        ENABLE_MACCATALYST: NO

  Features:
    type: framework
    platform: iOS
    sources:
      - path: Sources/Features
    dependencies:
      - target: Core
        embed: true
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: de.knng.app.yeelightcontrol.features
        DEVELOPMENT_TEAM: ""
        CODE_SIGN_STYLE: Automatic
        GENERATE_INFOPLIST_FILE: YES
        CURRENT_PROJECT_VERSION: 1
        MARKETING_VERSION: 1.0
        DEFINES_MODULE: YES
        TARGETED_DEVICE_FAMILY: 1
        SUPPORTS_MACCATALYST: NO
        SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD: NO
        SUPPORTS_VISION_OS: NO
        ENABLE_MACCATALYST: NO

  UI:
    type: framework
    platform: iOS
    sources:
      - path: Sources/UI
    dependencies:
      - target: Core
        embed: true
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: de.knng.app.yeelightcontrol.ui
        DEVELOPMENT_TEAM: ""
        CODE_SIGN_STYLE: Automatic
        GENERATE_INFOPLIST_FILE: YES
        CURRENT_PROJECT_VERSION: 1
        MARKETING_VERSION: 1.0
        DEFINES_MODULE: YES
        TARGETED_DEVICE_FAMILY: 1
        SUPPORTS_MACCATALYST: NO
        SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD: NO
        SUPPORTS_VISION_OS: NO
        ENABLE_MACCATALYST: NO

  Widget:
    type: app-extension
    platform: iOS
    sources:
      - path: Sources/Widget
    dependencies:
      - target: Core
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: de.knng.app.yeelightcontrol.widget
        DEVELOPMENT_TEAM: ""
        CODE_SIGN_STYLE: Automatic
        GENERATE_INFOPLIST_FILE: YES
        CURRENT_PROJECT_VERSION: 1
        MARKETING_VERSION: 1.0
        INFOPLIST_KEY_CFBundleDisplayName: YeelightControl
        INFOPLIST_KEY_NSHumanReadableCopyright: ""
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME: WidgetBackground
        TARGETED_DEVICE_FAMILY: 1
        SUPPORTS_MACCATALYST: NO
        SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD: NO
        SUPPORTS_VISION_OS: NO
        ENABLE_MACCATALYST: NO

  YeelightControlTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: Sources/Tests/UnitTests
    dependencies:
      - target: YeelightControl
      - target: Core
      - target: Features
      - target: UI
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: de.knng.app.yeelightcontrol.tests
        DEVELOPMENT_TEAM: ""
        CODE_SIGN_STYLE: Automatic
        GENERATE_INFOPLIST_FILE: YES
        CURRENT_PROJECT_VERSION: 1
        MARKETING_VERSION: 1.0
        TARGETED_DEVICE_FAMILY: 1
        SUPPORTS_MACCATALYST: NO
        SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD: NO
        SUPPORTS_VISION_OS: NO
        ENABLE_MACCATALYST: NO

schemes:
  YeelightControl:
    build:
      targets:
        YeelightControl: all
        Core: [run, test]
        Features: [run, test]
        UI: [run, test]
        Widget: [run, test]
    run:
      config: Debug
      environmentVariables:
        OS_ACTIVITY_MODE: disable
      target: YeelightControl
    test:
      config: Debug
      targets:
        - YeelightControlTests
      environmentVariables:
        OS_ACTIVITY_MODE: disable
    profile:
      config: Release
    analyze:
      config: Debug
    archive:
      config: Release
      customArchiveName: YeelightControl
      revealArchiveInOrganizer: true

  Widget:
    build:
      targets:
        Widget: all
        Core: [run, test]
    run:
      config: Debug
      target: Widget

default:
  scheme: YeelightControl
EOL

# Generate new Xcode project
cd "$XCODE_DIR" && xcodegen generate

if [ $? -eq 0 ]; then
    echo "Project setup complete. Opening Xcode project..."
    open "$XCODE_DIR/YeelightControl.xcodeproj"
else
    echo "Error: Failed to generate Xcode project"
    exit 1
fi 