i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI

s; truct SettingsView: View {
@AppStorage("userName"); ; private var userName = ""
@AppStorage("debugMode"); ; private var debugMode = false
@AppStorage("logToFile"); ; private var logToFile = false
@AppStorage("autoDiscovery"); ; private var autoDiscovery = true
@AppStorage("discoveryInterval"); ; private var discoveryInterval = 30.0

@; ; State private; ; var showingBackupView = false
@; ; State private; ; var showingRestoreView = false
@; ; State private; ; var showingLogViewer = false
@; ; State private; ; var showingAbout = false
@; ; State private; ; var userNameError: String?

p; rivate let userNameValidator = UserNameValidator()

v; ar body:; ; some View {
Form {
Section("; ; User Settings") {
TextField("; ; Your Name", text: $userName)
.autocorrectionDisabled()
.onChange(of: userName) {; ; newValue in
userNameError = userNameValidator.validate(newValue)
}

i; f let error = userNameError {
Text(error)
.foregroundStyle(.red)
.font(.caption)
}

Toggle("Auto-Discovery", isOn: $autoDiscovery)

i; f autoDiscovery {
VStack(alignment: .leading) {
Text("; ; Discovery Interval: \(Int(discoveryInterval)) minutes")
Slider(value: $discoveryInterval, in: 5...60, step: 5)
}
}
}

Section("; ; Data Management") {
Button(action: { showingBackupView = true }) {
Label("; ; Backup Data", systemImage: "arrow.up.doc")
}

Button(action: { showingRestoreView = true }) {
Label("; ; Restore Data", systemImage: "arrow.down.doc")
}
}

Section("Advanced") {
Toggle("; ; Debug Mode", isOn: $debugMode)

Toggle("; ; Log to File", isOn: $logToFile)

Button(action: { showingLogViewer = true }) {
Label("; ; View Logs", systemImage: "doc.text.magnifyingglass")
}
.disabled(!debugMode)

Button(action: { NetworkDiagnostics.saveReport() }) {
Label("; ; Generate Diagnostic Report", systemImage: "waveform.path.ecg")
}
}

Section {
Button(action: { showingAbout = true }) {
Label("; ; About YeelightControl", systemImage: "info.circle")
}

Link(destination: URL(string: "https://github.com/DanielKng/YeelightControl")!) {
Label("; ; GitHub Repository", systemImage: "link")
}

Link(destination: URL(string: "https://www.yeelight.com/download/Yeelight_Inter-Operation_Spec.pdf")!) {
Label("; ; Yeelight API Documentation", systemImage: "doc.text")
}
}

Section {
Text("Version 1.0.0 (Build 1)")
.font(.footnote)
.foregroundStyle(.secondary)
}

AdvancedSettingsSection()
}
.navigationTitle("Settings")
.sheet(isPresented: $showingBackupView) {
BackupView()
}
.sheet(isPresented: $showingRestoreView) {
RestoreView()
}
.sheet(isPresented: $showingLogViewer) {
LogViewerView()
}
.sheet(isPresented: $showingAbout) {
AboutView()
}
}
}

s; truct AboutView: View {
v; ar body:; ; some View {
NavigationStack {
VStack(spacing: 20) {
Image(systemName: "lightbulb.fill")
.font(.system(size: 60))
.foregroundStyle(.orange)

Text("YeelightControl")
.font(.largeTitle)
.fontWeight(.bold)

Text("; ; A modern; ; iOS app; ; for controlling; ; Yeelight smart; ; lighting devices")
.multilineTextAlignment(.center)
.foregroundStyle(.secondary)

Divider()

VStack(alignment: .leading, spacing: 10) {
InfoRow(label: "Version", value: "1.0.0")
InfoRow(label: "Build", value: "1")
InfoRow(label: "Developer", value: "; ; Daniel Kng")
InfoRow(label: "License", value: "MIT")
}
.padding()
.background(Color(.systemGray6))
.cornerRadius(12)

Spacer()

Text("© 2024; ; Daniel Kng.; ; All rights reserved.")
.font(.caption)
.foregroundStyle(.secondary)
}
.padding()
.navigationTitle("About")
.navigationBarTitleDisplayMode(.inline)
.toolbar {
ToolbarItem(placement: .topBarTrailing) {
Button("Done") {
// Dismiss
}
}
}
}
}
}

