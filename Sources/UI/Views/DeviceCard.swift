import SwiftUI
import Combine

struct DeviceCard: View {
    enum CardSize {
        case small, medium, large
    }
    
    @ObservedObject var device: YeelightDevice
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    @StateObject private var brightnessController: DevicePropertyController
    @StateObject private var powerController: DevicePropertyController
    @State private var showingErrorAlert = false
    @State private var isUpdating = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(device.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(device.model.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Power button
                Button(action: togglePower) {
                    Image(systemName: device.isOn ? "power" : "power")
                        .font(.title2)
                        .foregroundColor(device.isOn ? .green : .red)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!device.state.isOnline || isUpdating)
            }
            
            // Brightness slider
            if device.isOn {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Brightness")
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(Int(device.brightness))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "sun.min")
                            .font(.caption)
                        
                        Slider(value: $brightnessController.value, in: 1...100)
                            .disabled(!device.state.isOnline || isUpdating)
                        
                        Image(systemName: "sun.max")
                            .font(.caption)
                    }
                }
            }
            
            // Status indicator
            HStack {
                if !device.state.isOnline {
                    Label("Offline", systemImage: "wifi.slash")
                        .font(.caption)
                        .foregroundColor(.red)
                } else if isUpdating {
                    Label("Updating", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Label("Online", systemImage: "wifi")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Text(device.ip)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .alert(isPresented: $showingErrorAlert) {
            Alert(
                title: Text("Connection Error"),
                message: Text("Could not connect to the device. Please check if it's powered on and connected to the network."),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            setupControllers()
        }
    }
    
    init(device: YeelightDevice) {
        self.device = device
        
        // Initialize controllers
        _brightnessController = StateObject(wrappedValue: DevicePropertyController(
            initialValue: device.brightness,
            debounceTime: 0.3
        ))
        
        _powerController = StateObject(wrappedValue: DevicePropertyController(
            initialValue: device.isOn ? 1.0 : 0.0,
            debounceTime: 0.1
        ))
    }
    
    private func setupControllers() {
        // Brightness controller
        brightnessController.valuePublisher
            .sink { [weak self] brightness in
                guard let self = self, self.device.brightness != brightness else { return }
                self.isUpdating = true
                
                Task {
                    do {
                        try await self.device.setBrightness(Int(brightness))
                    } catch {
                        self.showingErrorAlert = true
                    }
                    
                    DispatchQueue.main.async {
                        self.isUpdating = false
                    }
                }
            }
            .store(in: &brightnessController.cancellables)
        
        // Update controller values when device changes
        device.objectWillChange
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if !self.isUpdating {
                    self.brightnessController.value = self.device.brightness
                    self.powerController.value = self.device.isOn ? 1.0 : 0.0
                }
            }
            .store(in: &brightnessController.cancellables)
    }
    
    private func togglePower() {
        isUpdating = true
        
        Task {
            do {
                if device.isOn {
                    try await device.turnOff()
                } else {
                    try await device.turnOn()
                }
            } catch {
                showingErrorAlert = true
            }
            
            DispatchQueue.main.async {
                self.isUpdating = false
            }
        }
    }
}

struct ConnectionStatusView: View {
    let state: YeelightDevice.ConnectionState

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.caption)
                .foregroundColor(statusColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Connection status: \(statusText)")
    }

    private var statusColor: Color {
        switch state {
        case .connected:
            return .green
        case .connecting:
            return .yellow
        case .disconnected:
            return .gray
        case .error:
            return .red
        }
    }

    private var statusText: String {
        switch state {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .error:
            return "Connection Error"
        }
    }
}

class DevicePropertyController: ObservableObject {
    private var value: Any
    private var cancellable: AnyCancellable?
    private let debounceInterval: TimeInterval
    private let subject = PassthroughSubject<Any, Never>()

    init(initialValue: Any, debounceInterval: TimeInterval) {
        self.value = initialValue
        self.debounceInterval = debounceInterval
    }

    func updateValue<T>(_ newValue: T, completion: @escaping (T) -> Void) {
        subject.send(newValue)

        if cancellable == nil {
            cancellable = subject
                .debounce(for: .seconds(debounceInterval), scheduler: DispatchQueue.main)
                .sink { [weak self] value in
                    guard let value = value as? T else { return }
                    self?.value = value
                    completion(value)
                }
        }
    }

    var valuePublisher: AnyPublisher<Any, Never> {
        subject.eraseToAnyPublisher()
    }
} 