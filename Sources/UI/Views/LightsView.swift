import SwiftUI

struct LightsView: View {
    @ObservedObject var manager: YeelightManager
    @StateObject private var roomManager = RoomManager.shared
    @State private var selectedRoom: UUID?
    @AppStorage("lastUsedRoom") private var lastUsedRoom = "Living Room"
    @State private var isDiscovering = false
    @State private var showingRoomEditor = false
    @State private var error: YeelightManager.NetworkError?
    @State private var showingError = false
    @SceneStorage("LightsView.scrollPosition") private var scrollPosition: String?
    @State private var currentPage = 0
    @State private var isRefreshing = false
    @State private var searchText = ""
    
    private let devicesPerPage = 12
    private let refreshDebouncer = Debouncer(delay: 0.5)
    
    private var filteredDevices: [YeelightDevice] {
        let devices = selectedRoom.map { roomId in
            manager.devices.filter { $0.roomId == roomId }
        } ?? manager.devices
        
        guard !searchText.isEmpty else { return devices }
        
        return devices.filter { device in
            device.name.localizedCaseInsensitiveContains(searchText) ||
            device.ip.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var paginatedDevices: [YeelightDevice] {
        let startIndex = currentPage * devicesPerPage
        let endIndex = min(startIndex + devicesPerPage, filteredDevices.count)
        return Array(filteredDevices[startIndex..<endIndex])
    }
    
    private var totalPages: Int {
        (filteredDevices.count + devicesPerPage - 1) / devicesPerPage
    }
    
    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                VStack(spacing: 24) {
                    // Search bar
                    UnifiedSearchBar(
                        text: $searchText,
                        placeholder: "Search devices"
                    )
                    .padding(.horizontal)
                    
                    // Room selector
                    UnifiedTabSelector(
                        selection: Binding(
                            get: { selectedRoom ?? UUID() },
                            set: { selectedRoom = $0 == UUID() ? nil : $0 }
                        ),
                        tabs: [
                            .init("All Rooms", icon: "house.fill", tag: UUID()),
                        ] + roomManager.rooms.map { room in
                            .init(room.name, icon: room.icon, tag: room.id)
                        },
                        style: .pills
                    )
                    
                    if filteredDevices.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "lightbulb.slash")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            
                            Text(searchText.isEmpty ? "No devices found" : "No matching devices")
                                .font(.headline)
                            
                            Button(action: startDiscovery) {
                                Text("Discover Devices")
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        UnifiedGridView(
                            title: "My Lights",
                            items: paginatedDevices,
                            columns: Int(UIScreen.main.bounds.width / 160),
                            spacing: 16,
                            emptyStateMessage: "No devices found",
                            onRefresh: {
                                await refreshDevices()
                            }
                        ) { device in
                            DeviceCard(device: device)
                                .id(device.ip)
                                .onTapGesture {
                                    // Navigate to device detail
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("\(device.name) \(device.isOn ? "On" : "Off")")
                                .accessibilityValue("Brightness \(device.brightness)%")
                        }
                        .padding(.horizontal)
                    }
                }
                .onChange(of: selectedRoom) { _ in
                    currentPage = 0
                    withAnimation {
                        proxy.scrollTo(scrollPosition)
                    }
                }
                .onChange(of: searchText) { _ in
                    currentPage = 0
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search devices")
        .refreshable {
            isRefreshing = true
            await refreshDevices()
            isRefreshing = false
        }
        .overlay {
            if isDiscovering {
                ProgressView("Discovering devices...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
        .navigationTitle("My Lights")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { showingRoomEditor = true }) {
                        Label("Manage Rooms", systemImage: "folder")
                    }
                    .accessibilityLabel("Open room management")
                    
                    Button(action: startDiscovery) {
                        Label("Discover Devices", systemImage: "magnifyingglass")
                    }
                    .accessibilityLabel("Start device discovery")
                    
                    if let error = error {
                        Button(action: showErrorDetails) {
                            Label("Show Error Details", systemImage: "exclamationmark.triangle")
                        }
                        .accessibilityLabel("Show error details")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            startDiscovery()
        }
        .onChange(of: manager.devices) { _ in
            refreshDebouncer.debounce {
                Task {
                    await refreshDevices()
                }
            }
        }
        .alert("Error", isPresented: $showingError, presenting: error) { error in
            Button("OK", role: .cancel) {}
            Button("Retry") {
                startDiscovery()
            }
            if error.isNetworkError {
                Button("Network Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        } message: { error in
            Text(error.localizedDescription)
        }
        .sheet(isPresented: $showingRoomEditor) {
            RoomManagementView(roomManager: roomManager)
        }
    }
    
    private func showErrorDetails() {
        showingError = true
    }
    
    private func handleError(_ error: Error) {
        if let networkError = error as? YeelightManager.NetworkError {
            self.error = networkError
        } else {
            self.error = .discoveryFailed(error)
        }
        showingError = true
        
        // Log error for debugging
        Logger.shared.error("Device discovery error: \(error.localizedDescription)")
    }
    
    private func startDiscovery() {
        guard !isDiscovering else { return }
        isDiscovering = true
        
        Task {
            do {
                try await withTimeout(30) {
                    try await manager.startDiscovery()
                }
                error = nil
            } catch {
                handleError(error)
            }
            isDiscovering = false
        }
    }
    
    private func refreshDevices() async {
        do {
            try await withTimeout(10) {
                try await manager.refreshDevices()
            }
            error = nil
        } catch {
            handleError(error)
        }
    }
}

// MARK: - Supporting Views

struct DeviceCard: View {
    @ObservedObject var device: YeelightDevice
    @Environment(\.scenePhase) private var scenePhase
    private let haptics = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: device.isOn ? "lightbulb.fill" : "lightbulb")
                .font(.system(size: 40))
                .foregroundStyle(device.isOn ? .orange : .gray)
                .accessibilityLabel(device.isOn ? "Light is on" : "Light is off")
            
            VStack(spacing: 4) {
                Text(device.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(device.isOn ? "On" : "Off")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Brightness")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Slider(
                    value: Binding(
                        get: { Double(device.brightness) },
                        set: { newValue in
                            haptics.impactOccurred()
                            device.brightness = Int(newValue)
                        }
                    ),
                    in: 1...100,
                    step: 1
                )
                .accessibilityValue("\(device.brightness) percent")
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 5)
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task {
                    try? await device.updateState()
                }
            }
        }
    }
}

// MARK: - Supporting Types

class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    
    init(delay: TimeInterval) {
        self.delay = delay
    }
    
    func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        if let workItem = workItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }
}

#Preview {
    NavigationStack {
        LightsView(manager: YeelightManager.shared)
    }
} 