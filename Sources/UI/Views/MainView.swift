import SwiftUI

/// Main tab-based navigation view for the application
/// Provides access to all major features through a tab interface
struct MainView: View {
    // MARK: - Properties
    
    /// Access to the Yeelight device manager
    @EnvironmentObject private var yeelightManager: YeelightManager
    
    /// Currently selected tab
    @State private var selectedTab = Tab.lights
    
    // MARK: - Types
    
    enum Tab {
        case lights, scenes, automation, effects, settings
        
        var title: String {
            switch self {
            case .lights: return "Lights"
            case .scenes: return "Scenes"
            case .automation: return "Automation"
            case .effects: return "Effects"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .lights: return "lightbulb.fill"
            case .scenes: return "theatermasks.fill"
            case .automation: return "timer"
            case .effects: return "waveform.path.ecg"
            case .settings: return "gear"
            }
        }
        
        var view: some View {
            NavigationView {
                switch self {
                case .lights:
                    LightsView()
                        .navigationTitle("My Lights")
                case .scenes:
                    ScenesView()
                        .navigationTitle("Scenes")
                case .automation:
                    AutomationView()
                        .navigationTitle("Automation")
                case .effects:
                    EffectsView()
                        .navigationTitle("Effects")
                case .settings:
                    SettingsView()
                        .navigationTitle("Settings")
                }
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            selectedTab.view
            
            // Tab bar
            UnifiedTabSelector(
                selection: $selectedTab,
                tabs: [
                    .init("Lights", icon: "lightbulb.fill", tag: Tab.lights),
                    .init("Scenes", icon: "theatermasks.fill", tag: Tab.scenes),
                    .init("Automation", icon: "timer", tag: Tab.automation),
                    .init("Effects", icon: "waveform.path.ecg", tag: Tab.effects),
                    .init("Settings", icon: "gear", tag: Tab.settings)
                ],
                style: .underlined
            )
            .padding(.vertical, 8)
            .background(.bar)
        }
        .onAppear {
            // Start device discovery when the main view appears
            yeelightManager.startDiscovery()
        }
    }
}

// MARK: - Preview

#Preview {
    MainView()
        .environmentObject(YeelightManager.shared)
} 