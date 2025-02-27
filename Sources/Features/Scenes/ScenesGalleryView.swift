import SwiftUI

struct ScenesGalleryView: View {
    @ObservedObject var manager: YeelightManager
    @AppStorage("favoriteScenes") private var favoriteScenes: [String] = []
    @State private var selectedCategory: SceneCategory = .favorites
    @State private var showingSceneEditor = false
    
    enum SceneCategory: String, CaseIterable {
        case favorites = "Favorites"
        case moods = "Moods"
        case dynamic = "Dynamic"
        case multiLight = "Multi-Light"
        case strip = "Strip Effects"
        case custom = "Custom"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Horizontal category picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(SceneCategory.allCases, id: \.self) { category in
                                CategoryButton(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Scene grid based on category
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 160), spacing: 16)
                    ], spacing: 16) {
                        ForEach(scenesForCategory(selectedCategory)) { scene in
                            SceneCard(
                                scene: scene,
                                isFavorite: favoriteScenes.contains(scene.id.uuidString),
                                onActivate: { activateScene(scene) },
                                onToggleFavorite: { toggleFavorite(scene) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Scenes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingSceneEditor = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingSceneEditor) {
                SceneEditorView(manager: manager)
            }
        }
    }
    
    private func scenesForCategory(_ category: SceneCategory) -> [ScenePreset] {
        switch category {
        case .favorites:
            return allScenes.filter { favoriteScenes.contains($0.id.uuidString) }
        case .moods:
            return moodScenes
        case .dynamic:
            return dynamicScenes
        case .multiLight:
            return manager.devices.count > 1 ? multiLightScenes : []
        case .strip:
            return manager.devices.count > 1 ? stripEffectScenes : []
        case .custom:
            return customScenes
        }
    }
    
    private var allScenes: [ScenePreset] {
        moodScenes + dynamicScenes + multiLightScenes + stripEffectScenes + customScenes
    }
    
    private func activateScene(_ scene: ScenePreset) {
        switch scene.scene {
        case .multiLight(let multiScene):
            multiScene.apply(to: manager.devices, using: manager)
        case .stripEffect(let effect):
            manager.startStripEffect(effect)
        default:
            // Apply to all devices or selected devices
            for device in manager.devices {
                manager.setScene(device, scene: scene.scene)
            }
        }
    }
    
    private func toggleFavorite(_ scene: ScenePreset) {
        if favoriteScenes.contains(scene.id.uuidString) {
            favoriteScenes.removeAll { $0 == scene.id.uuidString }
        } else {
            favoriteScenes.append(scene.id.uuidString)
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? .orange : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct SceneCard: View {
    let scene: ScenePreset
    let isFavorite: Bool
    let onActivate: () -> Void
    let onToggleFavorite: () -> Void
    
    @State private var isActive = false
    
    var body: some View {
        Button(action: {
            withAnimation {
                isActive.toggle()
                onActivate()
            }
        }) {
            VStack(spacing: 16) {
                // Scene icon
                ZStack {
                    Circle()
                        .fill(isActive ? .orange : Color(.systemGray5))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: scene.icon)
                        .font(.title2)
                        .foregroundStyle(isActive ? .white : .primary)
                }
                
                Text(scene.name)
                    .font(.headline)
                
                // Favorite button
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundStyle(isFavorite ? .yellow : .gray)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
} 