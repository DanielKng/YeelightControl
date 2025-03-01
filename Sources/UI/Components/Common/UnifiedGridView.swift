import SwiftUI
import Core

struct UnifiedGridView<Data: Identifiable, Content: View>: View {
    let title: String
    let items: [Data]
    let columns: Int
    let spacing: CGFloat
    let onRefresh: (() async -> Void)?
    let onItemTap: ((Data) -> Void)?
    let emptyStateIcon: String
    let emptyStateTitle: String
    let emptyStateMessage: String
    let footer: String?
    let content: (Data) -> Content
    
    @Environment(\.theme) private var theme
    @State private var isRefreshing = false
    
    init(
        title: String,
        items: [Data],
        columns: Int = 2,
        spacing: CGFloat = 16,
        onRefresh: (() async -> Void)? = nil,
        onItemTap: ((Data) -> Void)? = nil,
        emptyStateIcon: String = "square.grid.2x2",
        emptyStateTitle: String = "No Items",
        emptyStateMessage: String = "No items to display",
        footer: String? = nil,
        @ViewBuilder content: @escaping (Data) -> Content
    ) {
        self.title = title
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.onRefresh = onRefresh
        self.onItemTap = onItemTap
        self.emptyStateIcon = emptyStateIcon
        self.emptyStateTitle = emptyStateTitle
        self.emptyStateMessage = emptyStateMessage
        self.footer = footer
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if items.isEmpty {
                emptyStateView
            } else {
                Text(title)
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns), spacing: spacing) {
                    ForEach(items) { item in
                        Button {
                            onItemTap?(item)
                        } label: {
                            content(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                
                if let footer = footer {
                    Text(footer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            }
        }
        .refreshable {
            if let onRefresh = onRefresh {
                isRefreshing = true
                await onRefresh()
                isRefreshing = false
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(emptyStateTitle)
                .font(.headline)
            
            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Preview

struct UnifiedGridView_Previews: PreviewProvider {
    struct PreviewItem: Identifiable {
        let id = UUID()
        let title: String
        let color: Color
    }
    
    static var previews: some View {
        NavigationView {
            UnifiedGridView(
                title: "Sample Grid",
                items: [
                    PreviewItem(title: "Item 1", color: .red),
                    PreviewItem(title: "Item 2", color: .blue),
                    PreviewItem(title: "Item 3", color: .green),
                    PreviewItem(title: "Item 4", color: .orange)
                ],
                onItemTap: { _ in }
            ) { item in
                VStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(item.color)
                        .frame(height: 120)
                    
                    Text(item.title)
                        .font(.subheadline)
                }
            }
            .navigationTitle("Grid Example")
        }
        .environment(\.theme, Theme.default)
    }
}

extension UnifiedGridView {
    func onRefresh(_ action: @escaping () async -> Void) -> Self {
        UnifiedGridView(
            title: title,
            items: items,
            columns: columns,
            spacing: spacing,
            onRefresh: action,
            onItemTap: onItemTap,
            emptyStateIcon: emptyStateIcon,
            emptyStateTitle: emptyStateTitle,
            emptyStateMessage: emptyStateMessage,
            footer: footer,
            content: content
        )
    }
    
    func onItemTap(_ action: @escaping (Data) -> Void) -> Self {
        UnifiedGridView(
            title: title,
            items: items,
            columns: columns,
            spacing: spacing,
            onRefresh: onRefresh,
            onItemTap: action,
            emptyStateIcon: emptyStateIcon,
            emptyStateTitle: emptyStateTitle,
            emptyStateMessage: emptyStateMessage,
            footer: footer,
            content: content
        )
    }
} 