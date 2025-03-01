import SwiftUI
import Core

/// View for displaying and managing scenes
struct SceneListView: View {
    @ObservedObject var sceneManager: UnifiedSceneManager
    @State private var searchText = ""
    @State private var showingAddScene = false
    @State private var selectedScene: (any YeelightScene)?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredScenes) { scene in
                    SceneRow(scene: scene)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedScene = scene
                        }
                        .contextMenu {
                            Button(action: {
                                sceneManager.activateScene(scene)
                            }) {
                                Label("Activate", systemImage: "play.fill")
                            }
                            
                            Button(action: {
                                selectedScene = scene
                            }) {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive, action: {
                                selectedScene = scene
                                showingDeleteConfirmation = true
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .onDelete(perform: deleteScenes)
            }
            .navigationTitle("Scenes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddScene = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search scenes")
            .sheet(isPresented: $showingAddScene) {
                CreateSceneView(sceneManager: sceneManager)
            }
            .sheet(item: $selectedScene) { scene in
                ScenePreview(scene: scene)
                    .environmentObject(sceneManager)
            }
            .alert("Delete Scene", isPresented: $showingDeleteConfirmation, presenting: selectedScene) { scene in
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let index = sceneManager.scenes.firstIndex(where: { $0.id == scene.id }) {
                        sceneManager.deleteScene(at: IndexSet(integer: index))
                    }
                }
            } message: { scene in
                Text("Are you sure you want to delete \(scene.name)? This action cannot be undone.")
            }
            .overlay {
                if sceneManager.scenes.isEmpty {
                    ContentUnavailableView(
                        "No Scenes",
                        systemImage: "theatermasks",
                        description: Text("Create a scene using the + button")
                    )
                }
            }
        }
    }
    
    private var filteredScenes: [any YeelightScene] {
        if searchText.isEmpty {
            return sceneManager.scenes
        } else {
            return sceneManager.scenes.filter { scene in
                scene.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func deleteScenes(at offsets: IndexSet) {
        for index in offsets {
            if index < sceneManager.scenes.count {
                let scene = sceneManager.scenes[index]
                sceneManager.deleteScene(scene)
            }
        }
    }
}

// MARK: - Supporting Views

private struct SceneRow: View {
    let scene: any YeelightScene
    
    var body: some View {
        HStack {
            Image(systemName: iconForScene(scene))
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(scene.name)
                    .font(.headline)
                
                Text(scene.description ?? "No description")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                // Activate scene
            }) {
                Image(systemName: "play.fill")
                    .foregroundColor(.accentColor)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
    
    private func iconForScene(_ scene: any YeelightScene) -> String {
        // Determine icon based on scene type
        return "theatermasks.fill"
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SceneListView(sceneManager: ServiceContainer.shared.sceneManager)
    }
} 