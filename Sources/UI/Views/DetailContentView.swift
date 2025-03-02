import SwiftUI
import Core

// This file contains the detailed content view for the Yeelight Control app

struct DetailContentView: View {
    @EnvironmentObject private var yeelightManager: ObservableYeelightManager
    @State private var isDiscovering = false
    @State private var showingHelp = false
    @State private var showingError: Error?
    @State private var selectedDevice: YeelightDevice?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if yeelightManager.devices.isEmpty {
                    EmptyStateView(isDiscovering: $isDiscovering)
                } else {
                    List {
                        Section {
                            ForEach(yeelightManager.devices) { device in
                                DeviceRow(device: device) {
                                    selectedDevice = device
                                }
                            }
                        } header: {
                            HStack {
                                Text("Devices")
                                Spacer()
                                if isDiscovering {
                                    ProgressView()
                                        .padding(.trailing, 8)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await startDiscovery()
                    }
                }
            }
            .navigationTitle("Yeelight Control")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingHelp = true }) {
                        Image(systemName: "questionmark.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if isDiscovering {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        
                        Menu {
                            Button(action: { Task { await startDiscovery() } }) {
                                Label("Discover Devices", systemImage: "magnifyingglass")
                            }
                            
                            Button(action: { clearDevices() }) {
                                Label("Clear All Devices", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
            .sheet(item: $selectedDevice) { device in
                NavigationStack {
                    DeviceDetailView(device: device)
                }
            }
            .alert("Error", isPresented: .constant(showingError != nil), presenting: showingError) { _ in
                Button("OK") { showingError = nil }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
        .task {
            await startDiscovery()
        }
    }
    
    private func startDiscovery() async {
        isDiscovering = true
        do {
            try await yeelightManager.discoverDevices()
        } catch {
            showingError = error
        }
        isDiscovering = false
    }
    
    private func clearDevices() {
        yeelightManager.clearDevices()
    }
}

struct DetailContentView_Previews: PreviewProvider {
    static var previews: some View {
        DetailContentView()
            .environmentObject(ServiceContainer.shared.observableYeelightManager)
    }
}

struct EmptyStateView: View {
    @Binding var isDiscovering: Bool
    @EnvironmentObject private var yeelightManager: ObservableYeelightManager
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "lightbulb.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Devices Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Make sure your Yeelight devices are on the same network and have LAN Control enabled.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Button(action: {
                Task {
                    await yeelightManager.discoverDevices()
                }
            }) {
                HStack {
                    Text("Discover Devices")
                    if isDiscovering {
                        ProgressView()
                    }
                }
                .frame(minWidth: 200)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isDiscovering)
            
            Spacer()
        }
    }
}

// Remove the DeviceRow struct since we're using the centralized component

// Remove the DeviceDetailView struct since we're using the centralized component 