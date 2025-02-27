import SwiftUI

struct SettingsView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("debugMode") private var debugMode = false
    @AppStorage("logToFile") private var logToFile = false
    @AppStorage("autoDiscovery") private var autoDiscovery = true
    @AppStorage("discoveryInterval") private var discoveryInterval = 30.0
    
    @State private var showingBackupView = false
    @State private var showingRestoreView = false
    @State private var showingLogViewer = false
    @State private var showingAbout = false
    @State private var userNameError: String?
    
    private let userNameValidator = UserNameValidator()
    
    var body: some View {
        Form {
            Section("User Settings") {
                TextField("Your Name", text: $userName)
                    .autocorrectionDisabled()
                    .onChange(of: userName) { newValue in
                        userNameError = userNameValidator.validate(newValue)
                    }
                
                if let error = userNameError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                
                Toggle("Auto-Discovery", isOn: $autoDiscovery)
                
                if autoDiscovery {
                    VStack(alignment: .leading) {
                        Text("Discovery Interval: \(Int(discoveryInterval)) minutes")
                        Slider(value: $discoveryInterval, in: 5...60, step: 5)
                    }
                }
            }
            
            Section("Data Management") {
                Button(action: { showingBackupView = true }) {
                    Label("Backup Data", systemImage: "arrow.up.doc")
                }
                
                Button(action: { showingRestoreView = true }) {
                    Label("Restore Data", systemImage: "arrow.down.doc")
                }
            }
            
            Section("Advanced") {
                Toggle("Debug Mode", isOn: $debugMode)
                
                Toggle("Log to File", isOn: $logToFile)
                
                Button(action: { showingLogViewer = true }) {
                    Label("View Logs", systemImage: "doc.text.magnifyingglass")
                }
                .disabled(!debugMode)
                
                Button(action: { NetworkDiagnostics.saveReport() }) {
                    Label("Generate Diagnostic Report", systemImage: "waveform.path.ecg")
                }
            }
            
            Section {
                Button(action: { showingAbout = true }) {
                    Label("About YeelightControl", systemImage: "info.circle")
                }
                
                Link(destination: URL(string: "https://github.com/DanielKng/YeelightControl")!) {
                    Label("GitHub Repository", systemImage: "link")
                }
                
                Link(destination: URL(string: "https://www.yeelight.com/download/Yeelight_Inter-Operation_Spec.pdf")!) {
                    Label("Yeelight API Documentation", systemImage: "doc.text")
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

struct AboutView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
                
                Text("YeelightControl")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("A modern iOS app for controlling Yeelight smart lighting devices")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    InfoRow(label: "Version", value: "1.0.0")
                    InfoRow(label: "Build", value: "1")
                    InfoRow(label: "Developer", value: "Daniel Kng")
                    InfoRow(label: "License", value: "MIT")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                                Spacer()
                
                Text("© 2024 Daniel Kng. All rights reserved.")
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
                
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
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
        }
    }
    
    private func createBackup() {
        // Create backup data
        // This is a placeholder - actual implementation would depend on your data structure
        showingShareSheet = true
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
        }
    }
}

