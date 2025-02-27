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
    
    var body: some View {
        Form {
            Section("User Settings") {
                TextField("Your Name", text: $userName)
                    .autocorrectionDisabled()
                
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