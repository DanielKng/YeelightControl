import SwiftUI

struct AdvancedSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var yeelightManager: YeelightManager
    @State private var powerOnBehavior: PowerOnBehavior = .stay
    @State private var powerOnBrightness: Double = 100
    @State private var powerOnColor: Color = .white
    @State private var powerOnTemp: Double = 4000
    @State private var showingResetAlert = false
    @State private var isLoading = false
    @State private var showingSuccessToast = false
    
    let device: YeelightDevice
    
    enum PowerOnBehavior: String, CaseIterable, Identifiable {
        case stay = "Stay"
        case on = "Turn On"
        case off = "Turn Off"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Power On Behavior") {
                    Picker("When powered on", selection: $powerOnBehavior) {
                        ForEach(PowerOnBehavior.allCases) { behavior in
                            Text(behavior.rawValue).tag(behavior)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if powerOnBehavior == .on {
                    Section("Power On Settings") {
                        VStack(alignment: .leading) {
                            Text("Brightness: \(Int(powerOnBrightness))%")
                            Slider(value: $powerOnBrightness, in: 1...100)
                        }
                        
                        ColorPicker("Color", selection: $powerOnColor)
                    }
                }
                
                Section("Device Information") {
                    HStack {
                        Text("IP Address")
                        Spacer()
                        Text(device.ip)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Firmware Version")
                        Spacer()
                        Text(device.firmwareVersion ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Model")
                        Spacer()
                        Text(device.model ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(role: .destructive, action: { showingResetAlert = true }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to Factory Settings")
                        }
                    }
                }
            }
            .navigationTitle("Advanced Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveSettings() }
                        .disabled(isLoading)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView("Saving settings...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }
                
                if showingSuccessToast {
                    VStack {
                        Spacer()
                        
                        Text("Settings saved successfully")
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .padding(.bottom, 20)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showingSuccessToast = false
                            }
                        }
                    }
                }
            }
            .alert("Reset Device", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) { resetDevice() }
            } message: {
                Text("This will reset the device to factory settings. This action cannot be undone.")
            }
        }
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    private func loadCurrentSettings() {
        // In a real app, we would load the current settings from the device
        // For now, we'll just use default values
        powerOnBehavior = .stay
        powerOnBrightness = 100
        powerOnColor = .white
        powerOnTemp = 4000
    }
    
    private func saveSettings() {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // In a real app, we would send the settings to the device
            
            isLoading = false
            withAnimation {
                showingSuccessToast = true
            }
            
            // Dismiss after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
        }
    }
    
    private func resetDevice() {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // In a real app, we would send the reset command to the device
            
            isLoading = false
            dismiss()
        }
    }
}

struct LogViewerView: View {
    @StateObject private var logger = Logger.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLevel: LogLevel?
    @State private var searchText = ""

    var filteredLogs: [LogEntry] {
        logger.logs.filter { log in
            let matchesSearch = searchText.isEmpty || 
            log.message.localizedCaseInsensitiveContains(searchText)
            let matchesLevel = selectedLevel == nil || log.level == selectedLevel
            return matchesSearch && matchesLevel
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and filter
                VStack(spacing: 8) {
                    UnifiedSearchBar(
                        text: $searchText,
                        placeholder: "Search logs"
                    )

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(LogLevel.allCases) { level in
                                FilterChip(
                                    title: level.rawValue.capitalized,
                                    isSelected: level == selectedLevel,
                                    action: {
                                        if selectedLevel == level {
                                            selectedLevel = nil
                                        } else {
                                            selectedLevel = level
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
                .background(.bar)

                // Log list
                UnifiedListView(
                    items: filteredLogs,
                    emptyStateMessage: "No logs found"
                ) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(log.message)
                            .font(.system(.body, design: .monospaced))

                        HStack {
                            Text(log.timestamp, style: .time)

                            Text("•")

                            Text(log.level.rawValue.uppercased())
                                .foregroundColor(log.level.color)
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        logger.clearLogs()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? .tint : .clear)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? .clear : .secondary.opacity(0.3), lineWidth: 1)
                }
        }
    }
}

extension LogLevel {
    var color: Color {
        switch self {
        case .debug: return .secondary
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}

extension Notification.Name {
    static let deviceSettingsReset = Notification.Name("deviceSettingsReset")
}

extension LogLevel: Identifiable {
    var id: String { rawValue }
} 