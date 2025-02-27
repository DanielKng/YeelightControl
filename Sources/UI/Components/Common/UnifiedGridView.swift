import SwiftUI

struct UnifiedGridView<Data: Identifiable, Content: View>: View {
    let title: String
    let items: [Data]
    let columns: Int
    let spacing: CGFloat
    let emptyStateMessage: String
    let onRefresh: (() async -> Void)?
    let content: (Data) -> Content
    
    @State private var isRefreshing = false
    @Environment(\.theme) private var theme
    
    init(
        title: String,
        items: [Data],
        columns: Int = 2,
        spacing: CGFloat? = nil,
        emptyStateMessage: String = "No items to display",
        onRefresh: (() async -> Void)? = nil,
        @ViewBuilder content: @escaping (Data) -> Content
    ) {
        self.title = title
        self.items = items
        self.columns = max(1, columns)
        self.spacing = spacing ?? theme.metrics.spacing.medium
        self.emptyStateMessage = emptyStateMessage
        self.onRefresh = onRefresh
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            if items.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
                    spacing: spacing
                ) {
                    ForEach(items) { item in
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
            guard let onRefresh = onRefresh else { return }
            isRefreshing = true
            await onRefresh()
            isRefreshing = false
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: theme.metrics.spacing.large) {
            Image(systemName: "square.grid.3x3")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.secondary)
            
            Text(emptyStateMessage)
                .font(theme.fonts.body)
                .foregroundColor(theme.colors.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let onRefresh = onRefresh {
                Button {
                    Task {
                        await onRefresh()
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
struct UnifiedGridView_Previews: PreviewProvider {
    struct PreviewItem: Identifiable {
        let id = UUID()
        let color: Color
        let title: String
    }
    
    static var previews: some View {
        Group {
            NavigationView {
                UnifiedGridView(
                    title: "Grid Items",
                    items: [
                        PreviewItem(color: .red, title: "Item 1"),
                        PreviewItem(color: .blue, title: "Item 2"),
                        PreviewItem(color: .green, title: "Item 3"),
                        PreviewItem(color: .yellow, title: "Item 4")
                    ],
                    columns: 2,
                    onRefresh: {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                    }
                ) { item in
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
                    title: "Empty Grid",
                    items: [PreviewItem](),
                    emptyStateMessage: "No grid items available"
                ) { item in
                    EmptyView()
                }
            }
        }
    }
}

// Helper extension for grid layout calculations
extension UnifiedGridView {
    func itemWidth(for geometry: GeometryProxy) -> CGFloat {
        let totalSpacing = spacing * CGFloat(columns - 1)
        let availableWidth = geometry.size.width - totalSpacing - (geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing)
        return availableWidth / CGFloat(columns)
    }
    
    func gridLayout(for geometry: GeometryProxy) -> [GridItem] {
        Array(repeating: GridItem(.fixed(itemWidth(for: geometry)), spacing: spacing), count: columns)
    }
} 