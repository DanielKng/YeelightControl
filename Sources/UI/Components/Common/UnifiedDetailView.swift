import SwiftUI

struct UnifiedDetailView<Header: View, Content: View>: View {
    // MARK: - Properties
    
    let title: String
    let subtitle: String?
    let showsNavigationBar: Bool
    let onEdit: (() -> Void)?
    let onShare: (() -> Void)?
    let onDelete: (() -> Void)?
    let deleteConfirmationMessage: String?
    
    @State private var showingDeleteAlert = false
    
    // MARK: - Initialization
    
    init(
        title: String,
        subtitle: String? = nil,
        showsNavigationBar: Bool = true,
        onEdit: (() -> Void)? = nil,
        onShare: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        deleteConfirmationMessage: String? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showsNavigationBar = showsNavigationBar
        self.onEdit = onEdit
        self.onShare = onShare
        self.onDelete = onDelete
        self.deleteConfirmationMessage = deleteConfirmationMessage
        self.header = header()
        self.content = content()
    }
    
    private let header: Header
    private let content: Content
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                
                Divider()
                
                contentSection
            }
            .padding()
        }
        .navigationTitle(showsNavigationBar ? title : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if onEdit != nil || onShare != nil || onDelete != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarMenu
                }
            }
        }
        .alert("Confirm Delete", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text(deleteConfirmationMessage ?? "Are you sure you want to delete this item? This action cannot be undone.")
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !showsNavigationBar {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            header
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
    }
    
    private var toolbarMenu: some View {
        Menu {
            if let onEdit = onEdit {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
            }
            
            if let onShare = onShare {
                Button(action: onShare) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            
            if let onDelete = onDelete {
                Button(role: .destructive, action: {
                    showingDeleteAlert = true
                }) {
                    Label("Delete", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

struct UnifiedDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UnifiedDetailView(
                title: "Sample Item",
                subtitle: "Sample subtitle text",
                onEdit: {},
                onShare: {},
                onDelete: {}
            ) {
                // Header content
                HStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 60, height: 60)
                    
                    VStack(alignment: .leading) {
                        Text("Header Content")
                            .font(.headline)
                        Text("Additional details")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            } content: {
                // Main content
                VStack(alignment: .leading, spacing: 16) {
                    Text("This is a sample item description that showcases the unified detail view layout.")
                        .font(.body)
                    
                    ForEach(1...5, id: \.self) { item in
                        HStack {
                            Text("Property \(item)")
                            Spacer()
                            Text("Value \(item)")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        
                        if item < 5 {
                            Divider()
                        }
                    }
                }
            }
        }
    }
} 