import SwiftUI
import UniformTypeIdentifiers

struct SharedScene: Codable {
    let name: String
    let icon: String
    let scene: YeelightManager.Scene
    let createdBy: String
    let description: String
    let tags: [String]
    let version: Int = 1
    
    var shareURL: URL? {
        guard let data = try? JSONEncoder().encode(self),
              let base64 = String(data: data, encoding: .utf8)?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else { return nil }
        return URL(string: "yeelight://scene/import/\(base64)")
    }
    
    static func from(url: URL) -> SharedScene? {
        guard url.scheme == "yeelight",
              url.host == "scene",
              url.path.hasPrefix("/import/"),
              let base64 = url.path.replacingOccurrences(of: "/import/", with: "")
                .removingPercentEncoding,
              let data = Data(base64Encoded: base64),
              let scene = try? JSONDecoder().decode(SharedScene.self, from: data)
        else { return nil }
        return scene
    }
}

struct SceneSharingView: View {
    let scene: ScenePreset
    @State private var shareDescription = ""
    @State private var shareTags = ""
    @State private var showingShareSheet = false
    @AppStorage("userName") private var userName = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Scene Details") {
                    LabeledContent("Name", value: scene.name)
                    TextField("Description", text: $shareDescription, axis: .vertical)
                    TextField("Tags (comma separated)", text: $shareTags)
                }
                
                Section("Preview") {
                    ScenePreviewCard(scene: scene)
                }
                
                Section {
                    Button(action: shareScene) {
                        Label("Share Scene", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Share Scene")
            .sheet(isPresented: $showingShareSheet) {
                if let url = createShareURL() {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    private func createShareURL() -> URL? {
        let sharedScene = SharedScene(
            name: scene.name,
            icon: scene.icon,
            scene: scene.scene,
            createdBy: userName,
            description: shareDescription,
            tags: shareTags.split(separator: ",").map(String.init)
        )
        return sharedScene.shareURL
    }
    
    private func shareScene() {
        showingShareSheet = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ScenePreviewCard: View {
    let scene: ScenePreset
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: scene.icon)
                .font(.largeTitle)
                .foregroundStyle(.orange)
            
            Text(scene.name)
                .font(.headline)
            
            // Scene type indicator
            HStack {
                Image(systemName: sceneTypeIcon)
                Text(sceneTypeDescription)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var sceneTypeIcon: String {
        switch scene.scene {
        case .color: return "paintpalette"
        case .colorTemperature: return "sun.max"
        case .colorFlow: return "waveform"
        case .multiLight: return "lightbulb.2"
        default: return "lightbulb"
        }
    }
    
    private var sceneTypeDescription: String {
        switch scene.scene {
        case .color: return "Color Scene"
        case .colorTemperature: return "Temperature Scene"
        case .colorFlow: return "Dynamic Scene"
        case .multiLight: return "Multi-Light Scene"
        default: return "Custom Scene"
        }
    }
} 