struct LogViewerView: View {
    @StateObject private var logger = Logger.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: Logger.LogEntry.Category?
    @State private var selectedLevel: Logger.LogEntry.Level?
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: "All Levels",
                            isSelected: selectedLevel == nil,
                            action: { selectedLevel = nil }
                        )
                        
                        ForEach(Logger.LogEntry.Level.allCases, id: \.self) { level in
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
                    ForEach(filteredLogs) { log in
                        LogEntryRow(entry: log)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search logs")
            .navigationTitle("Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive, action: { logger.clearLogs() }) {
                            Label("Clear Logs", systemImage: "trash")
                        }
                        
                        Button(action: exportLogs) {
                            Label("Export Logs", systemImage: "square.and.arrow.up")
                        }
                        
                        Menu("Filter Category") {
                            Button("All Categories") {
                                selectedCategory = nil
                            }
                            
                            Divider()
                            
                            ForEach(Logger.LogEntry.Category.allCases, id: \.self) { category in
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
    
    private var filteredLogs: [Logger.LogEntry] {
        var logs = logger.logs
        
        if let level = selectedLevel {
            logs = logs.filter { $0.level == level }
        }
        
        if let category = selectedCategory {
            logs = logs.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            logs = logs.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
        }
        
        return logs
    }
    
    private func exportLogs() {
        // Export logs functionality
    }
}

struct FilterChip: View {
    let title: String
    var color: Color = .primary
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
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

struct LogEntryRow: View {
    let entry: Logger.LogEntry
    
    var body: some View {
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

struct UserNameValidator {
    func validate(_ name: String) -> String? {
        if name.isEmpty {
            return nil
        }
        
        if name.count < 2 {
            return "Name must be at least 2 characters"
        }
        
        if name.count > 50 {
            return "Name must be less than 50 characters"
        }
        
        if name.contains(where: { !$0.isLetter && !$0.isWhitespace }) {
            return "Name can only contain letters and spaces"
        }
        
        return nil
    }
}

// MARK: - Backup

struct BackupManager {
    static let shared = BackupManager()
    
    private let keychain = KeychainWrapper.standard
    private let backupKey = "backupEncryptionKey"
    private let services: ServiceContainer
    
    struct BackupMetadata: Codable {
        let version: String
        let timestamp: Date
        let deviceCount: Int
        let sceneCount: Int
        let automationCount: Int
        let effectCount: Int
    }
    
    struct BackupData: Codable {
        let metadata: BackupMetadata
        let devices: [StoredDevice]
        let scenes: [Scene]
        let automations: [Automation]
        let effects: [EffectConfiguration]
        let settings: [String: ConfigValue]
    }
    
    init() {
        self.services = .shared
    }
    
    func createBackup() throws -> Data {
        // Get encryption key or generate new one
        let encryptionKey = keychain.string(forKey: backupKey) ?? generateEncryptionKey()
        
        // Load data from storage
        let devices: [StoredDevice] = try services.storage.load(forKey: .devices)
        let scenes: [Scene] = try services.storage.load(forKey: .scenes)
        let automations: [Automation] = try services.storage.load(forKey: .automations)
        let effects: [EffectConfiguration] = try services.storage.load(forKey: .effects)
        let settings: [String: ConfigValue] = try services.storage.load(forKey: .settings)
        
        // Prepare backup data
        let backup = BackupData(
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
        
        // Encode and encrypt
        let encoder = JSONEncoder()
        let data = try encoder.encode(backup)
        return try encrypt(data: data, using: encryptionKey)
    }
    
    func restoreBackup(_ data: Data) throws {
        // Get encryption key
        guard let encryptionKey = keychain.string(forKey: backupKey) else {
            throw BackupError.encryptionKeyNotFound
        }
        
        // Decrypt and decode
        let decryptedData = try decrypt(data: data, using: encryptionKey)
        let decoder = JSONDecoder()
        let backup = try decoder.decode(BackupData.self, from: decryptedData)
        
        // Restore data
        try services.storage.save(backup.devices, forKey: .devices)
        try services.storage.save(backup.scenes, forKey: .scenes)
        try services.storage.save(backup.automations, forKey: .automations)
        try services.storage.save(backup.effects, forKey: .effects)
        try services.storage.save(backup.settings, forKey: .settings)
    }
    
    private func generateEncryptionKey() -> String {
        let key = UUID().uuidString
        keychain.set(key, forKey: backupKey)
        return key
    }
    
    private func encrypt(data: Data, using key: String) throws -> Data {
        // Implementation for encryption
        // This would use CryptoKit or another encryption library
        fatalError("Encryption not implemented")
    }
    
    private func decrypt(data: Data, using key: String) throws -> Data {
        // Implementation for decryption
        // This would use CryptoKit or another encryption library
        fatalError("Decryption not implemented")
    }
}

enum BackupError: Error {
    case encryptionKeyNotFound
    case encryptionFailed
    case decryptionFailed
    case invalidBackupData
    case restoreFailed
    
    var localizedDescription: String {
        switch self {
        case .encryptionKeyNotFound:
            return "Encryption key not found"
        case .encryptionFailed:
            return "Failed to encrypt backup data"
        case .decryptionFailed:
            return "Failed to decrypt backup data"
        case .invalidBackupData:
            return "Invalid backup data format"
        case .restoreFailed:
            return "Failed to restore backup data"
        }
    }
}

extension String {
    func isCompatible(with version: String) -> Bool {
        // Compare major and minor versions
        let components1 = self.split(separator: ".")
        let components2 = version.split(separator: ".")
        
        guard components1.count >= 2, components2.count >= 2,
              let major1 = Int(components1[0]),
              let minor1 = Int(components1[1]),
              let major2 = Int(components2[0]),
              let minor2 = Int(components2[1]) else {
            return false
        }
        
        return major1 == major2 && minor1 <= minor2
    }
}

extension Bundle {
    var version: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

struct AdvancedSettingsSection: View {
    @StateObject private var config = ConfigurationManager.shared
    @State private var showingResetAlert = false
    @State private var showingPresetPicker = false
    @State private var showingImportPicker = false
    @State private var showingExportSheet = false
    @State private var importError: String?
    
    var body: some View {
        Section(header: Text("Advanced Settings")) {
            Menu {
                ForEach(ConfigurationManager.Preset.allCases, id: \.self) { preset in
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
                Label("Configuration Presets", systemImage: "slider.horizontal.3")
            }
            
            NavigationLink("Connection Settings") {
                ConnectionSettingsView()
            }
            
            NavigationLink("Logging Settings") {
                LoggingSettingsView()
            }
            
            NavigationLink("Discovery Settings") {
                DiscoverySettingsView()
            }
            
            NavigationLink("Performance Settings") {
                PerformanceSettingsView()
            }
            
            Button(action: { showingExportSheet = true }) {
                Label("Export Settings", systemImage: "square.and.arrow.up")
            }
            
            Button(action: { showingImportPicker = true }) {
                Label("Import Settings", systemImage: "square.and.arrow.down")
            }
            
            if let error = importError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            
            Button(action: {
                showingResetAlert = true
            }) {
                Text("Reset All Settings")
                    .foregroundColor(.red)
            }
        }
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                config.resetToDefaults()
            }
        } message: {
            Text("Are you sure you want to reset all settings to their default values?")
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    let data = try Data(contentsOf: url)
                    try config.importSettings(data)
                    importError = nil
                } catch {
                    importError = error.localizedDescription
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
        .fileExporter(
            isPresented: $showingExportSheet,
            document: SettingsDocument(data: config.exportSettings() ?? Data()),
            contentType: .json,
            defaultFilename: "yeelight_settings.json"
        ) { result in
            if case .failure(let error) = result {
                importError = error.localizedDescription
            }
        }
    }
    
    private func applyPreset(_ preset: ConfigurationManager.Preset) {
        config.applyPreset(preset)
    }
}

struct ConnectionSettingsView: View {
    @StateObject private var config = ConfigurationManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("Timeouts")) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Connection Timeout")
                        Spacer()
                        Text("\(Int(config.connectionTimeout))s")
                    }
                    Slider(value: $config.connectionTimeout, in: 5...30, step: 1)
                }
                .help("Maximum time to wait when connecting to a device")
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Retry Delay")
                        Spacer()
                        Text("\(Int(config.retryDelay))s")
                    }
                    Slider(value: $config.retryDelay, in: 1...10, step: 1)
                }
                .help("Time to wait before retrying a failed connection")
            }
            
            Section(header: Text("Retries")) {
                Stepper("Max Retries: \(config.maxConnectionRetries)", value: $config.maxConnectionRetries, in: 1...10)
                    .help("Maximum number of connection attempts before giving up")
            }
            
            Section(header: Text("Features")) {
                Toggle("Auto Reconnect", isOn: $config.enableAutoReconnect)
                    .tint(.accentColor)
                    .help("Automatically attempt to reconnect to devices when connection is lost")
            }
        }
        .navigationTitle("Connection Settings")
    }
}

