import SwiftUI

struct HelpView: View {
    @State private var selectedTopic: HelpTopic?
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Getting Started")) {
                    ForEach(HelpTopic.gettingStarted) { topic in
                        NavigationLink(value: topic) {
                            Label(topic.title, systemImage: topic.icon)
                        }
                    }
                }
                
                Section(header: Text("Features")) {
                    ForEach(HelpTopic.features) { topic in
                        NavigationLink(value: topic) {
                            Label(topic.title, systemImage: topic.icon)
                        }
                    }
                }
                
                Section(header: Text("Troubleshooting")) {
                    ForEach(HelpTopic.troubleshooting) { topic in
                        NavigationLink(value: topic) {
                            Label(topic.title, systemImage: topic.icon)
                        }
                    }
                }
                
                Section(header: Text("Contact & Support")) {
                    Link(destination: URL(string: "https://github.com/yourusername/YeelightControl/issues")!) {
                        Label("Report an Issue", systemImage: "exclamationmark.bubble")
                    }
                    
                    Link(destination: URL(string: "mailto:support@example.com")!) {
                        Label("Email Support", systemImage: "envelope")
                    }
                }
            }
            .navigationTitle("Help & Support")
            .navigationDestination(for: HelpTopic.self) { topic in
                HelpTopicView(topic: topic)
            }
            .searchable(text: $searchText, prompt: "Search help topics")
        }
    }
    
    var filteredTopics: [HelpTopic] {
        if searchText.isEmpty {
            return HelpTopic.allTopics
        } else {
            return HelpTopic.allTopics.filter { topic in
                topic.title.localizedCaseInsensitiveContains(searchText) ||
                topic.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct HelpTopicView: View {
    let topic: HelpTopic
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(topic.title)
                    .font(.largeTitle)
                    .bold()
                
                Divider()
                
                Text(topic.content)
                    .font(.body)
                
                if !topic.relatedTopics.isEmpty {
                    Divider()
                    
                    Text("Related Topics")
                        .font(.headline)
                    
                    ForEach(topic.relatedTopics) { relatedTopic in
                        NavigationLink(value: relatedTopic) {
                            Text(relatedTopic.title)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpTopic: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let icon: String
    let content: String
    let relatedTopics: [HelpTopic]
    
    init(title: String, icon: String, content: String, relatedTopics: [HelpTopic] = []) {
        self.title = title
        self.icon = icon
        self.content = content
        self.relatedTopics = relatedTopics
    }
    
    static func == (lhs: HelpTopic, rhs: HelpTopic) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static var gettingStarted: [HelpTopic] {
        [
            HelpTopic(
                title: "Connecting Your First Device",
                icon: "wifi",
                content: "To connect your first Yeelight device:\n\n1. Ensure your Yeelight device is powered on and connected to your WiFi network.\n\n2. Open the YeelightControl app and navigate to the Devices tab.\n\n3. Tap the + button in the top right corner.\n\n4. Select 'Search for Devices' to automatically discover Yeelight devices on your network.\n\n5. Once your device appears in the list, tap on it to connect.\n\n6. If your device doesn't appear automatically, you can add it manually by selecting 'Add Manually' and entering the device's IP address."
            ),
            HelpTopic(
                title: "Setting Up Groups",
                icon: "folder",
                content: "Groups allow you to control multiple lights simultaneously. To create a group:\n\n1. Go to the Groups tab.\n\n2. Tap the + button.\n\n3. Give your group a name.\n\n4. Select the devices you want to include in the group.\n\n5. Tap 'Save' to create the group.\n\nYou can now control all devices in the group together."
            ),
            HelpTopic(
                title: "Creating Your First Scene",
                icon: "lightbulb",
                content: "Scenes allow you to save specific lighting configurations. To create a scene:\n\n1. Go to the Scenes tab.\n\n2. Tap the + button.\n\n3. Select the devices you want to include in the scene.\n\n4. Adjust the brightness, color, and other settings for each device.\n\n5. Give your scene a name.\n\n6. Tap 'Save' to create the scene.\n\nYou can now activate this scene at any time with a single tap."
            )
        ]
    }
    
    static var features: [HelpTopic] {
        [
            HelpTopic(
                title: "Color Flow Effects",
                icon: "waveform.path.ecg",
                content: "Color Flow allows your lights to transition between colors automatically. To use Color Flow:\n\n1. Select a device or group.\n\n2. Tap the 'Effects' button.\n\n3. Choose 'Color Flow' from the effects menu.\n\n4. Select a preset or create a custom flow by defining colors and transition times.\n\n5. Tap 'Start' to begin the effect."
            ),
            HelpTopic(
                title: "Music Sync",
                icon: "music.note",
                content: "Music Sync allows your lights to react to music playing on your device. To use Music Sync:\n\n1. Select a device or group.\n\n2. Tap the 'Effects' button.\n\n3. Choose 'Music Sync' from the effects menu.\n\n4. Grant microphone permissions if prompted.\n\n5. Adjust sensitivity and color settings as desired.\n\n6. Tap 'Start' to begin syncing your lights to music."
            ),
            HelpTopic(
                title: "Automations",
                icon: "clock",
                content: "Automations allow your lights to respond to specific triggers. To create an automation:\n\n1. Go to the Automations tab.\n\n2. Tap the + button.\n\n3. Select a trigger type (time, sunrise/sunset, device event, etc.).\n\n4. Configure the trigger details.\n\n5. Select the action to perform when the trigger occurs.\n\n6. Optionally, add conditions that must be met for the automation to run.\n\n7. Give your automation a name.\n\n8. Tap 'Save' to activate the automation."
            )
        ]
    }
    
    static var troubleshooting: [HelpTopic] {
        [
            HelpTopic(
                title: "Device Not Found",
                icon: "questionmark.circle",
                content: "If your device isn't being discovered:\n\n1. Ensure the device is powered on and connected to the same WiFi network as your phone.\n\n2. Check that LAN Control is enabled in the Yeelight app.\n\n3. Restart the device by turning it off and on again.\n\n4. Try adding the device manually using its IP address.\n\n5. Check your router settings to ensure multicast discovery is enabled.\n\n6. If all else fails, reset the device according to the manufacturer's instructions and set it up again."
            ),
            HelpTopic(
                title: "Connection Issues",
                icon: "wifi.slash",
                content: "If you're experiencing connection issues:\n\n1. Ensure your device and phone are on the same WiFi network.\n\n2. Check your WiFi signal strength near the device.\n\n3. Restart your WiFi router.\n\n4. Try forgetting the device in the app and rediscovering it.\n\n5. Check if the device firmware needs updating (this can usually be done through the manufacturer's app).\n\n6. If the device has a static IP, ensure it's still valid for your network."
            ),
            HelpTopic(
                title: "App Performance",
                icon: "gear",
                content: "If the app is running slowly or crashing:\n\n1. Ensure you're running the latest version of the app.\n\n2. Restart the app.\n\n3. Restart your device.\n\n4. Check if your device has sufficient storage and memory available.\n\n5. If problems persist, try uninstalling and reinstalling the app (note: this may delete your saved scenes and groups)."
            )
        ]
    }
    
    static var allTopics: [HelpTopic] {
        gettingStarted + features + troubleshooting
    }
}

#Preview {
    HelpView()
} 