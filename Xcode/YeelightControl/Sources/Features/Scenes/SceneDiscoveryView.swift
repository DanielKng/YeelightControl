import SwiftUI

struct SceneDiscoveryView: View {
    @StateObject private var viewModel = SceneDiscoveryViewModel()
    @State private var searchText = ""
    @State private var selectedCategory: SceneCategory?
    @State private var showingImportSheet = false
    @State private var selectedScene: SharedScene?
    
    enum SceneCategory: String, CaseIterable {
        case popular = "Popular"
        case recent = "Recent"
        case mood = "Mood"
        case productivity = "Productivity"
        case entertainment = "Entertainment"
        
        var icon: String {
            switch self {
            case .popular: return "star.fill"
            case .recent: return "clock.fill"
            case .mood: return "heart.fill"
            case .productivity: return "briefcase.fill"
            case .entertainment: return "tv.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(SceneCategory.allCases, id: \.rawValue) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: category == selectedCategory,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Featured scenes
                    if selectedCategory == nil {
                        FeaturedScenesView(scenes: viewModel.featuredScenes)
                    }
                    
                    // Scene grid
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 160), spacing: 16)
                    ], spacing: 16) {
                        ForEach(filteredScenes, id: \.name) { scene in
                            SharedSceneCard(scene: scene) {
                                selectedScene = scene
                                showingImportSheet = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Discover")
            .searchable(text: $searchText, prompt: "Search scenes")
            .sheet(isPresented: $showingImportSheet) {
                if let scene = selectedScene {
                    ImportSceneView(scene: scene)
                }
            }
            .refreshable {
                await viewModel.fetchScenes()
            }
        }
    }
    
    private var filteredScenes: [SharedScene] {
        let scenes = selectedCategory != nil ?
            viewModel.scenes.filter { $0.tags.contains(selectedCategory!.rawValue.lowercased()) } :
            viewModel.scenes
        
        if searchText.isEmpty {
            return scenes
        }
        
        return scenes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

struct CategoryButton: View {
    let category: SceneDiscoveryView.SceneCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: category.icon)
                Text(category.rawValue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? .orange : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct SharedSceneCard: View {
    let scene: SharedScene
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: scene.icon)
                    .font(.title)
                    .foregroundStyle(.orange)
                
                Text(scene.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(scene.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text("By \(scene.createdBy)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "square.and.arrow.down")
                        .font(.caption)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

class SceneDiscoveryViewModel: ObservableObject {
    @Published private(set) var scenes: [SharedScene] = []
    @Published private(set) var featuredScenes: [SharedScene] = []
    
    func fetchScenes() async {
        // In a real app, this would fetch from a backend service
        // For now, we'll use sample data
        await MainActor.run {
            scenes = SampleData.sharedScenes
            featuredScenes = Array(SampleData.sharedScenes.prefix(3))
        }
    }
}

// Sample data for testing
private enum SampleData {
    static let sharedScenes: [SharedScene] = [
        SharedScene(
            name: "Cozy Evening",
            icon: "sunset.fill",
            scene: .color(red: 255, green: 147, blue: 41),
            createdBy: "Sarah",
            description: "Perfect for relaxing evenings",
            tags: ["mood", "relaxation"]
        ),
        // Add more sample scenes...
    ]
} 