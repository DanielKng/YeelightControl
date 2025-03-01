import SwiftUI

/// View for displaying and managing scenes
struct SceneListView: View {
    @ObservedObject var sceneManager: SceneManager
    @State private var showingCreateScene = false
    @State private var selectedScene: Scene?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(sceneManager.scenes) { scene in
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
                        showingCreateScene = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateScene) {
                CreateSceneView(sceneManager: sceneManager)
            }
            .sheet(item: $selectedScene) { scene in
                EditSceneView(sceneManager: sceneManager, scene: scene)
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
                        systemImage: "lightbulb.slash",
                        description: Text("Tap the + button to create a new scene")
                    )
                }
            }
        }
    }
    
    private func deleteScenes(at offsets: IndexSet) {
        sceneManager.deleteScene(at: offsets)
    }
}

// MARK: - Supporting Views

private struct SceneRow: View {
    let scene: Scene
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(scene.name)
                    .font(.headline)
                
                Text("\(scene.devices.count) devices")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                // Activate scene
            }) {
                Image(systemName: "play.fill")
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
NavigationView {
SceneListView(sceneManager: ServiceContainer.shared.sceneManager)
}
} 