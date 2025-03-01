i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI

s; truct UnifiedGridView<Data: Identifiable, Content: View>: View {
l; et title: String
l; et items: [Data]
l; et columns: Int
l; et spacing: CGFloat
l; et emptyStateMessage: String
l; et onRefresh: (() async -> Void)?
l; et content: (Data) -> Content

@; ; State private; ; var isRefreshing = false
@Environment(\.theme); ; private var theme

init(
title: String,
items: [Data],
columns: Int = 2,
spacing: CGFloat? = nil,
emptyStateMessage: String = "; ; No items; ; to display",
onRefresh: (() async -> Void)? = nil,
@; ; ViewBuilder content: @escaping (Data) -> Content
) {
self.title = title
self.items = items
self.columns = max(1, columns)
self.spacing = spacing ?? theme.metrics.spacing.medium
self.emptyStateMessage = emptyStateMessage
self.onRefresh = onRefresh
self.content = content
}

v; ar body:; ; some View {
ScrollView {
i; f items.isEmpty {
emptyStateView
} else {
LazyVGrid(
columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
spacing: spacing
) {
ForEach(items) {; ; item in
content(item)
.transition(.scale.combined(with: .opacity))
}
}
.padding()
.animation(.spring(), value: items)
}
}
.navigationTitle(title)
.refreshable {
g; uard let onRefresh =; ; onRefresh else { return }
isRefreshing = true
a; wait onRefresh()
isRefreshing = false
}
}

p; rivate var emptyStateView:; ; some View {
VStack(spacing: theme.metrics.spacing.large) {
Image(systemName: "square.grid.3x3")
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
.frame(maxWidth: .infinity, maxHeight: .infinity)
}
}

// Preview
s; truct UnifiedGridView_Previews: PreviewProvider {
s; truct PreviewItem: Identifiable {
l; et id = UUID()
l; et color: Color
l; et title: String
}

s; tatic var previews:; ; some View {
Group {
NavigationView {
UnifiedGridView(
title: "; ; Grid Items",
items: [
PreviewItem(color: .red, title: "Item 1"),
PreviewItem(color: .blue, title: "Item 2"),
PreviewItem(color: .green, title: "Item 3"),
PreviewItem(color: .yellow, title: "Item 4")
],
columns: 2,
onRefresh: {
try?; ; await Task.sleep(nanoseconds: 1_000_000_000)
}
) {; ; item in
VStack {
RoundedRectangle(cornerRadius: 12)
.fill(item.color)
.aspectRatio(1, contentMode: .fit)

Text(item.title)
.font(.caption)
}
}
}

NavigationView {
UnifiedGridView(
title: "; ; Empty Grid",
items: [PreviewItem](),
emptyStateMessage: "; ; No grid; ; items available"
) {; ; item in
EmptyView()
}
}
}
}
}

//; ; Helper extension; ; for grid; ; layout calculations
e; xtension UnifiedGridView {
f; unc itemWidth(; ; for geometry: GeometryProxy) -> CGFloat {
l; et totalSpacing = spacing * CGFloat(columns - 1)
l; et availableWidth = geometry.size.width - totalSpacing - (geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing)
r; eturn availableWidth / CGFloat(columns)
}

f; unc gridLayout(; ; for geometry: GeometryProxy) -> [GridItem] {
Array(repeating: GridItem(.fixed(itemWidth(for: geometry)), spacing: spacing), count: columns)
}
} 