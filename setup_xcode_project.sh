#!/bin/bash
#

# Set up directories
PROJECT_NAME="YeelightControl"
WORKSPACE_ROOT="$(pwd)"
SOURCE_DIR="$WORKSPACE_ROOT/Sources"
XCODE_DIR="$WORKSPACE_ROOT/Xcode"

echo "Setting up Xcode project structure for $PROJECT_NAME..."

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Error: Source directory not found at $SOURCE_DIR"
    exit 1
fi

# Create Xcode directory structure
echo "Creating Xcode project structure..."
mkdir -p "$XCODE_DIR"
mkdir -p "$XCODE_DIR/$PROJECT_NAME"
mkdir -p "$XCODE_DIR/$PROJECT_NAME/Resources"
mkdir -p "$XCODE_DIR/$PROJECT_NAME/Resources/Assets.xcassets"
mkdir -p "$XCODE_DIR/$PROJECT_NAME/Resources/Assets.xcassets/AppIcon.appiconset"

# Safely copy source files
echo "Copying source files (preserving original files)..."
# Use rsync to copy files while preserving structure and not touching originals
if ! rsync -arv --exclude='.DS_Store' --exclude='.git' "$SOURCE_DIR/" "$XCODE_DIR/$PROJECT_NAME/Sources/"; then
    echo "❌ Error: Failed to copy source files"
    exit 1
else
    echo "✅ Successfully copied all source files"
    # Count files copied for verification
    SOURCE_FILE_COUNT=$(find "$SOURCE_DIR" -type f | grep -v ".DS_Store" | grep -v ".git" | wc -l | xargs)
    DEST_FILE_COUNT=$(find "$XCODE_DIR/$PROJECT_NAME/Sources" -type f | wc -l | xargs)
    echo "Files in source: $SOURCE_FILE_COUNT"
    echo "Files copied to destination: $DEST_FILE_COUNT"
    
    if [ "$SOURCE_FILE_COUNT" -ne "$DEST_FILE_COUNT" ]; then
        echo "⚠️ Warning: File count mismatch. Some files may not have been copied."
        echo "This could be due to excluded files (.DS_Store, .git) or other issues."
    fi
fi

# Create Info.plist
echo "Creating Info.plist..."
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

# Create LaunchScreen.storyboard
echo "Creating LaunchScreen.storyboard..."
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

# Create Contents.json for AppIcon
echo "Creating AppIcon structure..."
cat > "$XCODE_DIR/$PROJECT_NAME/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json" << EOL
{
  "images" : [
    {
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOL

# Create project.pbxproj (basic structure)
echo "Creating Xcode project file..."
mkdir -p "$XCODE_DIR/$PROJECT_NAME.xcodeproj"
cat > "$XCODE_DIR/$PROJECT_NAME.xcodeproj/project.pbxproj" << EOL
// !$*UTF8*$!
{
    archiveVersion = 1;
    classes = {
    };
    objectVersion = 56;
    objects = {
        /* Begin PBXBuildFile section */
        /* End PBXBuildFile section */
        
        /* Begin PBXFileReference section */
        /* End PBXFileReference section */
        
        /* Begin PBXFrameworksBuildPhase section */
        /* End PBXFrameworksBuildPhase section */
        
        /* Begin PBXGroup section */
        /* End PBXGroup section */
        
        /* Begin PBXNativeTarget section */
        /* End PBXNativeTarget section */
        
        /* Begin PBXProject section */
        /* End PBXProject section */
        
        /* Begin PBXResourcesBuildPhase section */
        /* End PBXResourcesBuildPhase section */
        
        /* Begin PBXSourcesBuildPhase section */
        /* End PBXSourcesBuildPhase section */
        
        /* Begin XCBuildConfiguration section */
        /* End XCBuildConfiguration section */
        
        /* Begin XCConfigurationList section */
        /* End XCConfigurationList section */
    };
    rootObject = 1234567890ABCDEF0123456789ABCDEF /* Project object */;
}
EOL

# Create workspace
echo "Creating Xcode workspace..."
mkdir -p "$XCODE_DIR/$PROJECT_NAME.xcworkspace"
cat > "$XCODE_DIR/$PROJECT_NAME.xcworkspace/contents.xcworkspacedata" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "group:$PROJECT_NAME.xcodeproj">
   </FileRef>
</Workspace>
EOL

# Create .gitignore for Xcode directory
echo "Creating .gitignore for Xcode directory..."
cat > "$XCODE_DIR/.gitignore" << EOL
# Xcode
.DS_Store
*/build/*
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
xcuserdata
*.xccheckout
*.moved-aside
DerivedData
.idea/
*.hmap
*.xcuserstate
EOL

# Verify app entry point files exist
echo "Verifying app entry point files..."
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

echo "✅ Xcode project structure created successfully!"
echo "Source files have been copied to Xcode directory while preserving originals in /Sources"
echo ""
echo "Next steps:"
echo "1. Open the project in Xcode: open $XCODE_DIR/$PROJECT_NAME.xcworkspace"
echo "2. Add your app icon to Assets.xcassets"
echo "3. Configure signing and capabilities in Xcode"
echo "4. Build and run the project"
echo ""
echo "Note: Original source files in /Sources remain unchanged. You can continue working in /Sources"
echo "and run this script again to update the Xcode project when needed." 