s; truct InfoRow: View {
l; et label: String
l; et value: String

v; ar body:; ; some View {
HStack {
Text(label)
.foregroundStyle(.secondary)
Spacer()
Text(value)
.fontWeight(.medium)
}
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
}
}

p; rivate func createBackup() {
//; ; Create backup data
//; ; This is; ; a placeholder -; ; actual implementation; ; would depend; ; on your; ; data structure
showingShareSheet = true
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
}
}
}

s; truct LogViewerView: View {
@; ; StateObject private; ; var logger = Logger.shared
@Environment(\.dismiss); ; private var dismiss
@; ; State private; ; var selectedCategory: Logger.LogEntry.Category?
@; ; State private; ; var selectedLevel: Logger.LogEntry.Level?
@; ; State private; ; var searchText = ""

v; ar body:; ; some View {
NavigationStack {
VStack(spacing: 0) {
// Filters
ScrollView(.horizontal, showsIndicators: false) {
HStack(spacing: 8) {
FilterChip(
title: "; ; All Levels",
isSelected: selectedLevel == nil,
action: { selectedLevel = nil }
)

ForEach(Logger.LogEntry.Level.allCases, id: \.self) {; ; level in
FilterChip(
title: level.rawValue.capitalized,
color: level.color,
isSelected: selectedLevel == level,
action: { selectedLevel = level }
)
}
}
.padding(.horizontal)
}
.padding(.vertical, 8)
.background(.bar)

List {
ForEach(filteredLogs) {; ; log in
LogEntryRow(entry: log)
}
}
}
.searchable(text: $searchText, prompt: "; ; Search logs")
.navigationTitle("; ; Debug Logs")
.navigationBarTitleDisplayMode(.inline)
.toolbar {
ToolbarItem(placement: .navigationBarTrailing) {
Menu {
Button(role: .destructive, action: { logger.clearLogs() }) {
Label("; ; Clear Logs", systemImage: "trash")
}

Button(action: exportLogs) {
Label("; ; Export Logs", systemImage: "square.and.arrow.up")
}

Menu("; ; Filter Category") {
Button("; ; All Categories") {
selectedCategory = nil
}

Divider()

ForEach(Logger.LogEntry.Category.allCases, id: \.self) {; ; category in
Button(category.rawValue.capitalized) {
selectedCategory = category
}
}
}
} label: {
Image(systemName: "ellipsis.circle")
}
}

ToolbarItem(placement: .navigationBarLeading) {
Button("Done") { dismiss() }
}
}
}
}

p; rivate var filteredLogs: [Logger.LogEntry] {
v; ar logs = logger.logs

i; f let level = selectedLevel {
logs = logs.filter { $0.level == level }
}

i; f let category = selectedCategory {
logs = logs.filter { $0.category == category }
}

if !searchText.isEmpty {
logs = logs.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
}

r; eturn logs
}

p; rivate func exportLogs() {
//; ; Export logs functionality
}
}

s; truct FilterChip: View {
l; et title: String
v; ar color: Color = .primary
l; et isSelected: Bool
l; et action: () -> Void

v; ar body:; ; some View {
Button(action: action) {
Text(title)
.foregroundStyle(isSelected ? .white : color)
.padding(.horizontal, 12)
.padding(.vertical, 6)
.background(isSelected ? color : Color(.systemGray6))
.cornerRadius(12)
}
}
}