struct LoggingSettingsView: View {
    @StateObject private var config = ConfigurationManager.shared
    
    private let fileSizeOptions = [1, 5, 10, 20, 50]
    private let fileCountOptions = [3, 5, 10, 15, 20]
    private let diskSpaceOptions = [50, 100, 200, 500, 1000]
    
    var body: some View {
        Form {
            Section(header: Text("File Size")) {
                Picker("Max Log File Size", selection: Binding(
                    get: { fileSizeOptions.firstIndex(of: config.maxLogFileSize / (1024 * 1024)) ?? 1 },
                    set: { config.maxLogFileSize = fileSizeOptions[$0] * 1024 * 1024 }
                )) {
                    ForEach(fileSizeOptions.indices, id: \.self) { index in
                        Text("\(fileSizeOptions[index]) MB").tag(index)
                    }
                }
                .help("Maximum size of each log file before rotation")
            }
            
            Section(header: Text("File Management")) {
                Picker("Max Log Files", selection: Binding(
                    get: { fileCountOptions.firstIndex(of: config.maxLogFiles) ?? 1 },
                    set: { config.maxLogFiles = fileCountOptions[$0] }
                )) {
                    ForEach(fileCountOptions.indices, id: \.self) { index in
                        Text("\(fileCountOptions[index]) files").tag(index)
                    }
                }
                .help("Number of log files to keep before deleting the oldest")
                
                Picker("Min Free Disk Space", selection: Binding(
                    get: { diskSpaceOptions.firstIndex(of: config.minDiskSpace / (1024 * 1024)) ?? 1 },
                    set: { config.minDiskSpace = diskSpaceOptions[$0] * 1024 * 1024 }
                )) {
                    ForEach(diskSpaceOptions.indices, id: \.self) { index in
                        Text("\(diskSpaceOptions[index]) MB").tag(index)
                    }
                }
                .help("Minimum free disk space to maintain")
            }
            
            Section(header: Text("Logging Level")) {
                Toggle("Detailed Logging", isOn: $config.enableDetailedLogging)
                    .tint(.accentColor)
                    .help("Enable verbose logging for debugging")
            }
        }
        .navigationTitle("Logging Settings")
    }
}

