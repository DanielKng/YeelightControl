import SwiftUI

struct UnifiedListView<Data: Identifiable, Content: View>: View {
    let title: String
    let items: [Data]
    let emptyStateMessage: String
    let onRefresh: (() async -> Void)?
    let onDelete: ((Data) -> Void)?
    let onMove: ((Data, Data) -> Void)?
    let content: (Data) -> Content

    @State private var isRefreshing = false
    @Environment(\.theme) private var theme

    init(
        title: String,
        items: [Data],
        emptyStateMessage: String = "No items to display",
        onRefresh: (() async -> Void)? = nil,
        onDelete: ((Data) -> Void)? = nil,
        onMove: ((Data, Data) -> Void)? = nil,
        @ViewBuilder content: @escaping (Data) -> Content
    ) {
        self.title = title
        self.items = items
        self.emptyStateMessage = emptyStateMessage
        self.onRefresh = onRefresh
        self.onDelete = onDelete
        self.onMove = onMove
        self.content = content
    }

    var body: some View {
        ZStack {
            if items.isEmpty {
                emptyStateView
            } else {
                listContent
            }
        }
        .navigationTitle(title)
    }

    private var listContent: some View {
        List {
            ForEach(items) { item in
                content(item)
                .swipeActions(edge: .trailing) {
                    if let onDelete = onDelete {
                        Button(role: .destructive) {
                            onDelete(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .swipeActions(edge: .leading) {
                    if let onMove = onMove {
                        Button {
                            // Show move options
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
            guard let onRefresh = onRefresh else { return }
            isRefreshing = true
            await onRefresh()
            isRefreshing = false
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: theme.metrics.spacing.large) {
            Image(systemName: "tray")
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
    }
}

// Preview
struct UnifiedListView_Previews: PreviewProvider {
    struct PreviewItem: Identifiable {
        let id = UUID()
        let title: String
    }

    static var previews: some View {
        NavigationView {
            UnifiedListView(
                title: "Items",
                items: [
                    PreviewItem(title: "Item 1"),
                    PreviewItem(title: "Item 2"),
                    PreviewItem(title: "Item 3")
                ],
                onRefresh: {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                },
                onDelete: { _ in },
                onMove: { _, _ in }
            ) { item in
                Text(item.title)
            }
        }

        NavigationView {
            UnifiedListView(
                title: "Empty State",
                items: [PreviewItem](),
                emptyStateMessage: "No items available"
            ) { item in
                Text(item.title)
            }
        }
    }
} 