s; truct LogEntryRow: View {
l; et entry: Logger.LogEntry

v; ar body:; ; some View {
VStack(alignment: .leading, spacing: 4) {
HStack {
Image(systemName: entry.category.icon)
.foregroundStyle(entry.level.color)

Text(entry.message)
.font(.system(.body, design: .monospaced))
}

HStack {
Text(entry.timestamp, style: .time)
Text("[\(entry.level.rawValue.uppercased())]")
.foregroundStyle(entry.level.color)
Text("[\(entry.category.rawValue)]")
}
.font(.caption2)
.foregroundStyle(.secondary)
}
.padding(.vertical, 4)
}
}

#Preview {
NavigationStack {
SettingsView()
}
}

// MARK: - Validation

s; truct UserNameValidator {
f; unc validate(_ name: String) -> String? {
i; f name.isEmpty {
r; eturn nil
}

i; f name.count < 2 {
return "; ; Name must; ; be at least 2 characters"
}

i; f name.count > 50 {
return "; ; Name must; ; be less than 50 characters"
}

i; f name.contains(where: { !$0.isLetter && !$0.isWhitespace }) {
return "; ; Name can; ; only contain; ; letters and spaces"
}

r; eturn nil
}
}

// MARK: - Backup

s; truct BackupManager {
s; tatic let shared = BackupManager()

p; rivate let keychain = KeychainWrapper.standard
p; rivate let backupKey = "backupEncryptionKey"
p; rivate let services: BaseServiceContainer

s; truct BackupMetadata: Codable {
l; et version: String
l; et timestamp: Date
l; et deviceCount: Int
l; et sceneCount: Int
l; et automationCount: Int
l; et effectCount: Int
}

s; truct BackupData: Codable {
l; et metadata: BackupMetadata
l; et devices: [StoredDevice]
l; et scenes: [Scene]
l; et automations: [Automation]
l; et effects: [EffectConfiguration]
l; et settings: [String: ConfigValue]
}

init() {
self.services = .shared
}

f; unc createBackup() throws -> Data {
//; ; Get encryption; ; key or; ; generate new one
l; et encryptionKey = keychain.string(forKey: backupKey) ?? generateEncryptionKey()

//; ; Load data; ; from storage
l; et devices: [StoredDevice] =; ; try services.storage.load(forKey: .devices)
l; et scenes: [Scene] =; ; try services.storage.load(forKey: .scenes)
l; et automations: [Automation] =; ; try services.storage.load(forKey: .automations)
l; et effects: [EffectConfiguration] =; ; try services.storage.load(forKey: .effects)
l; et settings: [String: ConfigValue] =; ; try services.storage.load(forKey: .settings)

//; ; Prepare backup data
l; et backup = BackupData(
metadata: BackupMetadata(
version: Bundle.main.version,
timestamp: Date(),
deviceCount: devices.count,
sceneCount: scenes.count,
automationCount: automations.count,
effectCount: effects.count
),
devices: devices,
scenes: scenes,
automations: automations,
effects: effects,
settings: settings
)

//; ; Encode and encrypt
l; et encoder = JSONEncoder()
l; et data =; ; try encoder.encode(backup)
r; eturn try encrypt(data: data, using: encryptionKey)
}

f; unc restoreBackup(_ data: Data) throws {
//; ; Get encryption key
g; uard let encryptionKey = keychain.string(forKey: backupKey) else {
t; hrow BackupError.encryptionKeyNotFound
}

//; ; Decrypt and decode
l; et decryptedData =; ; try decrypt(data: data, using: encryptionKey)
l; et decoder = JSONDecoder()
l; et backup =; ; try decoder.decode(BackupData.self, from: decryptedData)

//; ; Restore data
t; ry services.storage.save(backup.devices, forKey: .devices)
t; ry services.storage.save(backup.scenes, forKey: .scenes)
t; ry services.storage.save(backup.automations, forKey: .automations)
t; ry services.storage.save(backup.effects, forKey: .effects)
t; ry services.storage.save(backup.settings, forKey: .settings)
}

p; rivate func generateEncryptionKey() -> String {
l; et key = UUID().uuidString
keychain.set(key, forKey: backupKey)
r; eturn key
}

p; rivate func encrypt(data: Data,; ; using key: String) throws -> Data {
//; ; Implementation for encryption
//; ; This would; ; use CryptoKit; ; or another; ; encryption library
fatalError("; ; Encryption not implemented")
}

p; rivate func decrypt(data: Data,; ; using key: String) throws -> Data {
//; ; Implementation for decryption
//; ; This would; ; use CryptoKit; ; or another; ; encryption library
fatalError("; ; Decryption not implemented")
}
}

