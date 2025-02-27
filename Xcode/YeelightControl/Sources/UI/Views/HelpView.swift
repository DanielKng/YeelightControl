import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTopic: HelpTopic?
    @State private var searchText = ""
    
    enum HelpTopic: String, CaseIterable {
        case gettingStarted = "Getting Started"
        case deviceSetup = "Device Setup"
        case scenes = "Scenes"
        case automations = "Automations"
        case troubleshooting = "Troubleshooting"
        case advanced = "Advanced Features"
        
        var icon: String {
            switch self {
            case .gettingStarted: return "star"
            case .deviceSetup: return "plus.circle"
            case .scenes: return "theatermasks"
            case .automations: return "clock"
            case .troubleshooting: return "exclamationmark.triangle"
            case .advanced: return "gear"
            }
        }
        
        var content: [HelpSection] {
            switch self {
            case .gettingStarted:
                return [
                    HelpSection(
                        title: "Welcome to YeelightControl",
                        content: "YeelightControl is a powerful app for managing your Yeelight smart lighting devices. This guide will help you get started with the basic features.",
                        steps: [
                            "Make sure your Yeelight devices are connected to your WiFi network",
                            "Enable LAN Control in the official Yeelight app",
                            "Launch YeelightControl and allow local network access",
                            "Your devices will be discovered automatically"
                        ]
                    ),
                    HelpSection(
                        title: "Basic Controls",
                        content: "Learn how to control your lights:",
                        steps: [
                            "Tap a device to access detailed controls",
                            "Use the power toggle to turn lights on/off",
                            "Adjust brightness with the slider",
                            "Change colors or color temperature"
                        ]
                    )
                ]
            case .deviceSetup:
                return [
                    HelpSection(
                        title: "Adding New Devices",
                        content: "To add a new Yeelight device:",
                        steps: [
                            "Set up the device using the official Yeelight app",
                            "Connect it to your WiFi network",
                            "Enable LAN Control in device settings",
                            "Open YeelightControl and tap 'Discover Devices'"
                        ]
                    ),
                    HelpSection(
                        title: "Device Organization",
                        content: "Keep your devices organized:",
                        steps: [
                            "Create rooms to group devices",
                            "Name your devices for easy identification",
                            "Arrange devices in your preferred order",
                            "Use tags for better organization"
                        ]
                    )
                ]
            case .scenes:
                return [
                    HelpSection(
                        title: "Creating Scenes",
                        content: "Scenes let you save and recall lighting configurations:",
                        steps: [
                            "Choose between basic, preset, or custom scenes",
                            "Select the devices to include",
                            "Configure colors, brightness, and effects",
                            "Save the scene with a memorable name"
                        ]
                    ),
                    HelpSection(
                        title: "Multi-Device Effects",
                        content: "Create coordinated lighting effects:",
                        steps: [
                            "Select multiple devices",
                            "Choose from various effect types",
                            "Customize colors and timing",
                            "Preview and save your creation"
                        ]
                    )
                ]
            case .automations:
                return [
                    HelpSection(
                        title: "Setting Up Automations",
                        content: "Automate your lighting with triggers and actions:",
                        steps: [
                            "Choose a trigger (time, location, etc.)",
                            "Select the devices to control",
                            "Configure the desired action",
                            "Enable/disable as needed"
                        ]
                    ),
                    HelpSection(
                        title: "Trigger Types",
                        content: "Available automation triggers:",
                        steps: [
                            "Time-based triggers",
                            "Sunrise/Sunset triggers",
                            "Location-based triggers",
                            "Device connection triggers"
                        ]
                    )
                ]
            case .troubleshooting:
                return [
                    HelpSection(
                        title: "Common Issues",
                        content: "Solutions for common problems:",
                        steps: [
                            "Ensure devices are powered on and connected to WiFi",
                            "Check that LAN Control is enabled",
                            "Verify network permissions in app settings",
                            "Try restarting problematic devices"
                        ]
                    ),
                    HelpSection(
                        title: "Network Issues",
                        content: "Resolving network-related problems:",
                        steps: [
                            "Confirm devices are on the same network as your phone",
                            "Check WiFi signal strength",
                            "Restart your router if needed",
                            "Use the Network Diagnostics tool"
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
            List(selection: $selectedTopic) {
                ForEach(HelpTopic.allCases, id: \.self) { topic in
                    Label(topic.rawValue, systemImage: topic.icon)
                        .tag(topic)
                }
            }
            .navigationTitle("Help")
            .searchable(text: $searchText, prompt: "Search help topics")
        } detail: {
            if let topic = selectedTopic {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(topic.content) { section in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(section.title)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text(section.content)
                                    .font(.body)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(section.steps, id: \.self) { step in
                                        HStack(alignment: .top) {
                                            Image(systemName: "circle.fill")
                                                .font(.system(size: 6))
                                                .padding(.top, 8)
                                            Text(step)
                                        }
                                    }
                                }
                                .padding(.leading, 4)
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
                .navigationTitle(topic.rawValue)
                .navigationBarTitleDisplayMode(.inline)
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