struct DiscoverySettingsView: View {
    @StateObject private var config = ConfigurationManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("Timeouts")) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Discovery Timeout")
                        Spacer()
                        Text("\(Int(config.discoveryTimeout))s")
                    }
                    Slider(value: $config.discoveryTimeout, in: 10...60, step: 5)
                }
                .help("Maximum time to spend searching for devices")
            }
            
            Section(header: Text("Intervals")) {
                Picker("Discovery Interval", selection: Binding(
                    get: { Int(config.discoveryInterval / 60) },
                    set: { config.discoveryInterval = TimeInterval($0 * 60) }
                )) {
                    Text("1 minute").tag(1)
                    Text("5 minutes").tag(5)
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("1 hour").tag(60)
                }
                .help("How often to automatically search for new devices")
            }
        }
        .navigationTitle("Discovery Settings")
    }
}

struct PerformanceSettingsView: View {
    @StateObject private var config = ConfigurationManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("Background Refresh")) {
                Toggle("Enable Background Refresh", isOn: $config.enableBackgroundRefresh)
                    .tint(.accentColor)
                    .help("Allow the app to update device states in the background")
                
                if config.enableBackgroundRefresh {
                    Picker("Refresh Interval", selection: Binding(
                        get: { Int(config.backgroundRefreshInterval / 60) },
                        set: { config.backgroundRefreshInterval = TimeInterval($0 * 60) }
                    )) {
                        Text("5 minutes").tag(5)
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                        Text("1 hour").tag(60)
                    }
                    .help("How often to refresh device states in the background")
                }
            }
            
            Section(header: Text("Cache")) {
                Picker("Cache Expiration", selection: Binding(
                    get: { Int(config.deviceCacheExpiration / 60) },
                    set: { config.deviceCacheExpiration = TimeInterval($0 * 60) }
                )) {
                    Text("30 minutes").tag(30)
                    Text("1 hour").tag(60)
                    Text("2 hours").tag(120)
                    Text("4 hours").tag(240)
                }
                .help("How long to keep device states in memory before refreshing")
            }
        }
        .navigationTitle("Performance Settings")
    }
}

// Add this struct for file export support
struct SettingsDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
} 