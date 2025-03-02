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
                    .navigationTitle("Lights")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                yeelightManager.startDiscovery()
                            }) {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                    }
            }
            .tabItem {
                Label(Tab.lights.title, systemImage: Tab.lights.icon)
            }
            .tag(Tab.lights)
            
            NavigationStack {
                SceneListView()
                    .navigationTitle("Scenes")
            }
            .tabItem {
                Label(Tab.scenes.title, systemImage: Tab.scenes.icon)
            }
            .tag(Tab.scenes)
            
            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label(Tab.settings.title, systemImage: Tab.settings.icon)
            }
            .tag(Tab.settings)
        }
        .alert(isPresented: $showingErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onReceive(networkManager.$isConnected) { isConnected in
            isOffline = !isConnected
        }
    }
    
    // MARK: - Preview
    
    struct MainView_Previews: PreviewProvider {
        static var previews: some View {
            let container = ServiceContainer()
            
            return MainView()
                .environmentObject(UIEnvironment())
                .environmentObject(ObservableYeelightManager(manager: UnifiedYeelightManager()))
                .environmentObject(ObservableDeviceManager(manager: UnifiedDeviceManager()))
                .environmentObject(ObservableSceneManager(manager: UnifiedSceneManager()))
                .environmentObject(ObservableEffectManager(manager: UnifiedEffectManager()))
                .environmentObject(ObservableNetworkManager(manager: UnifiedNetworkManager()))
                .environmentObject(ObservableThemeManager(manager: UnifiedThemeManager()))
        }
    }
}

// Remove SettingsView and other views from this file as they are defined elsewhere 