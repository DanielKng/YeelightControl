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

# Create Resources directory if it doesn't exist
if [ ! -d "$WORKSPACE_ROOT/Resources" ]; then
    mkdir -p "$WORKSPACE_ROOT/Resources"
    mkdir -p "$WORKSPACE_ROOT/Resources/Screenshots"
    echo "📁 Created Resources directory"
fi

# Method 1: Create a new Xcode project using Xcode's command line tools
echo "📝 Creating new Xcode project..."

# Create a new Xcode project using Swift UI template
mkdir -p "$XCODE_DIR/$PROJECT_NAME"

# Create Info.plist
echo "📄 Creating Info.plist..."
cat > "$XCODE_DIR/$PROJECT_NAME/Info.plist" << EOL
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
    </dict>
</dict>
</plist>
EOL

# Create LaunchScreen.storyboard
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

# Create entitlements file
echo "🔐 Creating entitlements file..."
cat > "$XCODE_DIR/$PROJECT_NAME/$PROJECT_NAME.entitlements" << EOL
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

# Create a Swift Package for the project
echo "📦 Creating Swift package..."
cat > "$XCODE_DIR/Package.swift" << EOL
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "$PROJECT_NAME",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "$PROJECT_NAME", targets: ["$PROJECT_NAME"]),
    ],
    targets: [
        .target(
            name: "$PROJECT_NAME",
            path: "$PROJECT_NAME"
        )
    ]
)
EOL

# Copy source files
echo "📂 Copying source files..."
mkdir -p "$XCODE_DIR/$PROJECT_NAME"
rsync -av --exclude='.DS_Store' --exclude='.git' "$SOURCE_DIR/" "$XCODE_DIR/$PROJECT_NAME/"

# Count files copied for verification
SOURCE_FILE_COUNT=$(find "$SOURCE_DIR" -type f -name "*.swift" | wc -l | xargs)
DEST_FILE_COUNT=$(find "$XCODE_DIR/$PROJECT_NAME" -type f -name "*.swift" | wc -l | xargs)
echo "📊 Swift files in source: $SOURCE_FILE_COUNT"
echo "📊 Swift files copied to destination: $DEST_FILE_COUNT"

# Check if tuist is installed (preferred method)
if command -v tuist &> /dev/null; then
    echo "🔧 Using tuist to generate Xcode project..."
    
    # Create Project.swift for tuist
    mkdir -p "$XCODE_DIR/Project"
    cat > "$XCODE_DIR/Project/Project.swift" << EOL
import ProjectDescription

let project = Project(
    name: "$PROJECT_NAME",
    organizationName: "Daniel Kng",
    options: .options(
        automaticSchemesOptions: .disabled,
        disableBundleAccessors: false,
        disableSynthesizedResourceAccessors: false
    ),
    packages: [],
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "",
            "PRODUCT_BUNDLE_IDENTIFIER": "com.danielkng.$PROJECT_NAME",
            "MARKETING_VERSION": "1.0.0",
            "CURRENT_PROJECT_VERSION": "1",
            "SWIFT_VERSION": "5.5",
            "IPHONEOS_DEPLOYMENT_TARGET": "15.0"
        ],
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release")
        ]
    ),
    targets: [
        Target(
            name: "$PROJECT_NAME",
            platform: .iOS,
            product: .app,
            bundleId: "com.danielkng.$PROJECT_NAME",
            infoPlist: .file(path: "$PROJECT_NAME/Info.plist"),
            sources: ["$PROJECT_NAME/**/*.swift"],
            resources: [
                "$PROJECT_NAME/Resources/**"
            ],
            entitlements: .file(path: "$PROJECT_NAME/$PROJECT_NAME.entitlements")
        )
    ],
    schemes: [
        Scheme(
            name: "$PROJECT_NAME",
            shared: true,
            buildAction: .buildAction(targets: ["$PROJECT_NAME"]),
            testAction: .targets([]),
            runAction: .runAction(configuration: .debug),
            archiveAction: .archiveAction(configuration: .release),
            profileAction: .profileAction(configuration: .release),
            analyzeAction: .analyzeAction(configuration: .debug)
        )
    ]
)
EOL

    # Generate project with tuist
    cd "$XCODE_DIR"
    tuist generate
    
    echo "✅ Created Xcode project with tuist"
    
