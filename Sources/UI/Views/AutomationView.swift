import SwiftUI

struct AutomationView: View {
    // MARK: - Environment
    
    @EnvironmentObject private var automationManager: UnifiedAutomationManager
    @EnvironmentObject private var yeelightManager: UnifiedYeelightManager
    
    // MARK: - State
    
    @State private var showingAddAutomation = false
    @State private var selectedAutomation: Automation?
    @State private var showingDeleteAlert = false
    
    // MARK: - Body
    
    var body: some View {
        List {
            Section {
                ForEach(automationManager.automations) { automation in
                    AutomationRow(automation: automation) {
                        selectedAutomation = automation
                    }
                }
                .onDelete { indexSet in
                    if let index = indexSet.first {
                        selectedAutomation = automationManager.automations[index]
                        showingDeleteAlert = true
                    }
                }
            } header: {
                if automationManager.automations.isEmpty {
                    Text("No automations created yet")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Automations")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddAutomation = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddAutomation) {
            NavigationView {
                CreateAutomationView(devices: yeelightManager.devices)
            }
        }
        .sheet(item: $selectedAutomation) { automation in
            NavigationView {
                AutomationEditor(automation: automation, devices: yeelightManager.devices)
            }
        }
        .alert("Delete Automation", isPresented: $showingDeleteAlert, presenting: selectedAutomation) { automation in
            Button("Delete", role: .destructive) {
                automationManager.deleteAutomation(automation)
                selectedAutomation = nil
            }
            Button("Cancel", role: .cancel) {
                selectedAutomation = nil
            }
        } message: { automation in
            Text("Are you sure you want to delete '\(automation.name)'?")
        }
    }
}

// MARK: - Supporting Views

struct AutomationRow: View {
    let automation: Automation
    let onEdit: () -> Void
    
    var body: some View {
        Button {
            onEdit()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: automation.trigger.icon)
                            .foregroundColor(.accentColor)
                        
                        Text(automation.name)
                            .font(.headline)
                        
                        Spacer()
                        
                        Toggle("", isOn: .constant(automation.isEnabled))
                            .labelsHidden()
                    }
                    
                    Text(automation.trigger.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !automation.devices.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(automation.devices) { device in
                                    DeviceChip(device: device)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

struct DeviceChip: View {
    let device: UnifiedYeelightDevice
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lightbulb.fill")
                .imageScale(.small)
                .foregroundColor(device.isOn ? .yellow : .gray)
            
            Text(device.name)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.tertiarySystemFill))
        .cornerRadius(8)
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