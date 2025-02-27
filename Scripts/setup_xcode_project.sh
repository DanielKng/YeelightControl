#!/bin/bash

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: Xcode is not installed"
    exit 1
fi

# Directory setup
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
BUILD_DIR="$PROJECT_ROOT/Build"
SOURCES_DIR="$PROJECT_ROOT/Sources"

# Create build directory if it doesn't exist
mkdir -p "$BUILD_DIR"

# Clean up previous build files
if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"/*
fi

# Create Xcode project structure
echo "Creating Xcode project structure..."
xcodebuild -create \
    -template "iOS Application" \
    -destination "$BUILD_DIR" \
    -productName "YeelightControl" \
    -bundleIdentifier "de.knng.app.yeelightcontrol" \
    -organizationName "Daniel Kng" \
    -deploymentTarget "15.0"

# Create widget extension
echo "Creating widget extension..."
xcodebuild -create \
    -template "iOS Widget Extension" \
    -destination "$BUILD_DIR" \
    -productName "YeelightWidget" \
    -bundleIdentifier "de.knng.app.yeelightcontrol.widget" \
    -organizationName "Daniel Kng" \
    -deploymentTarget "15.0"

# Create symbolic links for development
echo "Creating symbolic links..."
ln -sf "$SOURCES_DIR" "$BUILD_DIR/Sources"
ln -sf "$PROJECT_ROOT/Resources" "$BUILD_DIR/Resources"

# Configure main app build settings
echo "Configuring app build settings..."
xcodebuild -project "$BUILD_DIR/YeelightControl.xcodeproj" \
    -scheme "YeelightControl" \
    -configuration Debug \
    DEVELOPMENT_TEAM="" \
    CODE_SIGN_STYLE="Automatic" \
    PRODUCT_BUNDLE_IDENTIFIER="de.knng.app.yeelightcontrol" \
    MARKETING_VERSION="1.0.0" \
    CURRENT_PROJECT_VERSION="1" \
    TARGETED_DEVICE_FAMILY="1" \
    INFOPLIST_KEY_UILaunchScreen_Generation="YES" \
    INFOPLIST_KEY_UISupportedInterfaceOrientations="UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight" \
    INFOPLIST_KEY_UIApplicationSceneManifest_Generation="YES" \
    INFOPLIST_KEY_NSLocalNetworkUsageDescription="YeelightControl needs access to your local network to discover and control Yeelight devices." \
    INFOPLIST_KEY_NSMicrophoneUsageDescription="YeelightControl needs microphone access for music visualization features." \
    INFOPLIST_KEY_NSLocationWhenInUseUsageDescription="YeelightControl uses your location for automation features."

# Configure widget build settings
echo "Configuring widget build settings..."
xcodebuild -project "$BUILD_DIR/YeelightWidget.xcodeproj" \
    -scheme "YeelightWidget" \
    -configuration Debug \
    DEVELOPMENT_TEAM="" \
    CODE_SIGN_STYLE="Automatic" \
    PRODUCT_BUNDLE_IDENTIFIER="de.knng.app.yeelightcontrol.widget" \
    MARKETING_VERSION="1.0.0" \
    CURRENT_PROJECT_VERSION="1" \
    TARGETED_DEVICE_FAMILY="1" \
    INFOPLIST_KEY_CFBundleDisplayName="YeelightControl" \
    INFOPLIST_KEY_NSHumanReadableCopyright="" \
    ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME="AccentColor" \
    ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME="WidgetBackground"

echo "Project setup complete! Opening Xcode project..."

# Open the Xcode project
if [ -d "$BUILD_DIR/YeelightControl.xcodeproj" ]; then
    open "$BUILD_DIR/YeelightControl.xcodeproj"
else
    echo "Error: Xcode project not found at $BUILD_DIR/YeelightControl.xcodeproj"
    exit 1
fi 