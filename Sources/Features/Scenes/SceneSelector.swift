import SwiftUI

struct SceneSelector: View {
    @Binding var selectedScene: ScenePreset?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List(selection: $selectedScene) {
            Section("Favorites") {
                ForEach(DeviceStorage.shared.loadFavoriteScenes()) { scene in
                    SceneSelectorRow(scene: scene, isSelected: scene.id == selectedScene?.id)
                }
            }
            
            Section("All Scenes") {
                ForEach(DeviceStorage.shared.loadAllScenes()) { scene in
                    SceneSelectorRow(scene: scene, isSelected: scene.id == selectedScene?.id)
                }
            }
        }
        .navigationTitle("Select Scene")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
                    .disabled(selectedScene == nil)
            }
        }
    }
}

struct SceneSelectorRow: View {
    let scene: ScenePreset
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: scene.icon)
                .foregroundStyle(isSelected ? .orange : .primary)
            
            Text(scene.name)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.orange)
            }
        }
    }
} 