# Check if xcodegen is installed (alternative method)
elif command -v xcodegen &> /dev/null; then
    echo "🔧 Using xcodegen to generate Xcode project..."
    
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
      - path: $PROJECT_NAME
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
        SWIFT_VERSION: 5.5
    entitlements:
      path: $PROJECT_NAME/$PROJECT_NAME.entitlements
EOL

    # Run xcodegen
    cd "$XCODE_DIR"
    xcodegen generate
    
    echo "✅ Created Xcode project with xcodegen"
    
else
    echo "⚠️ Neither tuist nor xcodegen found. Using manual project creation method..."
    
    # Create a basic project structure that can be opened in Xcode
    # This is a fallback method that will require manual configuration in Xcode
    
    # Create a basic xcodeproj structure
    mkdir -p "$XCODE_DIR/$PROJECT_NAME.xcodeproj"
    
    # Create project.pbxproj file (minimal version)
    cat > "$XCODE_DIR/$PROJECT_NAME.xcodeproj/project.pbxproj" << EOL
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 55;
	objects = {
		LastUpgradeCheck = 1320;
		ORGANIZATIONNAME = "Daniel Kng";
		TargetAttributes = {
			IPHONEOS_DEPLOYMENT_TARGET = 15.0;
		};
	};
	rootObject = 1D6058900D05DD3D006BFB54 /* Project object */;
}
EOL
    
    echo "⚠️ Created minimal Xcode project structure."
    echo "⚠️ You will need to manually configure the project in Xcode:"
    echo "  1. Open Xcode and create a new iOS App project named $PROJECT_NAME"
    echo "  2. Close the project and replace the generated files with your source files"
    echo "  3. Reopen the project and configure as needed"
fi

# Create a script to open the project in Xcode
echo "📜 Creating helper script to open project..."
cat > "$XCODE_DIR/open_project.sh" << EOL
#!/bin/bash
if [ -d "$PROJECT_NAME.xcworkspace" ]; then
    open "$PROJECT_NAME.xcworkspace"
elif [ -d "$PROJECT_NAME.xcodeproj" ]; then
    open "$PROJECT_NAME.xcodeproj"
else
    echo "No Xcode project or workspace found."
fi
EOL
chmod +x "$XCODE_DIR/open_project.sh"

# Verify app entry point files exist
echo "🔍 Verifying app entry point files..."
if [ -f "$XCODE_DIR/$PROJECT_NAME/App/YeelightApp.swift" ]; then
    echo "✅ Found YeelightApp.swift (main app entry point)"
else
    echo "⚠️ Warning: YeelightApp.swift not found in expected location"
fi

if [ -f "$XCODE_DIR/$PROJECT_NAME/App/ContentView.swift" ]; then
    echo "✅ Found ContentView.swift"
else
    echo "⚠️ Warning: ContentView.swift not found in expected location"
fi

if [ -f "$XCODE_DIR/$PROJECT_NAME/UI/Views/MainView.swift" ]; then
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
echo "If you encounter issues with the generated project:"
echo ""
echo "Option 1: Install project generation tools (recommended)"
echo "  brew install xcodegen    # or"
echo "  brew install tuist"
echo "  Then run this script again"
echo ""
echo "Option 2: Create a new project manually in Xcode"
echo "  1. Create a new iOS App project with SwiftUI interface"
echo "  2. Add your source files from the Sources directory"
echo "  3. Configure the Info.plist with required permissions"
echo ""
echo "Note: Original source files in /Sources remain unchanged." 