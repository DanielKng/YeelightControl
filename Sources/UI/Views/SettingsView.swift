import SwiftUI

struct SettingsView: View {
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("autoDiscovery") private var autoDiscovery: Bool = true
    @AppStorage("discoveryInterval") private var discoveryInterval: Double = 60
    @AppStorage("theme") private var theme: String = "system"
    @AppStorage("showDebugInfo") private var showDebugInfo: Bool = false
    @AppStorage("analyticsEnabled") private var analyticsEnabled: Bool = true
    
    @State private var showingBackupView = false
    @State private var showingRestoreView = false
    @State private var showingLogViewer = false
    @State private var showingAbout = false
    @State private var userNameError: String?
    
    private let userNameValidator = UserNameValidator()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Your Name", text: $userName)
                        .onChange(of: userName) { newValue in
                            userNameError = userNameValidator.validate(name: newValue)
                        }
                    
                    if let error = userNameError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Section("Discovery") {
                    Toggle("Auto-discover devices", isOn: $autoDiscovery)
                    
                    if autoDiscovery {
                        VStack(alignment: .leading) {
                            Text("Discovery interval: \(Int(discoveryInterval)) seconds")
                            Slider(value: $discoveryInterval, in: 30...300, step: 30)
                        }
                    }
                }
                
                Section("Appearance") {
                    Picker("Theme", selection: $theme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
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
                    Toggle("Show Debug Information", isOn: $showDebugInfo)
                    
                    Button(action: { showingLogViewer = true }) {
                        Label("View Logs", systemImage: "doc.text.magnifyingglass")
                    }
                    
                    Toggle("Analytics", isOn: $analyticsEnabled)
                        .onChange(of: analyticsEnabled) { newValue in
                            // In a real app, you would enable/disable analytics here
                        }
                }
                
                Section {
                    Button(action: { showingAbout = true }) {
                        Label("About", systemImage: "info.circle")
                    }
                }
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
}

struct AboutView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 16) {
                        Image("AppIcon")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .cornerRadius(20)
                        
                        Text("Yeelight Control")
                            .font(.title2)
                            .bold()
                        
                        Text("A modern iOS app for controlling Yeelight smart lighting devices")
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Version \(Bundle.main.version)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                
                Section("Developer") {
                    InfoRow(title: "Developer", value: "Your Name")
                    InfoRow(title: "Website", value: "yourwebsite.com")
                    InfoRow(title: "Contact", value: "contact@yourwebsite.com")
                }
                
                Section("Legal") {
                    InfoRow(title: "License", value: "MIT")
                    InfoRow(title: "Privacy Policy", value: "Tap to View")
                    InfoRow(title: "Terms of Use", value: "Tap to View")
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let action: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action?()
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
                    .foregroundColor(.accentColor)
                
                Text("Backup Your Data")
                    .font(.title2)
                    .bold()
                
                Text("This will create a backup file containing all your scenes, groups, automations, and settings.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    createBackup()
                    showingShareSheet = true
                }) {
                    Text("Create Backup")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func createBackup() {
        // In a real app, you would create a backup of the user's data here
        // This is a placeholder - actual implementation would depend on your data structure
        backupData = "Sample backup data".data(using: .utf8)
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
                    .foregroundColor(.accentColor)
                
                Text("Restore Your Data")
                    .font(.title2)
                    .bold()
                
                Text("Select a backup file to restore your scenes, groups, automations, and settings.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    showingFilePicker = true
                }) {
                    Text("Select Backup File")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                if let error = restoreError {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
            .navigationTitle("Restore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
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
                // Search and filter
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search logs", text: $searchText)
                            .textFieldStyle(.plain)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Level filters
                            ForEach(Logger.LogEntry.Level.allCases, id: \.self) { level in
                                FilterChip(
                                    title: level.rawValue.uppercased(),
                                    isSelected: selectedLevel == level,
                                    color: level.color
                                ) {
                                    if selectedLevel == level {
                                        selectedLevel = nil
                                    } else {
                                        selectedLevel = level
                                    }
                                }
                            }
                            
                            Divider()
                                .frame(height: 24)
                            
                            // Category filters
                            ForEach(Logger.LogEntry.Category.allCases, id: \.self) { category in
                                FilterChip(
                                    title: category.rawValue.capitalized,
                                    isSelected: selectedCategory == category
                                ) {
                                    if selectedCategory == category {
                                        selectedCategory = nil
                                    } else {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                // Log list
                List {
                    ForEach(filteredLogs) { entry in
                        LogEntryRow(entry: entry)
                    }
                }
            }
            .navigationTitle("Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { logger.clearLogs() }) {
                            Label("Clear Logs", systemImage: "trash")
                        }
                        
                        Button(action: { exportLogs() }) {
                            Label("Export Logs", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private var filteredLogs: [Logger.LogEntry] {
        var logs = logger.logs
        
        // Apply level filter
        if let level = selectedLevel {
            logs = logs.filter { $0.level == level }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            logs = logs.filter { $0.category == category }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            logs = logs.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
        }
        
        return logs
    }
    
    private func exportLogs() {
        // In a real app, you would export the logs to a file here
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color.clear)
                .foregroundColor(isSelected ? .white : color)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color, lineWidth: isSelected ? 0 : 1)
                )
        }
    }
}

struct LogEntryRow: View {
    let entry: Logger.LogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(entry.level.rawValue.uppercased())
                    .font(.caption2.bold())
                    .foregroundColor(entry.level.color)
                
                Text(entry.category.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray6))
                    .cornerRadius(4)
            }
            
            Text(entry.message)
                .font(.callout)
                .lineLimit(nil)
        }
        .padding(.vertical, 4)
    }
}

