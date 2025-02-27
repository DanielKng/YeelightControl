import SwiftUI

struct AdvancedSettingsView: View {
    let device: YeelightDevice
    @StateObject private var deviceManager = YeelightManager.shared
    @State private var powerOnBehavior: PowerOnBehavior = .stay
    @State private var powerOnBrightness: Double = 100
    @State private var powerOnColor: Color = .white
    @State private var powerOnTemp: Double = 4000
    @State private var showingResetAlert = false
    @State private var isUpdating = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    enum PowerOnBehavior: String, CaseIterable {
        case stay = "Stay"
        case custom = "Custom"
        case lastUsed = "Last Used"
        
        var description: String {
            switch self {
            case .stay:
                return "Keep current settings"
            case .custom:
                return "Use custom settings"
            case .lastUsed:
                return "Restore last used settings"
            }
        }
    }
    
    var body: some View {
        Form {
            Section("Power On Behavior") {
                Picker("Behavior", selection: $powerOnBehavior) {
                    ForEach(PowerOnBehavior.allCases, id: \.self) { behavior in
                        Text(behavior.rawValue)
                            .tag(behavior)
                    }
                }
                
                if powerOnBehavior == .custom {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Brightness")
                            Spacer()
                            Text("\(Int(powerOnBrightness))%")
                        }
                        Slider(value: $powerOnBrightness, in: 1...100)
                    }
                    
                    ColorPicker("Color", selection: $powerOnColor)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text("\(Int(powerOnTemp))K")
                        }
                        Slider(value: $powerOnTemp, in: 1700...6500)
                    }
                }
                
                Text(powerOnBehavior.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Device Information") {
                LabeledContent("Model", value: device.model)
                LabeledContent("Firmware", value: device.firmwareVersion)
                LabeledContent("IP Address", value: device.ip)
                if let port = device.port {
                    LabeledContent("Port", value: "\(port)")
                }
            }
            
            Section("Advanced Options") {
                Button("Reset to Factory Settings") {
                    showingResetAlert = true
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Advanced Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Apply") {
                    applySettings()
                }
                .disabled(isUpdating)
            }
        }
        .alert("Reset Device?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetDevice()
            }
        } message: {
            Text("This will reset the device to factory settings. This action cannot be undone.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isUpdating {
                ProgressView("Updating settings...")
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(8)
            }
        }
    }
    
    private func applySettings() {
        isUpdating = true
        
        Task {
            do {
                switch powerOnBehavior {
                case .stay:
                    try await deviceManager.setPowerOnBehavior(device, mode: .stay)
                case .custom:
                    let components = UIColor(powerOnColor).cgColor.components ?? [1, 1, 1, 1]
                    try await deviceManager.setPowerOnBehavior(
                        device,
                        mode: .custom(
                            brightness: Int(powerOnBrightness),
                            red: Int(components[0] * 255),
                            green: Int(components[1] * 255),
                            blue: Int(components[2] * 255),
                            temperature: Int(powerOnTemp)
                        )
                    )
                case .lastUsed:
                    try await deviceManager.setPowerOnBehavior(device, mode: .lastUsed)
                }
                
                await MainActor.run {
                    isUpdating = false
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }
    
    private func resetDevice() {
        isUpdating = true
        
        Task {
            do {
                try await deviceManager.resetDevice(device)
                await MainActor.run {
                    isUpdating = false
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }
}

struct LogViewerView: View {
    @StateObject private var logger = Logger.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(logger.logs, id: \.timestamp) { log in
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.message)
                        .font(.system(.body, design: .monospaced))
                    
                    Text(log.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
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

// Notification for device settings reset
extension Notification.Name {
    static let deviceSettingsReset = Notification.Name("deviceSettingsReset")
}

enum LogLevel: String, CaseIterable, Identifiable {
    case debug
    case info
    case warning
    case error
    
    var id: String { rawValue }
} 