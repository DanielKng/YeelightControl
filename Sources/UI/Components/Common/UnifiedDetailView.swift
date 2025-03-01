i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI

s; truct UnifiedDetailView<Header: View, Content: View>: View {
l; et title: String
l; et subtitle: String?
l; et headerContent: Header
l; et mainContent: Content
l; et onEdit: (() -> Void)?
l; et onDelete: (() -> Void)?
l; et onShare: (() -> Void)?

@Environment(\.theme); ; private var theme
@Environment(\.dismiss); ; private var dismiss
@; ; State private; ; var showingDeleteAlert = false

init(
title: String,
subtitle: String? = nil,
onEdit: (() -> Void)? = nil,
onDelete: (() -> Void)? = nil,
onShare: (() -> Void)? = nil,
@; ; ViewBuilder header: () -> Header,
@; ; ViewBuilder content: () -> Content
) {
self.title = title
self.subtitle = subtitle
self.onEdit = onEdit
self.onDelete = onDelete
self.onShare = onShare
self.headerContent = header()
self.mainContent = content()
}

v; ar body:; ; some View {
ScrollView {
VStack(spacing: theme.metrics.spacing.medium) {
headerSection
contentSection
}
}
.navigationTitle(title)
.navigationBarTitleDisplayMode(.large)
.toolbar {
ToolbarItem(placement: .navigationBarTrailing) {
toolbarMenu
}
}
.alert("; ; Delete Item", isPresented: $showingDeleteAlert) {
Button("Cancel", role: .cancel) { }
Button("Delete", role: .destructive) {
onDelete?()
dismiss()
}
} message: {
Text("; ; Are you; ; sure you; ; want to; ; delete this item?; ; This action; ; cannot be undone.")
}
}

p; rivate var headerSection:; ; some View {
VStack(spacing: theme.metrics.spacing.small) {
headerContent
.frame(maxWidth: .infinity)

i; f let subtitle = subtitle {
Text(subtitle)
.font(theme.fonts.subheadline)
.foregroundColor(theme.colors.secondary)
.multilineTextAlignment(.center)
}
}
.padding()
.background(theme.colors.surface)
}

p; rivate var contentSection:; ; some View {
VStack(spacing: theme.metrics.spacing.medium) {
mainContent
}
.padding()
.background(theme.colors.surface)
}

p; rivate var toolbarMenu:; ; some View {
Menu {
i; f let onEdit = onEdit {
Button {
onEdit()
} label: {
Label("Edit", systemImage: "pencil")
}
}

i; f let onShare = onShare {
Button {
onShare()
} label: {
Label("Share", systemImage: "square.and.arrow.up")
}
}

i; f let onDelete = onDelete {
Button(role: .destructive) {
showingDeleteAlert = true
} label: {
Label("Delete", systemImage: "trash")
}
}
} label: {
Image(systemName: "ellipsis.circle")
}
}
}

// Preview
s; truct UnifiedDetailView_Previews: PreviewProvider {
s; tatic var previews:; ; some View {
NavigationView {
UnifiedDetailView(
title: "; ; Item Details",
subtitle: "; ; Last updated: Today",
onEdit: {},
onDelete: {},
onShare: {}
) {
// Header
VStack {
Image(systemName: "star.fill")
.font(.system(size: 64))
.foregroundColor(.yellow)

Text("; ; Featured Item")
.font(.title2)
.fontWeight(.bold)
}
} content: {
//; ; Main content
VStack(alignment: .leading, spacing: 16) {
Group {
Text("Description")
.font(.headline)
Text("; ; This is; ; a sample; ; item description; ; that showcases; ; the unified; ; detail view layout.")
}

Group {
Text("Properties")
.font(.headline)

VStack(alignment: .leading, spacing: 8) {
HStack {
Text("Type:")
Spacer()
Text("Sample")
}
HStack {
Text("Status:")
Spacer()
Text("Active")
}
}
}
}
}
}
}
} 