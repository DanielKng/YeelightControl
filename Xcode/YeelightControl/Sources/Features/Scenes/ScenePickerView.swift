import SwiftUI

struct ScenePickerView: View {
    @Binding var selectedScene: YeelightManager.Scene?
    @StateObject private var sceneManager = SceneManager.shared
    @State private var showingCreateScene = false
    @State private var searchText = ""
    @State private var selectedCategory: SceneCategory?
    
    enum SceneCategory: String, CaseIterable {
        case all = "All"
        case color = "Color"
        case temperature = "Temperature"
        case dynamic = "Dynamic"
        case custom = "Custom"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SceneCategory.allCases, id: \.self) { category in
                        CategoryPill(
                            title: category.rawValue,
                            isSelected: category == selectedCategory,
                            action: { selectedCategory = category }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // Scene grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 150), spacing: 16)
                ], spacing: 16) {
                    ForEach(filteredScenes) { scene in
                        SceneCard(
                            scene: scene,
                            isSelected: selectedScene?.id == scene.id,
                            action: { selectedScene = scene }
                        )
                    }
                }
                .padding()
            }
        }
        .searchable(text: $searchText, prompt: "Search scenes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingCreateScene = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateScene) {
            CreateSceneView()
        }
    }
    
    private var filteredScenes: [YeelightManager.Scene] {
        var scenes = sceneManager.scenes
        
        if let category = selectedCategory {
            scenes = scenes.filter { scene in
                switch category {
                case .all: return true
                case .color: return scene.type == .color
                case .temperature: return scene.type == .temperature
                case .dynamic: return scene.type == .dynamic
                case .custom: return scene.type == .custom
                }
            }
        }
        
        if !searchText.isEmpty {
            scenes = scenes.filter { scene in
                scene.name.localizedCaseInsensitiveContains(searchText) ||
                scene.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return scenes
    }
}

struct SceneCard: View {
    let scene: YeelightManager.Scene
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Scene preview
                RoundedRectangle(cornerRadius: 12)
                    .fill(scenePreviewColor)
                    .frame(height: 100)
                    .overlay {
                        Image(systemName: scene.icon)
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                
                VStack(alignment: .leading) {
                    Text(scene.name)
                        .font(.headline)
                    
                    Text(scene.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? .orange : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var scenePreviewColor: Color {
        switch scene.type {
        case .color:
            return Color(
                red: Double(scene.color?.red ?? 0) / 255,
                green: Double(scene.color?.green ?? 0) / 255,
                blue: Double(scene.color?.blue ?? 0) / 255
            )
        case .temperature:
            return .orange
        case .dynamic:
            return .purple
        case .custom:
            return .blue
        }
    }
}

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? .orange : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
} 