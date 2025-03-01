import SwiftUI
import UniformTypeIdentifiers
import Foundation

struct BackupData: Codable {
    let settings: [String: Any]
    let scenes: [DeviceStorage.SavedScene]
    let groups: [DeviceGroupManager.DeviceGroup]
    let automations: [Automation]
    let version: Int = 1

    enum CodingKeys: String, CodingKey {
        case settings
        case scenes
        case automations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        settings = try container.decode([String: AnyCodable].self, forKey: .settings)
        scenes = try container.decode([DeviceStorage.SavedScene].self, forKey: .scenes)
        automations = try container.decode([Automation].self, forKey: .automations)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(settings as [String: AnyCodable], forKey: .settings)
        try container.encode(scenes, forKey: .scenes)
        try container.encode(automations, forKey: .automations)
    }
}

struct BackupView: View {
    @State private var showingShareSheet = false
    @State private var backupData: Data?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "arrow.up.doc")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Backup Your Data")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("This will create a backup file containing all your scenes, groups, automations, and settings.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button(action: createBackup) {
                    Text("Create Backup")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
            .padding()
            .navigationTitle("Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let data = backupData {
                    ShareSheet(items: [data])
                }
            }
        }
    }

    private func createBackup() {
        // Create backup data
        let backup = BackupData(
            settings: UserDefaults.standard.dictionaryRepresentation(),
            scenes: DeviceStorage.shared.loadSavedScenes(),
            groups: DeviceGroupManager().groups,
            automations: DeviceStorage.shared.loadAutomations()
        )

        if let data = try? JSONEncoder().encode(backup) {
            backupData = data
            showingShareSheet = true
        }
    }
}

struct RestoreView: View {
    @State private var showingFilePicker = false
    @State private var restoreError: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Restore Your Data")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Select a backup file to restore your scenes, groups, automations, and settings.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button(action: { showingFilePicker = true }) {
                    Text("Select Backup File")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)

                if let error = restoreError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            .padding()
            .navigationTitle("Restore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [UTType.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first,
                  let data = try? Data(contentsOf: url),
                  let backup = try? JSONDecoder().decode(BackupData.self, from: data)
            else {
                restoreError = "Invalid backup file"
                return
            }
            restoreFromBackup(backup)
            dismiss()

        case .failure(let error):
            restoreError = error.localizedDescription
        }
    }

    private func restoreFromBackup(_ backup: BackupData) {
        // Restore settings
        for (key, value) in backup.settings {
            UserDefaults.standard.set(value, forKey: key)
        }

        // Restore scenes
        DeviceStorage.shared.restoreScenes(backup.scenes)

        // Restore groups
        DeviceStorage.shared.restoreGroups(backup.groups)

        // Restore automations
        DeviceStorage.shared.restoreAutomations(backup.automations)
    }
} 