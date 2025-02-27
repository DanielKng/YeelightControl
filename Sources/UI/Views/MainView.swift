import SwiftUI

/// Main tab-based navigation view for the application
/// Provides access to all major features through a tab interface
struct MainView: View {
    // MARK: - Properties
    
    /// Access to the Yeelight device manager
    @EnvironmentObject private var yeelightManager: YeelightManager
    
    /// Currently selected tab index
    @State private var selectedTab = 0
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: Lights Tab
            NavigationView {
                LightsView()
                    .navigationTitle("My Lights")
                    .navigationBarItems(trailing: refreshButton)
            }
            .tabItem {
                Label("Lights", systemImage: "lightbulb.fill")
            }
            .tag(0)
            
            // MARK: Scenes Tab
            NavigationView {
                ScenesView()
                    .navigationTitle("Scenes")
            }
            .tabItem {
                Label("Scenes", systemImage: "theatermasks.fill")
            }
            .tag(1)
            
            // MARK: Automation Tab
            NavigationView {
                AutomationView()
                    .navigationTitle("Automation")
            }
            .tabItem {
                Label("Automation", systemImage: "timer")
            }
            .tag(2)
            
            // MARK: Effects Tab
            NavigationView {
                EffectsView()
                    .navigationTitle("Effects")
            }
            .tabItem {
                Label("Effects", systemImage: "waveform.path.ecg")
            }
            .tag(3)
            
            // MARK: Settings Tab
            NavigationView {
                SettingsView()
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(4)
        }
        .accentColor(.blue)
        .onAppear {
            // Start device discovery when the main view appears
            yeelightManager.startDiscovery()
            
            // Configure tab bar appearance
            configureTabBarAppearance()
        }
    }
    
    // MARK: - UI Components
    
    /// Button that refreshes device discovery
    private var refreshButton: some View {
        Button(action: {
            yeelightManager.startDiscovery()
        }) {
            Image(systemName: "arrow.clockwise")
                .imageScale(.large)
                .accessibilityLabel("Refresh devices")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Configures the appearance of the tab bar
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = appearance
        
        // iOS 15+ specific appearance settings
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Preview

#Preview {
    MainView()
        .environmentObject(YeelightManager.shared)
} 