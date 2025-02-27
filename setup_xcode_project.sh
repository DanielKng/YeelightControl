#!/bin/bash
#

# YeelightControl Xcode Project Generator
# This script creates a proper Xcode project from the source files in the Sources directory

# Set up directories
PROJECT_NAME="YeelightControl"
WORKSPACE_ROOT="$(pwd)"
SOURCE_DIR="$WORKSPACE_ROOT/Sources"
XCODE_DIR="$WORKSPACE_ROOT/Xcode"
TEMP_DIR="$WORKSPACE_ROOT/temp_build"

echo "🚀 Setting up Xcode project for $PROJECT_NAME..."

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Error: Source directory not found at $SOURCE_DIR"
    exit 1
fi

# Clean up any existing Xcode directory
if [ -d "$XCODE_DIR" ]; then
    echo "🧹 Cleaning up existing Xcode directory..."
    rm -rf "$XCODE_DIR"
fi

# Create Xcode directory
mkdir -p "$XCODE_DIR"
mkdir -p "$XCODE_DIR/$PROJECT_NAME"

# Create temporary build directory
mkdir -p "$TEMP_DIR"

# Step 1: Create a basic SwiftUI app project using Swift Package Manager
echo "📦 Creating Swift package structure..."
cd "$TEMP_DIR"

# Create Package.swift
cat > Package.swift << EOL
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "$PROJECT_NAME",
    platforms: [.iOS(.v15)],
    products: [
        .executable(name: "$PROJECT_NAME", targets: ["$PROJECT_NAME"]),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "$PROJECT_NAME",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "${PROJECT_NAME}Tests",
            dependencies: ["$PROJECT_NAME"],
            path: "Tests"
        ),
    ]
)
EOL

# Create basic app structure for SPM
mkdir -p Sources
touch Sources/main.swift
echo 'print("Hello, YeelightControl!")' > Sources/main.swift

# Step 2: Generate Xcode project from the package
echo "🛠 Generating Xcode project from package..."
swift package generate-xcodeproj

# Step 3: Copy the generated project to the Xcode directory
echo "📋 Copying generated project..."
cp -R "$PROJECT_NAME.xcodeproj" "$XCODE_DIR/"

# Step 4: Create proper app structure in Xcode directory
echo "📁 Creating app structure..."
mkdir -p "$XCODE_DIR/$PROJECT_NAME/Sources"

# Step 5: Copy source files
echo "📂 Copying source files..."
rsync -av --exclude='.DS_Store' --exclude='.git' "$SOURCE_DIR/" "$XCODE_DIR/$PROJECT_NAME/Sources/"

# Count files copied for verification
SOURCE_FILE_COUNT=$(find "$SOURCE_DIR" -type f | grep -v ".DS_Store" | grep -v ".git" | wc -l | xargs)
DEST_FILE_COUNT=$(find "$XCODE_DIR/$PROJECT_NAME/Sources" -type f | wc -l | xargs)
echo "📊 Files in source: $SOURCE_FILE_COUNT"
echo "📊 Files copied to destination: $DEST_FILE_COUNT"

# Step 6: Create Info.plist
echo "📝 Creating Info.plist..."
cat > "$XCODE_DIR/$PROJECT_NAME/Info.plist" << EOL
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
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>NSLocalNetworkUsageDescription</key>
    <string>YeelightControl needs access to your local network to discover and control Yeelight devices</string>
    <key>NSBonjourServices</key>
    <array>
        <string>_yeelight._tcp</string>
    </array>
    <key>NSMicrophoneUsageDescription</key>
    <string>YeelightControl needs microphone access for music sync features</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>YeelightControl uses your location for automation features</string>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
        <key>UISceneConfigurations</key>
        <dict>
            <key>UIWindowSceneSessionRoleApplication</key>
            <array>
                <dict>
                    <key>UISceneConfigurationName</key>
                    <string>Default Configuration</string>
                    <key>UISceneDelegateClassName</key>
                    <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
                </dict>
            </array>
        </dict>
    </dict>
</dict>
</plist>
EOL

# Step 7: Create LaunchScreen.storyboard
echo "📱 Creating LaunchScreen.storyboard..."
mkdir -p "$XCODE_DIR/$PROJECT_NAME/Resources"
cat > "$XCODE_DIR/$PROJECT_NAME/Resources/LaunchScreen.storyboard" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="21507" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
    <device id="retina6_12" orientation="portrait" appearance="light"/>
    <dependencies>
        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="21505"/>
        <capability name="Safe area layout guides" minToolsVersion="9.0"/>
        <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
    </dependencies>
    <scenes>
        <scene sceneID="EHf-IW-A2E">
            <objects>
                <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                        <rect key="frame" x="0.0" y="0.0" width="393" height="852"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <viewLayoutGuide key="safeArea" id="6Tk-OE-BBY"/>
                        <color key="backgroundColor" white="1" alpha="1" colorSpace="custom" customColorSpace="genericGamma22GrayColorSpace"/>
                    </view>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="53" y="375"/>
        </scene>
    </scenes>
