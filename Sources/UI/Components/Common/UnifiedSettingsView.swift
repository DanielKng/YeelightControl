import SwiftUI

struct UnifiedSettingsView: View {
    let title: String
    let sections: [SettingsSection]
    let footer: String?
    
    @Environment(\.theme) private var theme
    
    init(
        title: String,
        sections: [SettingsSection],
        footer: String? = nil
    ) {
        self.title = title
        self.sections = sections
        self.footer = footer
    }
    
    var body: some View {
        List {
            ForEach(sections) { section in
                Section {
                    ForEach(section.items) { item in
                        settingsRow(for: item)
                    }
                } header: {
                    if let header = section.header {
                        Text(header)
                    }
                } footer: {
                    if let footer = section.footer {
                        Text(footer)
                    }
                }
            }
            
            if let footer = footer {
                Section {
                    Text(footer)
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.colors.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle(title)
        .listStyle(.insetGrouped)
    }
    
    @ViewBuilder
    private func settingsRow(for item: SettingsItem) -> some View {
        switch item.type {
        case .navigation(let destination):
            NavigationLink {
                destination
            } label: {
                settingsLabel(for: item)
            }
            
        case .toggle(let isOn):
            HStack {
                settingsLabel(for: item)
                Spacer()
                Toggle("", isOn: isOn)
                    .labelsHidden()
            }
            
        case .button(let action):
            Button {
                action()
            } label: {
                settingsLabel(for: item)
            }
            
        case .value(let value):
            HStack {
                settingsLabel(for: item)
                Spacer()
                Text(value)
                    .foregroundColor(theme.colors.secondary)
            }
            
        case .custom(let view):
            view
        }
    }
    
    private func settingsLabel(for item: SettingsItem) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .foregroundColor(theme.colors.primary)
                
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.colors.secondary)
                }
            }
        } icon: {
            if let icon = item.icon {
                Image(systemName: icon)
                    .foregroundColor(item.iconColor ?? theme.colors.accent)
            }
        }
    }
}

// Models
struct SettingsSection: Identifiable {
    let id = UUID()
    let header: String?
    let footer: String?
    let items: [SettingsItem]
    
    init(
        header: String? = nil,
        footer: String? = nil,
        items: [SettingsItem]
    ) {
        self.header = header
        self.footer = footer
        self.items = items
    }
}

struct SettingsItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let icon: String?
    let iconColor: Color?
    let type: ItemType
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        iconColor: Color? = nil,
        type: ItemType
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.type = type
    }
    
    enum ItemType {
        case navigation(destination: AnyView)
        case toggle(isOn: Binding<Bool>)
        case button(action: () -> Void)
        case value(String)
        case custom(AnyView)
    }
}

// Preview
struct UnifiedSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UnifiedSettingsView(
                title: "Settings",
                sections: [
                    SettingsSection(
                        header: "General",
                        footer: "These settings affect the general behavior of the app.",
                        items: [
                            SettingsItem(
                                title: "Notifications",
                                subtitle: "Configure notification preferences",
                                icon: "bell.fill",
                                type: .navigation(destination: AnyView(Text("Notifications")))
                            ),
                            SettingsItem(
                                title: "Dark Mode",
                                icon: "moon.fill",
                                type: .toggle(isOn: .constant(true))
                            )
                        ]
                    ),
                    SettingsSection(
                        header: "Account",
                        items: [
                            SettingsItem(
                                title: "Profile",
                                subtitle: "Manage your account details",
                                icon: "person.fill",
                                type: .navigation(destination: AnyView(Text("Profile")))
                            ),
                            SettingsItem(
                                title: "Sign Out",
                                icon: "arrow.right.square",
                                iconColor: .red,
                                type: .button(action: {})
                            )
                        ]
                    )
                ],
                footer: "App Version 1.0.0"
            )
        }
    }
} 