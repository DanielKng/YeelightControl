import SwiftUI

struct MusicSyncView: View {
    @StateObject private var syncManager = MusicSyncManager.shared
    @StateObject private var deviceManager = YeelightManager.shared
    
    @State private var selectedMode = MusicSyncManager.SyncMode.amplitude
    @State private var selectedDevices: Set<String> = []
    @State private var colorPalette: [Color] = [.red, .green, .blue]
    @State private var sensitivity: Double = 0.5
    @State private var showingColorPicker = false
    @State private var editingColorIndex: Int?
    
    var body: some View {
        VStack(spacing: 24) {
            // Visualization
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGroupedBackground))
                
                VStack(spacing: 16) {
                    // Audio level meter
                    AudioLevelMeter(amplitude: syncManager.currentAmplitude)
                        .frame(height: 100)
                    
                    // Frequency spectrum
                    if selectedMode == .frequency {
                        FrequencySpectrum(frequency: syncManager.dominantFrequency)
                            .frame(height: 60)
                    }
                }
                .padding()
            }
            .frame(height: 200)
            
            // Settings
            Form {
                Section("Mode") {
                    Picker("Sync Mode", selection: $selectedMode) {
                        Text("Amplitude").tag(MusicSyncManager.SyncMode.amplitude)
                        Text("Frequency").tag(MusicSyncManager.SyncMode.frequency)
                        Text("Beat").tag(MusicSyncManager.SyncMode.beat)
                    }
                    .pickerStyle(.segmented)
                    
                    VStack(alignment: .leading) {
                        Text("Sensitivity")
                        Slider(value: $sensitivity)
                    }
                }
                
                Section("Colors") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(colorPalette.indices, id: \.self) { index in
                                ColorButton(color: colorPalette[index]) {
                                    editingColorIndex = index
                                    showingColorPicker = true
                                }
                            }
                            
                            if colorPalette.count < 5 {
                                Button(action: { colorPalette.append(.white) }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .listRowInsets(EdgeInsets())
                }
                
                Section("Devices") {
                    EnhancedDeviceSelectionList(selectedDevices: $selectedDevices)
                }
            }
            
            // Control button
            Button(action: toggleSync) {
                HStack {
                    Image(systemName: syncManager.isRunning ? "stop.fill" : "play.fill")
                    Text(syncManager.isRunning ? "Stop Sync" : "Start Sync")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(syncManager.isRunning ? .red : .orange)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            .padding()
            .disabled(selectedDevices.isEmpty)
        }
        .navigationTitle("Music Sync")
        .sheet(isPresented: $showingColorPicker) {
            if let index = editingColorIndex {
                ColorPicker("Select Color", selection: $colorPalette[index])
                    .presentationDetents([.height(400)])
            }
        }
        .onDisappear {
            if syncManager.isRunning {
                syncManager.stop()
            }
        }
    }
    
    private func toggleSync() {
        if syncManager.isRunning {
            syncManager.stop()
        } else {
            syncManager.start(mode: selectedMode, colors: colorPalette)
        }
    }
}

struct AudioLevelMeter: View {
    let amplitude: Float
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<30) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: index))
                        .frame(width: (geometry.size.width - 58) / 30,
                               height: barHeight(for: index, in: geometry))
                }
            }
        }
    }
    
    private func barHeight(for index: Int, in geometry: GeometryProxy) -> CGFloat {
        let threshold = Float(index) / 30.0
        let height = amplitude > threshold ?
            CGFloat(amplitude - threshold) * geometry.size.height :
            0
        return max(3, min(height, geometry.size.height))
    }
    
    private func barColor(for index: Int) -> Color {
        let threshold = Float(index) / 30.0
        if amplitude > threshold {
            return .orange
        } else {
            return .secondary.opacity(0.2)
        }
    }
}

struct FrequencySpectrum: View {
    let frequency: Float
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Dominant Frequency")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("\(Int(frequency)) Hz")
                .font(.title2)
                .monospacedDigit()
            
            // Frequency range indicator
            GeometryReader { geometry in
                Rectangle()
                    .fill(.orange)
                    .frame(width: 4)
                    .offset(x: CGFloat(frequency / 2000) * geometry.size.width)
            }
        }
    }
}

struct ColorButton: View {
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
                .overlay {
                    Circle()
                        .stroke(.white, lineWidth: 2)
                }
        }
    }
} 