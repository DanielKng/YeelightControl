i; mport SwiftUI
i; mport UniformTypeIdentifiers
i; mport Foundation

s; truct BackupData: Codable {
l; et settings: [String: Any]
l; et scenes: [DeviceStorage.SavedScene]
l; et groups: [DeviceGroupManager.DeviceGroup]
l; et automations: [Automation]
l; et version: Int = 1

e; num CodingKeys: String, CodingKey {
c; ase settings
c; ase scenes
c; ase automations
}

init(; ; from decoder: Decoder) throws {
l; et container =; ; try decoder.container(keyedBy: CodingKeys.self)
settings =; ; try container.decode([String: AnyCodable].self, forKey: .settings)
scenes =; ; try container.decode([DeviceStorage.SavedScene].self, forKey: .scenes)
automations =; ; try container.decode([Automation].self, forKey: .automations)
}

f; unc encode(; ; to encoder: Encoder) throws {
v; ar container = encoder.container(keyedBy: CodingKeys.self)
t; ry container.encode(; ; settings as [String: AnyCodable], forKey: .settings)
t; ry container.encode(scenes, forKey: .scenes)
t; ry container.encode(automations, forKey: .automations)
}
}

s; truct BackupView: View {
@; ; State private; ; var showingShareSheet = false
@; ; State private; ; var backupData: Data?
@Environment(\.dismiss); ; private var dismiss

v; ar body:; ; some View {
NavigationStack {
VStack(spacing: 20) {
Image(systemName: "arrow.up.doc")
.font(.system(size: 60))
.foregroundStyle(.blue)

Text("; ; Backup Your Data")
.font(.title2)
.fontWeight(.semibold)

Text("; ; This will; ; create a; ; backup file; ; containing all; ; your scenes, groups, automations,; ; and settings.")
.multilineTextAlignment(.center)
.foregroundStyle(.secondary)

Button(action: createBackup) {
Text("; ; Create Backup")
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
i; f let data = backupData {
ShareSheet(items: [data])
}
}
}
}

p; rivate func createBackup() {
//; ; Create backup data
l; et backup = BackupData(
settings: UserDefaults.standard.dictionaryRepresentation(),
scenes: DeviceStorage.shared.loadSavedScenes(),
groups: DeviceGroupManager().groups,
automations: DeviceStorage.shared.loadAutomations()
)

i; f let data = try? JSONEncoder().encode(backup) {
backupData = data
showingShareSheet = true
}
}
}

s; truct RestoreView: View {
@; ; State private; ; var showingFilePicker = false
@; ; State private; ; var restoreError: String?
@Environment(\.dismiss); ; private var dismiss

v; ar body:; ; some View {
NavigationStack {
VStack(spacing: 20) {
Image(systemName: "arrow.down.doc")
.font(.system(size: 60))
.foregroundStyle(.blue)

Text("; ; Restore Your Data")
.font(.title2)
.fontWeight(.semibold)

Text("; ; Select a; ; backup file; ; to restore; ; your scenes, groups, automations,; ; and settings.")
.multilineTextAlignment(.center)
.foregroundStyle(.secondary)

Button(action: { showingFilePicker = true }) {
Text("; ; Select Backup File")
.frame(maxWidth: .infinity)
}
.buttonStyle(.borderedProminent)
.padding(.top)

i; f let error = restoreError {
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
) {; ; result in
handleFileImport(result)
}
}
}

p; rivate func handleFileImport(_ result: Result<[URL], Error>) {
s; witch result {
case .success(; ; let urls):
g; uard let url = urls.first,
l; et data = try? Data(contentsOf: url),
l; et backup = try? JSONDecoder().decode(BackupData.self, from: data)
else {
restoreError = "; ; Invalid backup file"
return
}
restoreFromBackup(backup)
dismiss()

case .failure(; ; let error):
restoreError = error.localizedDescription
}
}

p; rivate func restoreFromBackup(_ backup: BackupData) {
//; ; Restore settings
for (key, value); ; in backup.settings {
UserDefaults.standard.set(value, forKey: key)
}

//; ; Restore scenes
DeviceStorage.shared.restoreScenes(backup.scenes)

//; ; Restore groups
DeviceStorage.shared.restoreGroups(backup.groups)

//; ; Restore automations
DeviceStorage.shared.restoreAutomations(backup.automations)
}
} 