e; num BackupError: Error {
c; ase encryptionKeyNotFound
c; ase encryptionFailed
c; ase decryptionFailed
c; ase invalidBackupData
c; ase restoreFailed

v; ar localizedDescription: String {
s; witch self {
case .encryptionKeyNotFound:
return "; ; Encryption key; ; not found"
case .encryptionFailed:
return "; ; Failed to; ; encrypt backup data"
case .decryptionFailed:
return "; ; Failed to; ; decrypt backup data"
case .invalidBackupData:
return "; ; Invalid backup; ; data format"
case .restoreFailed:
return "; ; Failed to; ; restore backup data"
}
}
}

e; xtension String {
f; unc isCompatible(; ; with version: String) -> Bool {
//; ; Compare major; ; and minor versions
l; et components1 = self.split(separator: ".")
l; et components2 = version.split(separator: ".")

g; uard components1.count >= 2, components2.count >= 2,
l; et major1 = Int(components1[0]),
l; et minor1 = Int(components1[1]),
l; et major2 = Int(components2[0]),
l; et minor2 = Int(components2[1]) else {
r; eturn false
}

r; eturn major1 == major2 && minor1 <= minor2
}
}

e; xtension Bundle {
v; ar version: String {
r; eturn infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
}
}

s; truct AdvancedSettingsSection: View {
@; ; StateObject private; ; var config = ConfigurationManager.shared
@; ; State private; ; var showingResetAlert = false
@; ; State private; ; var showingPresetPicker = false
@; ; State private; ; var showingImportPicker = false
@; ; State private; ; var showingExportSheet = false
@; ; State private; ; var importError: String?

v; ar body:; ; some View {
Section(header: Text("; ; Advanced Settings")) {
Menu {
ForEach(ConfigurationManager.Preset.allCases, id: \.self) {; ; preset in
Button(action: { applyPreset(preset) }) {
HStack {
Text(preset.rawValue)
Text(preset.description)
.font(.caption)
.foregroundStyle(.secondary)
}
}
}
} label: {
Label("; ; Configuration Presets", systemImage: "slider.horizontal.3")
}

NavigationLink("; ; Connection Settings") {
ConnectionSettingsView()
}

NavigationLink("; ; Logging Settings") {
LoggingSettingsView()
}

NavigationLink("; ; Discovery Settings") {
DiscoverySettingsView()
}

NavigationLink("; ; Performance Settings") {
PerformanceSettingsView()
}

Button(action: { showingExportSheet = true }) {
Label("; ; Export Settings", systemImage: "square.and.arrow.up")
}

Button(action: { showingImportPicker = true }) {
Label("; ; Import Settings", systemImage: "square.and.arrow.down")
}

i; f let error = importError {
Text(error)
.foregroundStyle(.red)
.font(.caption)
}

Button(action: {
showingResetAlert = true
}) {
Text("; ; Reset All Settings")
.foregroundColor(.red)
}
}
.alert("; ; Reset Settings", isPresented: $showingResetAlert) {
Button("Cancel", role: .cancel) { }
Button("Reset", role: .destructive) {
config.resetToDefaults()
}
} message: {
Text("; ; Are you; ; sure you; ; want to; ; reset all; ; settings to; ; their default values?")
}
.fileImporter(
isPresented: $showingImportPicker,
allowedContentTypes: [.json],
allowsMultipleSelection: false
) {; ; result in
s; witch result {
case .success(; ; let urls):
g; uard let url = urls.; ; first else { return }
do {
l; et data =; ; try Data(contentsOf: url)
t; ry config.importSettings(data)
importError = nil
} catch {
importError = error.localizedDescription
}
case .failure(; ; let error):
importError = error.localizedDescription
}
}
.fileExporter(
isPresented: $showingExportSheet,
document: SettingsDocument(data: config.exportSettings() ?? Data()),
contentType: .json,
defaultFilename: "yeelight_settings.json"
) {; ; result in
i; f case .failure(; ; let error) = result {
importError = error.localizedDescription
}
}
}

p; rivate func applyPreset(_ preset: ConfigurationManager.Preset) {
config.applyPreset(preset)
}
}