</document>
EOL

# Step 8: Create workspace
echo "🏗 Creating Xcode workspace..."
mkdir -p "$XCODE_DIR/$PROJECT_NAME.xcworkspace/xcshareddata"
cat > "$XCODE_DIR/$PROJECT_NAME.xcworkspace/contents.xcworkspacedata" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "group:$PROJECT_NAME.xcodeproj">
   </FileRef>
</Workspace>
EOL

cat > "$XCODE_DIR/$PROJECT_NAME.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>IDEDidComputeMac32BitWarning</key>
    <true/>
</dict>
</plist>
EOL

# Step 9: Create a script to open the project in Xcode
echo "📜 Creating helper script to open project..."
cat > "$XCODE_DIR/open_project.sh" << EOL
#!/bin/bash
open "$PROJECT_NAME.xcworkspace"
EOL
chmod +x "$XCODE_DIR/open_project.sh"

# Step 10: Clean up temporary files
echo "🧹 Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

# Step 11: Create a better Xcode project using xcodegen if available
if command -v xcodegen &> /dev/null; then
    echo "🔧 xcodegen found, creating optimized project..."
    
    # Create project.yml for xcodegen
    cat > "$XCODE_DIR/project.yml" << EOL
name: $PROJECT_NAME
options:
  bundleIdPrefix: com.danielkng
  deploymentTarget:
    iOS: 15.0
targets:
  $PROJECT_NAME:
    type: application
    platform: iOS
    sources:
      - path: $PROJECT_NAME/Sources
    info:
      path: $PROJECT_NAME/Info.plist
      properties:
        CFBundleDisplayName: YeelightControl
        UILaunchStoryboardName: LaunchScreen
        NSLocalNetworkUsageDescription: YeelightControl needs access to your local network to discover and control Yeelight devices
        NSBonjourServices:
          - _yeelight._tcp
        NSMicrophoneUsageDescription: YeelightControl needs microphone access for music sync features
        NSLocationWhenInUseUsageDescription: YeelightControl uses your location for automation features
    settings:
      base:
        TARGETED_DEVICE_FAMILY: 1,2
        DEVELOPMENT_TEAM: ""
    entitlements:
      path: $PROJECT_NAME/YeelightControl.entitlements
      properties:
        com.apple.security.app-sandbox: true
        com.apple.security.network.client: true
EOL

    # Create entitlements file
    cat > "$XCODE_DIR/$PROJECT_NAME/YeelightControl.entitlements" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
EOL

    # Run xcodegen
    cd "$XCODE_DIR"
    xcodegen generate
    
    echo "✅ Created optimized Xcode project with xcodegen"
else
    echo "⚠️ xcodegen not found. Using basic project structure."
    echo "💡 For a better project structure, install xcodegen: brew install xcodegen"
fi

# Verify app entry point files exist
echo "🔍 Verifying app entry point files..."
if [ -f "$XCODE_DIR/$PROJECT_NAME/Sources/App/YeelightApp.swift" ]; then
    echo "✅ Found YeelightApp.swift (main app entry point)"
else
    echo "⚠️ Warning: YeelightApp.swift not found in expected location"
fi

if [ -f "$XCODE_DIR/$PROJECT_NAME/Sources/App/ContentView.swift" ]; then
    echo "✅ Found ContentView.swift"
else
    echo "⚠️ Warning: ContentView.swift not found in expected location"
fi

if [ -f "$XCODE_DIR/$PROJECT_NAME/Sources/UI/Views/MainView.swift" ]; then
    echo "✅ Found MainView.swift"
else
    echo "⚠️ Warning: MainView.swift not found in expected location"
fi

echo ""
echo "✅ Xcode project setup complete!"
echo ""
echo "To open the project in Xcode:"
echo "  cd $XCODE_DIR"
echo "  ./open_project.sh"
echo ""
echo "If you encounter any issues with the generated project, try:"
echo "  1. Opening the project manually: open $XCODE_DIR/$PROJECT_NAME.xcworkspace"
echo "  2. Creating a new project in Xcode and manually adding the source files"
echo ""
echo "Note: Original source files in /Sources remain unchanged. You can continue working in /Sources"
echo "and run this script again to update the Xcode project when needed." 