struct UserNameValidator {
    func validate(name: String) -> String? {
        if name.isEmpty {
            return nil // Empty name is allowed
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
        
        return nil // Valid name
    }
}

struct BackupManager {
    static let shared = BackupManager()
    
    private let keychain = KeychainWrapper.standard
    private let backupKey = "backupEncryptionKey"
    private let services: BaseServiceContainer
    
    struct BackupMetadata: Codable {
        let version: String
        let createdAt: Date
        let deviceName: String
        let appVersion: String
    }
    
    struct BackupData: Codable {
        let metadata: BackupMetadata
        let scenes: [SceneData]
        let groups: [GroupData]
        let automations: [AutomationData]
        let settings: SettingsData
        
        struct SceneData: Codable {
            let id: String
            let name: String
            let deviceIDs: [String]
            // Other scene properties
        }
        
        struct GroupData: Codable {
            let id: String
            let name: String
            let deviceIDs: [String]
            // Other group properties
        }
        
        struct AutomationData: Codable {
            let id: String
            let name: String
            let isEnabled: Bool
            // Other automation properties
        }
        
        struct SettingsData: Codable {
            let theme: String
            let autoDiscovery: Bool
            let discoveryInterval: Double
            // Other settings
        }
    }
    
    init(services: BaseServiceContainer = ServiceContainer.shared) {
        self.services = services
    }
    
    func createBackup() throws -> Data {
        // Get encryption key or generate a new one
        let encryptionKey = keychain.string(forKey: backupKey) ?? generateEncryptionKey()
        
        // Save the key if it's new
        if keychain.string(forKey: backupKey) == nil {
            keychain.set(encryptionKey, forKey: backupKey)
        }
        
        // Create backup data
        let metadata = BackupMetadata(
            version: "1.0",
            createdAt: Date(),
            deviceName: UIDevice.current.name,
            appVersion: Bundle.main.version
        )
        
        // In a real app, you would get this data from your data stores
        let backupData = BackupData(
            metadata: metadata,
            scenes: [],
            groups: [],
            automations: [],
            settings: BackupData.SettingsData(
                theme: "system",
                autoDiscovery: true,
                discoveryInterval: 60
            )
        )
        
        // Encode the data
        let jsonData = try JSONEncoder().encode(backupData)
        
        // Encrypt the data
        return try encrypt(data: jsonData, using: encryptionKey)
    }
    
    func restoreBackup(from data: Data) throws {
        guard let encryptionKey = keychain.string(forKey: backupKey) else {
            throw BackupError.missingEncryptionKey
        }
        
        // Decrypt the data
        let jsonData = try decrypt(data: data, using: encryptionKey)
        
        // Decode the data
        let backupData = try JSONDecoder().decode(BackupData.self, from: jsonData)
        
        // In a real app, you would restore the data to your data stores
        
        // Log the restore
        services.logger.info("Restored backup from \(backupData.metadata.createdAt)", category: .data)
    }
    
    private func generateEncryptionKey() -> String {
        // In a real app, you would use a secure random generator
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<32).map { _ in letters.randomElement()! })
    }
    
    private func encrypt(data: Data, using key: String) throws -> Data {
        // In a real app, you would use proper encryption
        // This is just a placeholder
        return data
    }
    
    private func decrypt(data: Data, using key: String) throws -> Data {
        // In a real app, you would use proper decryption
        // This is just a placeholder
        return data
    }
}

enum BackupError: Error {
    case missingEncryptionKey
    case encryptionFailed
    case decryptionFailed
    case invalidData
    
    var localizedDescription: String {
        switch self {
        case .missingEncryptionKey:
            return "Encryption key not found"
        case .encryptionFailed:
            return "Failed to encrypt backup data"
        case .decryptionFailed:
            return "Failed to decrypt backup data"
        case .invalidData:
            return "Invalid backup data format"
        }
    }
}

extension String {
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        } else {
            return self
        }
    }
    
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
}

extension Bundle {
    var version: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
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
        Section("Advanced") {
            Toggle("Developer Mode", isOn: $config.developerMode)
                .onChange(of: config.developerMode) { newValue in
                    if newValue {
                        // Enable additional logging or features
                    }
                }
            
            if config.developerMode {
                Button(action: { showingPresetPicker = true }) {
                    Label("Load Configuration Preset", systemImage: "square.and.arrow.down")
                }
                
                Button(action: { showingImportPicker = true }) {
                    Label("Import Configuration", systemImage: "doc.badge.plus")
                }
                
                Button(action: { showingExportSheet = true }) {
                    Label("Export Configuration", systemImage: "square.and.arrow.up")
                }
            }
            
            Button(role: .destructive, action: { showingResetAlert = true }) {
                Label("Reset All Settings", systemImage: "trash")
                    .foregroundColor(.red)
            }
        }
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                config.resetToDefaults()
            }
        } message: {
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
    }
} 