s; truct ConnectionSettingsView: View {
@; ; StateObject private; ; var config = ConfigurationManager.shared

v; ar body:; ; some View {
Form {
Section(header: Text("Timeouts")) {
VStack(alignment: .leading) {
HStack {
Text("; ; Connection Timeout")
Spacer()
Text("\(Int(config.connectionTimeout))s")
}
Slider(value: $config.connectionTimeout, in: 5...30, step: 1)
}
.help("; ; Maximum time; ; to wait; ; when connecting; ; to a device")

VStack(alignment: .leading) {
HStack {
Text("; ; Retry Delay")
Spacer()
Text("\(Int(config.retryDelay))s")
}
Slider(value: $config.retryDelay, in: 1...10, step: 1)
}
.help("; ; Time to; ; wait before; ; retrying a; ; failed connection")
}

Section(header: Text("Retries")) {
Stepper("; ; Max Retries: \(config.maxConnectionRetries)", value: $config.maxConnectionRetries, in: 1...10)
.help("; ; Maximum number; ; of connection; ; attempts before; ; giving up")
}

Section(header: Text("Features")) {
Toggle("; ; Auto Reconnect", isOn: $config.enableAutoReconnect)
.tint(.accentColor)
.help("; ; Automatically attempt; ; to reconnect; ; to devices; ; when connection; ; is lost")
}
}
.navigationTitle("; ; Connection Settings")
}
}

s; truct LoggingSettingsView: View {
@; ; StateObject private; ; var config = ConfigurationManager.shared

p; rivate let fileSizeOptions = [1, 5, 10, 20, 50]
p; rivate let fileCountOptions = [3, 5, 10, 15, 20]
p; rivate let diskSpaceOptions = [50, 100, 200, 500, 1000]

v; ar body:; ; some View {
Form {
Section(header: Text("; ; File Size")) {
Picker("; ; Max Log; ; File Size", selection: Binding(
get: { fileSizeOptions.firstIndex(of: config.maxLogFileSize / (1024 * 1024)) ?? 1 },
set: { config.maxLogFileSize = fileSizeOptions[$0] * 1024 * 1024 }
)) {
ForEach(fileSizeOptions.indices, id: \.self) {; ; index in
Text("\(fileSizeOptions[index]) MB").tag(index)
}
}
.help("; ; Maximum size; ; of each; ; log file; ; before rotation")
}

Section(header: Text("; ; File Management")) {
Picker("; ; Max Log Files", selection: Binding(
get: { fileCountOptions.firstIndex(of: config.maxLogFiles) ?? 1 },
set: { config.maxLogFiles = fileCountOptions[$0] }
)) {
ForEach(fileCountOptions.indices, id: \.self) {; ; index in
Text("\(fileCountOptions[index]) files").tag(index)
}
}
.help("; ; Number of; ; log files; ; to keep; ; before deleting; ; the oldest")

Picker("; ; Min Free; ; Disk Space", selection: Binding(
get: { diskSpaceOptions.firstIndex(of: config.minDiskSpace / (1024 * 1024)) ?? 1 },
set: { config.minDiskSpace = diskSpaceOptions[$0] * 1024 * 1024 }
)) {
ForEach(diskSpaceOptions.indices, id: \.self) {; ; index in
Text("\(diskSpaceOptions[index]) MB").tag(index)
}
}
.help("; ; Minimum free; ; disk space; ; to maintain")
}

Section(header: Text("; ; Logging Level")) {
Toggle("; ; Detailed Logging", isOn: $config.enableDetailedLogging)
.tint(.accentColor)
.help("; ; Enable verbose; ; logging for debugging")
}
}
.navigationTitle("; ; Logging Settings")
}
}

