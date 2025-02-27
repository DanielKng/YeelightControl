import SwiftUI

struct AutomationView: View {
    @StateObject private var automationManager = AutomationManager.shared
    @State private var showingAddAutomation = false
    
    var body: some View {
        List {
            ForEach(automationManager.automations) { automation in
                AutomationRow(automation: automation)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    automationManager.removeAutomation(automationManager.automations[index])
                }
            }
        }
        .navigationTitle("Automations")
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
                Image(systemName: triggerIcon)
                    .foregroundStyle(.orange)
                Text(automation.name)
                    .font(.headline)
                Spacer()
                Toggle("", isOn: .constant(automation.isEnabled))
                    .labelsHidden()
            }
            
            Text(triggerDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Action preview
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(automation.actions, id: \.self) { action in
                        ActionChip(action: action)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var triggerIcon: String {
        switch automation.trigger {
        case .time:
            return "clock.fill"
        case .location:
            return "location.fill"
        case .sunset:
            return "sunset.fill"
        case .sunrise:
            return "sunrise.fill"
        }
    }
    
    private var triggerDescription: String {
        switch automation.trigger {
        case .time(let date):
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Runs at \(formatter.string(from: date))"
        case .location(let location):
            return "Location based trigger: \(location.name)"
        case .sunset:
            return "Runs at sunset"
        case .sunrise:
            return "Runs at sunrise"
        }
    }
}

struct ActionChip: View {
    let action: Automation.Action
    
    var body: some View {
        HStack {
            Image(systemName: actionIcon)
            Text(actionDescription)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var actionIcon: String {
        switch action {
        case .setPower:
            return "lightbulb.fill"
        case .setScene:
            return "theatermasks.fill"
        case .setBrightness:
            return "sun.max.fill"
        case .setGroup:
            return "lightbulb.2.fill"
        }
    }
    
    private var actionDescription: String {
        switch action {
        case .setPower(let deviceIPs, let on):
            return "\(on ? "Turn On" : "Turn Off") (\(deviceIPs.count) devices)"
        case .setScene(let deviceIPs, _):
            return "Apply Scene (\(deviceIPs.count) devices)"
        case .setBrightness(let deviceIPs, let level):
            return "Set Brightness: \(level)% (\(deviceIPs.count) devices)"
        case .setGroup(_, _):
            return "Apply to Group"
        }
    }
}

#Preview {
    NavigationStack {
        AutomationView()
    }
} 