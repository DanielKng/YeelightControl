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

# Create build directory if it doesn't exist
mkdir -p "$BUILD_DIR"
mkdir -p "$CONFIGS_DIR"

# Clean up previous build files
if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"/*
fi

# Create necessary directories
echo "📁 Creating directory structure..."
mkdir -p "$SOURCES_DIR/App"
mkdir -p "$SOURCES_DIR/Widget"
mkdir -p "$SOURCES_DIR/Models"
mkdir -p "$SOURCES_DIR/Views"
mkdir -p "$SOURCES_DIR/Controllers"
mkdir -p "$SOURCES_DIR/Utils"
mkdir -p "$SOURCES_DIR/Extensions"
mkdir -p "$SOURCES_DIR/Services"
mkdir -p "Tests/YeelightControlTests"

# Create basic app structure
echo "📱 Creating basic app structure..."
cat > "$SOURCES_DIR/App/YeelightControlApp.swift" << 'EOL'
import SwiftUI

@main
struct YeelightControlApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
EOL

cat > "$SOURCES_DIR/App/ContentView.swift" << 'EOL'
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            Text("Welcome to YeelightControl")
                .navigationTitle("YeelightControl")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
EOL

# Create basic widget structure
echo "🔧 Creating widget structure..."
cat > "$SOURCES_DIR/Widget/YeelightWidget.swift" << 'EOL'
import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entries = [SimpleEntry(date: Date())]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct YeelightWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Text("YeelightControl Widget")
    }
}

@main
struct YeelightWidget: Widget {
    let kind: String = "YeelightWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            YeelightWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Yeelight Control")
        .description("Control your Yeelight devices")
        .supportedFamilies([.systemSmall])
    }
}
EOL

# Create Info.plist files
echo "📄 Creating Info.plist files..."
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
    <key>NSMicrophoneUsageDescription</key>
    <string>YeelightControl needs microphone access for music visualization features.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>YeelightControl uses your location for automation features.</string>
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

# Create test file
echo "📝 Creating test file..."
cat > "Tests/YeelightControlTests/YeelightControlTests.swift" << 'EOL'
import XCTest
@testable import YeelightControl

final class YeelightControlTests: XCTestCase {
    func testExample() throws {
        // This is an example test case
        XCTAssertTrue(true)
    }
}
EOL

# Copy and process project.yml template
echo "📝 Setting up XcodeGen configuration..."
cp "$CONFIGS_DIR/project.yml.template" "$CONFIGS_DIR/project.yml"

# Run XcodeGen
echo "🛠 Running XcodeGen..."
xcodegen generate --spec "$CONFIGS_DIR/project.yml" --project "$BUILD_DIR"

echo "✅ Setup complete!"

# Try to open the Xcode project
if [ -d "YeelightControl.xcodeproj" ]; then
    echo "Opening Xcode project..."
    open YeelightControl.xcodeproj
else
    echo "Error: Xcode project not found"
    exit 1
fi 