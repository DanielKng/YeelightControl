import SwiftUI
import Core

struct AutomationView: View {
    // MARK: - Properties
    
    @EnvironmentObject private var automationManager: ObservableAutomationManager
    @EnvironmentObject private var yeelightManager: ObservableYeelightManager
    
    // State variables
    @State private var searchText = ""
    @State private var showingAddAutomation = false
    @State private var selectedAutomation: Automation?
    @State private var showingDeleteAlert = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                // Automations list
                ForEach(filteredAutomations) { automation in
                    AutomationRow(automation: automation)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedAutomation = automation
                        }
                }
                .onDelete { indexSet in
                    if let index = indexSet.first {
                        selectedAutomation = automationManager.automations[index]
                        showingDeleteAlert = true
                    }
                }
            }
            .overlay {
                if automationManager.automations.isEmpty {
                    ContentUnavailableView(
                        "No automations created yet",
                        systemImage: "clock.arrow.2.circlepath",
                        description: Text("Tap the + button to create your first automation")
                    )
                } else if filteredAutomations.isEmpty {
                    ContentUnavailableView.search
                }
            }
            .navigationTitle("Automations")
            .searchable(text: $searchText, prompt: "Search automations")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddAutomation = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAutomation) {
                NavigationStack {
                    AutomationCreationView()
                }
                .presentationDetents([.large])
            }
            .sheet(item: $selectedAutomation) { automation in
                NavigationStack {
                    AutomationDetailView(automation: automation)
                }
                .presentationDetents([.large])
            }
            .alert("Delete Automation", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    selectedAutomation = nil
                }
                Button("Delete", role: .destructive) {
                    if let automation = selectedAutomation {
                        automationManager.removeAutomation(automation)
                        selectedAutomation = nil
                    }
                }
            } message: {
                Text("Are you sure you want to delete this automation? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredAutomations: [Automation] {
        if searchText.isEmpty {
            return automationManager.automations
        } else {
            return automationManager.automations.filter { automation in
                automation.name.localizedCaseInsensitiveContains(searchText) ||
                automation.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct AutomationRow: View {
    let automation: Automation
    @EnvironmentObject private var automationManager: ObservableAutomationManager
    
    var body: some View {
        HStack {
            // Icon
            ZStack {
                Circle()
                    .fill(automation.isEnabled ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconForTrigger(automation.trigger))
                    .foregroundColor(automation.isEnabled ? .accentColor : .gray)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(automation.name)
                    .font(.headline)
                
                Text(automation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Device chips
                if !automation.actions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(automation.actions) { action in
                                if case .device(let deviceID, _) = action.type {
                                    DeviceChip(deviceID: deviceID)
                                }
                            }
                        }
                    }
                    .frame(height: 24)
                }
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: Binding(
                get: { automation.isEnabled },
                set: { newValue in
                    automationManager.toggleAutomation(automation, enabled: newValue)
                }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
    
    private func iconForTrigger(_ trigger: AutomationTrigger) -> String {
        switch trigger.type {
        case .time:
            return "clock"
        case .sunrise, .sunset:
            return "sun.horizon"
        case .deviceState:
            return "lightbulb"
        case .location:
            return "location"
        case .networkEvent:
            return "wifi"
        }
    }
}

struct DeviceChip: View {
    let deviceID: DeviceID
    @EnvironmentObject private var yeelightManager: ObservableYeelightManager
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.orange)
                .frame(width: 8, height: 8)
            
            Text(deviceName)
                .font(.caption2)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    private var deviceName: String {
        if let device = yeelightManager.getDevice(id: deviceID) {
            return device.name
        } else {
            return "Unknown"
        }
    }
}

// MARK: - Preview

#Preview {
NavigationView {
AutomationView()
.environmentObject(ServiceContainer.shared.automationManager)
.environmentObject(ServiceContainer.shared.yeelightManager)
}
} 