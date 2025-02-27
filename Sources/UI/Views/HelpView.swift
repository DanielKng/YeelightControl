import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTopic: HelpTopic?
    @State private var searchText = ""
    
    enum HelpTopic: String, CaseIterable {
        case gettingStarted = "Getting Started"
        case basicControls = "Basic Controls"
        case scenes = "Scenes"
        case advanced = "Advanced"
        
        var icon: String {
            switch self {
            case .gettingStarted: return "star"
            case .basicControls: return "slider.horizontal.3"
            case .scenes: return "theatermasks"
            case .advanced: return "gearshape.2"
            }
        }
        
        var content: [HelpSection] {
            switch self {
            case .gettingStarted:
                return [
                    HelpSection(
                        title: "Welcome to Yeelight Control",
                        content: "Get started with your smart lighting:",
                        steps: [
                            "Connect your Yeelight devices to your WiFi network",
                            "Enable LAN Control in the Yeelight app",
                            "Open this app and discover your devices",
                            "Start controlling your lights"
                        ]
                    ),
                    HelpSection(
                        title: "Device Discovery",
                        content: "Finding your devices:",
                        steps: [
                            "Ensure devices are on the same network",
                            "Tap 'Search for Devices' in the main view",
                            "Wait for devices to appear",
                            "Tap a device to start controlling"
                        ]
                    )
                ]
            case .basicControls:
                return [
                    HelpSection(
                        title: "Light Controls",
                        content: "Basic light operations:",
                        steps: [
                            "Toggle power on/off",
                            "Adjust brightness",
                            "Change color temperature",
                            "Select RGB colors"
                        ]
                    ),
                    HelpSection(
                        title: "Device Management",
                        content: "Managing your devices:",
                        steps: [
                            "Rename devices",
                            "Group devices together",
                            "Remove devices",
                            "Update device settings"
                        ]
                    )
                ]
            case .scenes:
                return [
                    HelpSection(
                        title: "Scene Creation",
                        content: "Create custom scenes:",
                        steps: [
                            "Choose scene type",
                            "Select devices",
                            "Configure settings",
                            "Save and apply scenes"
                        ]
                    ),
                    HelpSection(
                        title: "Scene Management",
                        content: "Managing your scenes:",
                        steps: [
                            "Edit existing scenes",
                            "Schedule scenes",
                            "Delete scenes",
                            "Share scenes"
                        ]
                    )
                ]
            case .advanced:
                return [
                    HelpSection(
                        title: "Advanced Features",
                        content: "Explore advanced capabilities:",
                        steps: [
                            "Custom flow effects",
                            "Music synchronization",
                            "Device grouping and coordination",
                            "Power-on behavior configuration"
                        ]
                    ),
                    HelpSection(
                        title: "Developer Options",
                        content: "For advanced users:",
                        steps: [
                            "Access debug logs",
                            "Configure network settings",
                            "Export device data",
                            "Custom command interface"
                        ]
                    )
                ]
            }
        }
    }
    
    struct HelpSection: Identifiable {
        let id = UUID()
        let title: String
        let content: String
        let steps: [String]
    }
    
    var body: some View {
        NavigationSplitView {
            UnifiedListView(
                title: "Help Topics",
                items: HelpTopic.allCases,
                emptyStateMessage: ""
            ) { topic in
                Label(topic.rawValue, systemImage: topic.icon)
                    .tag(topic)
                    .foregroundColor(topic == selectedTopic ? .accentColor : .primary)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTopic = topic
                    }
            }
            .searchable(text: $searchText, prompt: "Search help topics")
        } detail: {
            if let topic = selectedTopic {
                UnifiedDetailView(
                    title: topic.rawValue,
                    mainContent: {
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(topic.content) { section in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(section.title)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    
                                    Text(section.content)
                                        .font(.body)
                                    
                                    UnifiedListView(
                                        items: section.steps,
                                        emptyStateMessage: ""
                                    ) { step in
                                        HStack(alignment: .top) {
                                            Image(systemName: "circle.fill")
                                                .font(.system(size: 6))
                                                .padding(.top, 8)
                                            Text(step)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                
                                if section.id != topic.content.last?.id {
                                    Divider()
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                )
            } else {
                ContentUnavailableView(
                    "Select a Topic",
                    systemImage: "book",
                    description: Text("Choose a help topic from the sidebar")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") { dismiss() }
            }
        }
    }
}

#Preview {
    HelpView()
} 