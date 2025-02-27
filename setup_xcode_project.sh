#!/bin/bash

# YeelightControl Xcode Project Generator
PROJECT_NAME="YeelightControl"
WORKSPACE_ROOT="$(pwd)"
SOURCE_DIR="$WORKSPACE_ROOT/Sources"
XCODE_DIR="$WORKSPACE_ROOT/Xcode"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🚀 Setting up Xcode project for $PROJECT_NAME..."

# Verify Xcode installation
if [ ! -d "/Applications/Xcode.app" ]; then
    echo -e "${RED}Error: Xcode.app not found${NC}"
    exit 1
fi

# Clean and create directories
rm -rf "$XCODE_DIR"
mkdir -p "$XCODE_DIR"

# Copy source files
echo "📂 Copying source files..."
cp -R "$SOURCE_DIR" "$XCODE_DIR/Sources"

# Create project.yml
echo "📝 Creating project configuration..."
cat > "$XCODE_DIR/project.yml" << EOL
name: YeelightControl
options:
  createIntermediateGroups: true
  bundleIdPrefix: com.yeelightcontrol
  deploymentTarget:
    iOS: 17.0
  xcodeVersion: "15.0"
packages:
  SwiftLint:
    url: https://github.com/realm/SwiftLint
    from: 0.54.0
settings:
  base:
    DEVELOPMENT_TEAM: ""
    CODE_SIGN_STYLE: Automatic
    CODE_SIGN_IDENTITY: "Apple Development"
    SWIFT_VERSION: "5.9"
    GENERATE_INFOPLIST_FILE: YES
    MARKETING_VERSION: "1.0.0"
    CURRENT_PROJECT_VERSION: "1"
targets:
  YeelightControl:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - Sources/App
      - Sources/Core
      - Sources/Features
      - Sources/UI
      - Sources/Widget
    info:
      path: Sources/App/Info.plist
      properties:
        CFBundleDisplayName: YeelightControl
        LSApplicationCategoryType: "public.app-category.utilities"
        NSLocalNetworkUsageDescription: "YeelightControl needs access to your local network to discover and control Yeelight devices"
        UIApplicationSceneManifest:
          UIApplicationSupportsMultipleScenes: false
          UISceneConfigurations: {}
        UILaunchScreen: {}
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
          - UIInterfaceOrientationLandscapeLeft
          - UIInterfaceOrientationLandscapeRight
        UISupportedInterfaceOrientations~ipad:
          - UIInterfaceOrientationPortrait
          - UIInterfaceOrientationPortraitUpsideDown
          - UIInterfaceOrientationLandscapeLeft
          - UIInterfaceOrientationLandscapeRight
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.yeelightcontrol.app
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        TARGETED_DEVICE_FAMILY: "1,2"
        ENABLE_PREVIEWS: YES
    preBuildScripts:
      - name: SwiftLint
        script: |
          if which swiftlint > /dev/null; then
            swiftlint
          else
            echo "warning: SwiftLint not installed"
          fi
schemes:
  YeelightControl:
    build:
      targets:
        YeelightControl: all
    run:
      config: Debug
    profile:
      config: Release
    analyze:
      config: Debug
    archive:
      config: Release
EOL

# Create Info.plist directory
mkdir -p "$XCODE_DIR/Sources/App"
cat > "$XCODE_DIR/Sources/App/Info.plist" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>\$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>\$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>\$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>\$(MARKETING_VERSION)</string>
    <key>CFBundleVersion</key>
    <string>\$(CURRENT_PROJECT_VERSION)</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
</dict>
</plist>
EOL

# Generate project using xcodegen
echo "🔨 Generating Xcode project..."
cd "$XCODE_DIR"
if ! command -v xcodegen &> /dev/null; then
    echo -e "${RED}Error: xcodegen not found. Please install it with:${NC}"
    echo "brew install xcodegen"
    exit 1
fi

if xcodegen generate; then
    echo -e "${GREEN}✅ Successfully generated Xcode project${NC}"
    
    # Create helper script
    cat > "open_project.sh" << EOL
#!/bin/bash
open YeelightControl.xcodeproj
EOL
    chmod +x "open_project.sh"
    
    echo ""
    echo "🎉 Project setup complete!"
    echo ""
    echo "To open the project:"
    echo "  cd $XCODE_DIR"
    echo "  ./open_project.sh"
else
    echo -e "${RED}❌ Failed to generate Xcode project${NC}"
    exit 1
fi 