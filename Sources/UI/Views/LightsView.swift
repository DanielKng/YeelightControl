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
    
    private let refreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                VStack(spacing: 24) {
                    // Room selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            Button(action: { selectedRoom = nil }) {
                                RoomTab(
                                    icon: "house.fill",
                                    name: "All Rooms",
                                    isSelected: selectedRoom == nil
                                )
                            }
                            
                            ForEach(roomManager.rooms) { room in
                                Button(action: { selectedRoom = room.id }) {
                                    RoomTab(
                                        icon: room.icon,
                                        name: room.name,
                                        isSelected: selectedRoom == room.id
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Device grid
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 160), spacing: 16)
                    ], spacing: 16) {
                        ForEach(filteredDevices) { device in
                            DeviceCard(device: device)
                                .id(device.ip)
                                .onTapGesture {
                                    // Navigate to device detail
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: selectedRoom) { _ in
                    withAnimation {
                        proxy.scrollTo(scrollPosition)
                    }
                }
            }
        }
        .refreshable {
            await refreshDevices()
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
                    
                    Button(action: startDiscovery) {
                        Label("Discover Devices", systemImage: "magnifyingglass")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            startDiscovery()
        }
        .onReceive(refreshTimer) { _ in
            Task {
                await refreshDevices()
            }
        }
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button("OK", role: .cancel) {}
            Button("Retry") {
                startDiscovery()
            }
        } message: { error in
            Text(error.localizedDescription)
        }
        .sheet(isPresented: $showingRoomEditor) {
            RoomManagementView(roomManager: roomManager)
        }
    }
    
    private var filteredDevices: [YeelightDevice] {
        guard let selectedRoom = selectedRoom else {
            return manager.devices
        }
        
        guard let room = roomManager.rooms.first(where: { $0.id == selectedRoom }) else {
            return []
        }
        
        return manager.devices.filter { room.deviceIPs.contains($0.ip) }
    }
    
    private func startDiscovery() {
        isDiscovering = true
        
        Task {
            do {
                try await manager.startDiscovery()
            } catch let networkError as YeelightManager.NetworkError {
                error = networkError
                showingError = true
            } catch {
                error = .discoveryFailed(error)
                showingError = true
            }
            isDiscovering = false
        }
    }
    
    private func refreshDevices() async {
        do {
            try await manager.refreshDevices()
        } catch {
            self.error = .discoveryFailed(error)
            showingError = true
        }
    }
}

// MARK: - Supporting Views
struct RoomTab: View {
    let icon: String
    let name: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(name)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? .orange : Color(.systemGray6))
        .foregroundStyle(isSelected ? .white : .primary)
        .cornerRadius(20)
    }
}

struct DeviceCard: View {
    @ObservedObject var device: YeelightDevice
    
    var body: some View {
        VStack(spacing: 16) {
            // Device icon
            Image(systemName: device.isOn ? "lightbulb.fill" : "lightbulb")
                .font(.system(size: 40))
                .foregroundStyle(device.isOn ? .orange : .gray)
            
            // Device name and status
            VStack(spacing: 4) {
                Text(device.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(device.isOn ? "On" : "Off")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Brightness slider
            VStack(alignment: .leading, spacing: 4) {
                Text("Brightness")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Slider(
                    value: Binding(
                        get: { Double(device.brightness) },
                        set: { device.brightness = Int($0) }
                    ),
                    in: 1...100,
                    step: 1
                )
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

#Preview {
    NavigationStack {
        LightsView(manager: YeelightManager.shared)
    }
} 