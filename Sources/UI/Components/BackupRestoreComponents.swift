import SwiftUI
import Core

/// View for backing up app data
public struct BackupView: View {
    @EnvironmentObject private var storageManager: UnifiedStorageManager
    @Environment(\.dismiss) private var dismiss
    @State private var backupName = ""
    @State private var includeDevices = true
    @State private var includeScenes = true
    @State private var includeSettings = true
    @State private var isBackingUp = false
    @State private var showingSuccess = false
    @State private var errorMessage: String?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Backup Details")) {
                    TextField("Backup Name", text: $backupName)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Include in Backup")) {
                    Toggle("Devices", isOn: $includeDevices)
                    Toggle("Scenes", isOn: $includeScenes)
                    Toggle("Settings", isOn: $includeSettings)
                }
                
                Section(footer: Text("Backups are stored locally on your device.")) {
                    Button(action: performBackup) {
                        if isBackingUp {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Text("Create Backup")
                        }
                    }
                    .disabled(backupName.isEmpty || isBackingUp || (!includeDevices && !includeScenes && !includeSettings))
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .disabled(isBackingUp)
            .alert("Backup Complete", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your backup has been created successfully.")
            }
            .alert("Backup Failed", isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
        }
    }
    
    private func performBackup() {
        guard !backupName.isEmpty else { return }
        
        isBackingUp = true
        
        Task {
            do {
                // In a real implementation, this would call the storage manager
                // For now, we'll just simulate a backup
                try await Task.sleep(for: .seconds(2))
                
                await MainActor.run {
                    isBackingUp = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isBackingUp = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

/// View for restoring app data from a backup
public struct RestoreView: View {
    @EnvironmentObject private var storageManager: UnifiedStorageManager
    @Environment(\.dismiss) private var dismiss
    @State private var backups: [BackupInfo] = []
    @State private var selectedBackup: BackupInfo?
    @State private var isLoading = true
    @State private var isRestoring = false
    @State private var showingConfirmation = false
    @State private var showingSuccess = false
    @State private var errorMessage: String?
    
    public struct BackupInfo: Identifiable {
        public let id: String
        public let name: String
        public let date: Date
        public let size: Int
        
        public var formattedSize: String {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useKB, .useMB]
            formatter.countStyle = .file
            return formatter.string(fromByteCount: Int64(size))
        }
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else if backups.isEmpty {
                    ContentUnavailableView(
                        "No Backups Found",
                        systemImage: "archivebox",
                        description: Text("You haven't created any backups yet.")
                    )
                } else {
                    List {
                        ForEach(backups) { backup in
                            Button(action: {
                                selectedBackup = backup
                                showingConfirmation = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(backup.name)
                                            .font(.headline)
                                        
                                        Text(backup.date, style: .date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(backup.formattedSize)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deleteBackups)
                    }
                }
            }
            .navigationTitle("Restore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !backups.isEmpty {
                        EditButton()
                    }
                }
            }
            .onAppear {
                loadBackups()
            }
            .disabled(isRestoring)
            .alert("Confirm Restore", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) {
                    selectedBackup = nil
                }
                
                Button("Restore", role: .destructive) {
                    if let backup = selectedBackup {
                        restoreBackup(backup)
                    }
                }
            } message: {
                if let backup = selectedBackup {
                    Text("Are you sure you want to restore from '\(backup.name)'? This will replace your current data and cannot be undone.")
                } else {
                    Text("Please select a backup to restore.")
                }
            }
            .alert("Restore Complete", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your data has been restored successfully. The app will now restart.")
            }
            .alert("Restore Failed", isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
        }
    }
    
    private func loadBackups() {
        isLoading = true
        
        // In a real implementation, this would load backups from the storage manager
        // For now, we'll just create some sample backups
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.backups = [
                BackupInfo(id: "1", name: "Weekly Backup", date: Date().addingTimeInterval(-7*24*60*60), size: 1024*1024),
                BackupInfo(id: "2", name: "Before Update", date: Date().addingTimeInterval(-30*24*60*60), size: 2048*1024),
                BackupInfo(id: "3", name: "Initial Setup", date: Date().addingTimeInterval(-90*24*60*60), size: 512*1024)
            ]
            self.isLoading = false
        }
    }
    
    private func deleteBackups(at offsets: IndexSet) {
        // In a real implementation, this would delete backups from the storage manager
        backups.remove(atOffsets: offsets)
    }
    
    private func restoreBackup(_ backup: BackupInfo) {
        isRestoring = true
        
        Task {
            do {
                // In a real implementation, this would call the storage manager
                // For now, we'll just simulate a restore
                try await Task.sleep(for: .seconds(2))
                
                await MainActor.run {
                    isRestoring = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isRestoring = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
} 