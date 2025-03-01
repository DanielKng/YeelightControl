import SwiftUI
import Core

struct AdvancedSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var yeelightManager: ObservableYeelightManager
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

struct UnifiedSearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct UnifiedListView<T: Identifiable, Content: View>: View {
    let items: [T]
    let emptyStateMessage: String
    let content: (T) -> Content
    
    var body: some View {
        if items.isEmpty {
            ContentUnavailableView {
                Label(emptyStateMessage, systemImage: "doc.text")
            }
        } else {
            List {
                ForEach(items) { item in
                    content(item)
                }
            }
            .listStyle(.plain)
        }
    }
}

extension Notification.Name {
    static let deviceSettingsReset = Notification.Name("deviceSettingsReset")
}

extension LogLevel: Identifiable {
    var id: String { rawValue }
} 