import SwiftUI
import Combine
import Network
import Core

/// Main tab-based navigation view for the application
/// Provides access to all major features through a tab interface
struct MainView: View {
// MARK: - Environment Objects

@EnvironmentObject private var uiEnvironment: UIEnvironment
@EnvironmentObject private var yeelightManager: ObservableYeelightManager
@EnvironmentObject private var deviceManager: ObservableDeviceManager
@EnvironmentObject private var sceneManager: ObservableSceneManager
@EnvironmentObject private var effectManager: ObservableEffectManager
@EnvironmentObject private var networkManager: ObservableNetworkManager
@EnvironmentObject private var themeManager: ObservableThemeManager

// MARK: - State

@State private var selectedTab = Tab.lights
@State private var isOffline = false
@State private var showingErrorAlert = false
@State private var alertMessage: String?

// MARK: - Types

enum Tab {
case lights
case scenes
case settings

var title: String {
switch self {
case .lights: return "Lights"
case .scenes: return "Scenes"
case .settings: return "Settings"
}
}

var icon: String {
switch self {
case .lights: return "lightbulb.fill"
case .scenes: return "theatermasks.fill"
case .settings: return "gear"
}
}
}

// MARK: - Body

var body: some View {
TabView(selection: $selectedTab) {
NavigationStack {
LightsView()
}
.tabItem {
Label(Tab.lights.title, systemImage: Tab.lights.icon)
}
.tag(Tab.lights)

NavigationStack {
Text("Scenes Coming Soon")
.font(.title)
.foregroundColor(.secondary)
}
.tabItem {
Label(Tab.scenes.title, systemImage: Tab.scenes.icon)
}
.tag(Tab.scenes)

NavigationStack {
SettingsView()
}
.tabItem {
Label(Tab.settings.title, systemImage: Tab.settings.icon)
}
.tag(Tab.settings)
}
.alert("Error", isPresented: $showingErrorAlert) {
Button("OK", role: .cancel) {
uiEnvironment.clearError()
}
} message: {
Text(alertMessage ?? "An error occurred.")
}
.onChange(of: uiEnvironment.errorMessage) { newValue in
if let errorMessage = newValue {
alertMessage = errorMessage
showingErrorAlert = true
}
}
.onChange(of: networkManager.isConnected) { isConnected in
isOffline = !isConnected
}
.alert("Network Unavailable", isPresented: $isOffline) {
Button("OK", role: .cancel) { }
} message: {
Text("Please check your network connection.")
}
}
}

// MARK: - Settings View

struct SettingsView: View {
@EnvironmentObject private var yeelightManager: ObservableYeelightManager
@EnvironmentObject private var deviceManager: ObservableDeviceManager
@EnvironmentObject private var networkManager: ObservableNetworkManager

@State private var showingAbout = false

var body: some View {
List {
Section(header: Text("App")) {
NavigationLink(destination: Text("Theme Settings")) {
Label("Appearance", systemImage: "paintbrush")
}

NavigationLink(destination: Text("Network Settings")) {
Label("Network", systemImage: "network")
}

NavigationLink(destination: Text("Notifications Settings")) {
Label("Notifications", systemImage: "bell")
}
}

Section(header: Text("Devices")) {
NavigationLink(destination: DeviceDiscoveryView()) {
Label("Add Device", systemImage: "plus.circle")
}

NavigationLink(destination: Text("Device Management")) {
Label("Manage Devices", systemImage: "lightbulb")
}
}

Section(header: Text("About")) {
Button(action: { showingAbout = true }) {
Label("About YeelightControl", systemImage: "info.circle")
}
}
}
.navigationTitle("Settings")
.sheet(isPresented: $showingAbout) {
AboutView()
}
}

// MARK: - About View

struct AboutView: View {
@Environment(\.dismiss) private var dismiss

var body: some View {
NavigationView {
List {
Section {
HStack {
Spacer()
VStack(spacing: 10) {
Image(systemName: "lightbulb.fill")
.font(.system(size: 60))
.foregroundColor(.accentColor)

Text("YeelightControl")
.font(.title)
.fontWeight(.bold)

Text("Version 1.0.0")
.font(.subheadline)
.foregroundColor(.secondary)
}
Spacer()
}
.padding()
}

Section(header: Text("About")) {
Text("YeelightControl is an app for controlling Yeelight smart lighting devices. It allows you to discover, connect to, and control your Yeelight bulbs, strips, and other lighting products.")
.font(.body)
.padding(.vertical, 8)
}

Section(header: Text("Support")) {
Link(destination: URL(string: "https://example.com/support")!) {
Label("Get Help", systemImage: "questionmark.circle")
}

Link(destination: URL(string: "https://example.com/privacy")!) {
Label("Privacy Policy", systemImage: "hand.raised")
}

Link(destination: URL(string: "https://example.com/terms")!) {
Label("Terms of Service", systemImage: "doc.text")
}
}

Section(header: Text("Credits")) {
Text("Created by Your Name")
Text("© 2023 Your Company")
}
}
.navigationTitle("About")
.navigationBarTitleDisplayMode(.inline)
.toolbar {
ToolbarItem(placement: .navigationBarTrailing) {
Button("Done") {
dismiss()
}
}
}
}
}

// MARK: - Preview

struct MainView_Previews: PreviewProvider {
static var previews: some View {
let container = UnifiedServiceContainer.shared

// Initialize the service container
let storageManager = UnifiedStorageManager()
let networkManager = UnifiedNetworkManager()
let yeelightManager = UnifiedYeelightManager(
storageManager: storageManager,
networkManager: networkManager
)
let deviceManager = UnifiedDeviceManager()
let sceneManager = UnifiedSceneManager()
let effectManager = UnifiedEffectManager()

// Create the UI environment
let environment = UIEnvironment(container: container)

return MainView()
.environmentObject(environment)
.environmentObject(ObservableYeelightManager(manager: yeelightManager))
.environmentObject(ObservableDeviceManager(manager: deviceManager))
.environmentObject(ObservableSceneManager(manager: sceneManager))
.environmentObject(ObservableEffectManager(manager: effectManager))
.environmentObject(ObservableNetworkManager(manager: networkManager))
.environmentObject(ObservableThemeManager(manager: UnifiedThemeManager()))
}
} 