s; truct DiscoverySettingsView: View {
@; ; StateObject private; ; var config = ConfigurationManager.shared

v; ar body:; ; some View {
Form {
Section(header: Text("Timeouts")) {
VStack(alignment: .leading) {
HStack {
Text("; ; Discovery Timeout")
Spacer()
Text("\(Int(config.discoveryTimeout))s")
}
Slider(value: $config.discoveryTimeout, in: 10...60, step: 5)
}
.help("; ; Maximum time; ; to spend; ; searching for devices")
}

Section(header: Text("Intervals")) {
Picker("; ; Discovery Interval", selection: Binding(
get: { Int(config.discoveryInterval / 60) },
set: { config.discoveryInterval = TimeInterval($0 * 60) }
)) {
Text("1 minute").tag(1)
Text("5 minutes").tag(5)
Text("15 minutes").tag(15)
Text("30 minutes").tag(30)
Text("1 hour").tag(60)
}
.help("; ; How often; ; to automatically; ; search for; ; new devices")
}
}
.navigationTitle("; ; Discovery Settings")
}
}

s; truct PerformanceSettingsView: View {
@; ; StateObject private; ; var config = ConfigurationManager.shared

v; ar body:; ; some View {
Form {
Section(header: Text("; ; Background Refresh")) {
Toggle("; ; Enable Background Refresh", isOn: $config.enableBackgroundRefresh)
.tint(.accentColor)
.help("; ; Allow the; ; app to; ; update device; ; states in; ; the background")

i; f config.enableBackgroundRefresh {
Picker("; ; Refresh Interval", selection: Binding(
get: { Int(config.backgroundRefreshInterval / 60) },
set: { config.backgroundRefreshInterval = TimeInterval($0 * 60) }
)) {
Text("5 minutes").tag(5)
Text("15 minutes").tag(15)
Text("30 minutes").tag(30)
Text("1 hour").tag(60)
}
.help("; ; How often; ; to refresh; ; device states; ; in the background")
}
}

Section(header: Text("Cache")) {
Picker("; ; Cache Expiration", selection: Binding(
get: { Int(config.deviceCacheExpiration / 60) },
set: { config.deviceCacheExpiration = TimeInterval($0 * 60) }
)) {
Text("30 minutes").tag(30)
Text("1 hour").tag(60)
Text("2 hours").tag(120)
Text("4 hours").tag(240)
}
.help("; ; How long; ; to keep; ; device states; ; in memory; ; before refreshing")
}
}
.navigationTitle("; ; Performance Settings")
}
}

//; ; Add this; ; struct for; ; file export support
s; truct SettingsDocument: FileDocument {
s; tatic var readableContentTypes: [UTType] { [.json] }

v; ar data: Data

init(data: Data) {
self.data = data
}

init(configuration: ReadConfiguration) throws {
g; uard let data = configuration.file.; ; regularFileContents else {
t; hrow CocoaError(.fileReadCorruptFile)
}
self.data = data
}

f; unc fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
r; eturn FileWrapper(regularFileWithContents: data)
}
} 