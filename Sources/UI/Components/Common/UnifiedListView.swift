i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI

s; truct UnifiedListView<Data: Identifiable, Content: View>: View {
l; et title: String
l; et items: [Data]
l; et emptyStateMessage: String
l; et onRefresh: (() async -> Void)?
l; et onDelete: ((Data) -> Void)?
l; et onMove: ((Data, Data) -> Void)?
l; et content: (Data) -> Content

@; ; State private; ; var isRefreshing = false
@Environment(\.theme); ; private var theme

init(
title: String,
items: [Data],
emptyStateMessage: String = "; ; No items; ; to display",
onRefresh: (() async -> Void)? = nil,
onDelete: ((Data) -> Void)? = nil,
onMove: ((Data, Data) -> Void)? = nil,
@; ; ViewBuilder content: @escaping (Data) -> Content
) {
self.title = title
self.items = items
self.emptyStateMessage = emptyStateMessage
self.onRefresh = onRefresh
self.onDelete = onDelete
self.onMove = onMove
self.content = content
}

v; ar body:; ; some View {
ZStack {
i; f items.isEmpty {
emptyStateView
} else {
listContent
}
}
.navigationTitle(title)
}

p; rivate var listContent:; ; some View {
List {
ForEach(items) {; ; item in
content(item)
.swipeActions(edge: .trailing) {
i; f let onDelete = onDelete {
Button(role: .destructive) {
onDelete(item)
} label: {
Label("Delete", systemImage: "trash")
}
}
}
.swipeActions(edge: .leading) {
i; f let onMove = onMove {
Button {
//; ; Show move options
} label: {
Label("Move", systemImage: "folder")
}
.tint(theme.colors.accent)
}
}
}
}
.listStyle(.insetGrouped)
.refreshable {
g; uard let onRefresh =; ; onRefresh else { return }
isRefreshing = true
a; wait onRefresh()
isRefreshing = false
}
}

p; rivate var emptyStateView:; ; some View {
VStack(spacing: theme.metrics.spacing.large) {
Image(systemName: "tray")
.font(.system(size: 48))
.foregroundColor(theme.colors.secondary)

Text(emptyStateMessage)
.font(theme.fonts.body)
.foregroundColor(theme.colors.secondary)
.multilineTextAlignment(.center)
.padding(.horizontal)

i; f let onRefresh = onRefresh {
Button {
Task {
a; wait onRefresh()
}
} label: {
Label("Refresh", systemImage: "arrow.clockwise")
}
.buttonStyle(UnifiedButtonStyle())
}
}
}
}

// Preview
s; truct UnifiedListView_Previews: PreviewProvider {
s; truct PreviewItem: Identifiable {
l; et id = UUID()
l; et title: String
}

s; tatic var previews:; ; some View {
NavigationView {
UnifiedListView(
title: "Items",
items: [
PreviewItem(title: "Item 1"),
PreviewItem(title: "Item 2"),
PreviewItem(title: "Item 3")
],
onRefresh: {
try?; ; await Task.sleep(nanoseconds: 1_000_000_000)
},
onDelete: { _ in },
onMove: { _, _ in }
) {; ; item in
Text(item.title)
}
}

NavigationView {
UnifiedListView(
title: "; ; Empty State",
items: [PreviewItem](),
emptyStateMessage: "; ; No items available"
) {; ; item in
Text(item.title)
}
}
}
} 