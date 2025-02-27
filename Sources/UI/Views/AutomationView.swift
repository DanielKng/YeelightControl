import SwiftUI

struct AutomationView: View {
    @StateObject private var automationManager = AutomationManager.shared
    @State private var showingAddAutomation = false
    
    var body: some View {
        UnifiedListView(
            title: "Automations",
            items: automationManager.automations,
            emptyStateMessage: "No automations found",
            onDelete: { indexSet in
                for index in indexSet {
                    automationManager.removeAutomation(automationManager.automations[index])
                }
            }
        ) { automation in
            AutomationRow(automation: automation)
        }
        .toolbar {
            Button(action: { showingAddAutomation = true }) {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingAddAutomation) {
            NavigationStack {
                AutomationEditor(manager: YeelightManager.shared)
            }
        }
        .overlay {
            if automationManager.automations.isEmpty {
                ContentUnavailableView(
                    "No Automations",
                    systemImage: "clock.arrow.2.circlepath",
                    description: Text("Add automations to control your lights automatically")
                )
            }
        }
    }
}

struct AutomationRow: View {
    let automation: Automation
    
    var body: some View {
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
        .padding(.vertical, 8)
    }
}

struct DeviceChip: View {
    let device: Device
    
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

#Preview {
    NavigationStack {
        AutomationView()
    }
} 