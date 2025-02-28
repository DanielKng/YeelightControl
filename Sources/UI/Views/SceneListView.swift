import SwiftUI

/// View for displaying and managing scenes
struct SceneListView: View {
    // MARK: - Environment
    
    @EnvironmentObject private var sceneManager: UnifiedSceneManager
    @EnvironmentObject private var yeelightManager: UnifiedYeelightManager
    
    // MARK: - State
    
    @State private var isCreatingScene = false
    @State private var selectedScene: Scene?
    
    // MARK: - Body
    
    var body: some View {
        UnifiedListView(
            title: "Scenes",
            items: sceneManager.scenes,
            emptyStateMessage: "No scenes created yet",
            onRefresh: {
                // Refresh scenes if needed
            },
            onDelete: { scene in
                sceneManager.deleteScene(scene)
            }
        ) { scene in
            SceneRow(
                scene: scene,
                onActivate: {
                    sceneManager.activateScene(scene)
                },
                onEdit: {
                    selectedScene = scene
                }
            )
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isCreatingScene = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isCreatingScene) {
            NavigationView {
                CreateSceneView(devices: yeelightManager.devices)
            }
        }
        .sheet(item: $selectedScene) { scene in
            NavigationView {
                SceneEditor(scene: scene)
            }
        }
    }
}

// MARK: - Supporting Views

private struct SceneRow: View {
    let scene: Scene
    let onActivate: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(scene.name)
                    .font(.headline)
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .imageScale(.small)
                        .foregroundColor(.yellow)
                    Text("\(scene.devices.count) devices")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                onActivate()
            } label: {
                Image(systemName: "play.fill")
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.borderless)
            
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SceneListView()
            .environmentObject(ServiceContainer.shared.sceneManager)
            .environmentObject(ServiceContainer.shared.yeelightManager)
    }
} 