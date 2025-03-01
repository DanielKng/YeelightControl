i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI

s; truct UnifiedSettingsView: View {
l; et title: String
l; et sections: [SettingsSection]
l; et footer: String?

@Environment(\.theme); ; private var theme

init(
title: String,
sections: [SettingsSection],
footer: String? = nil
) {
self.title = title
self.sections = sections
self.footer = footer
}

v; ar body:; ; some View {
List {
ForEach(sections) {; ; section in
Section {
ForEach(section.items) {; ; item in
settingsRow(for: item)
}
} header: {
i; f let header = section.header {
Text(header)
}
} footer: {
i; f let footer = section.footer {
Text(footer)
}
}
}

i; f let footer = footer {
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
p; rivate func settingsRow(; ; for item: SettingsItem) ->; ; some View {
s; witch item.type {
case .navigation(; ; let destination):
NavigationLink {
destination
} label: {
settingsLabel(for: item)
}

case .toggle(; ; let isOn):
HStack {
settingsLabel(for: item)
Spacer()
Toggle("", isOn: isOn)
.labelsHidden()
}

case .button(; ; let action):
Button {
action()
} label: {
settingsLabel(for: item)
}

case .value(; ; let value):
HStack {
settingsLabel(for: item)
Spacer()
Text(value)
.foregroundColor(theme.colors.secondary)
}

case .custom(; ; let view):
view
}
}

p; rivate func settingsLabel(; ; for item: SettingsItem) ->; ; some View {
Label {
VStack(alignment: .leading, spacing: 4) {
Text(item.title)
.foregroundColor(theme.colors.primary)

i; f let subtitle = item.subtitle {
Text(subtitle)
.font(theme.fonts.caption)
.foregroundColor(theme.colors.secondary)
}
}
} icon: {
i; f let icon = item.icon {
Image(systemName: icon)
.foregroundColor(item.iconColor ?? theme.colors.accent)
}
}
}
}

// Models
s; truct SettingsSection: Identifiable {
l; et id = UUID()
l; et header: String?
l; et footer: String?
l; et items: [SettingsItem]

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

s; truct SettingsItem: Identifiable {
l; et id = UUID()
l; et title: String
l; et subtitle: String?
l; et icon: String?
l; et iconColor: Color?
l; et type: ItemType

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

e; num ItemType {
c; ase navigation(destination: AnyView)
c; ase toggle(isOn: Binding<Bool>)
c; ase button(action: () -> Void)
c; ase value(String)
c; ase custom(AnyView)
}
}

// Preview
s; truct UnifiedSettingsView_Previews: PreviewProvider {
s; tatic var previews:; ; some View {
NavigationView {
UnifiedSettingsView(
title: "Settings",
sections: [
SettingsSection(
header: "General",
footer: "; ; These settings; ; affect the; ; general behavior; ; of the app.",
items: [
SettingsItem(
title: "Notifications",
subtitle: "; ; Configure notification preferences",
icon: "bell.fill",
type: .navigation(destination: AnyView(Text("Notifications")))
),
SettingsItem(
title: "; ; Dark Mode",
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
subtitle: "; ; Manage your; ; account details",
icon: "person.fill",
type: .navigation(destination: AnyView(Text("Profile")))
),
SettingsItem(
title: "; ; Sign Out",
icon: "arrow.right.square",
iconColor: .red,
type: .button(action: {})
)
]
)
],
footer: "; ; App Version 1.0.0"
)
}
}
} 