import SwiftUI
import Core

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