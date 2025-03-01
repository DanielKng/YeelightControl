import SwiftUI
import Core

struct UnifiedSearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSearch: ((String) -> Void)?
    let onCancel: (() -> Void)?
    
    @Environment(\.theme) private var theme
    private let debouncer = Debouncer(delay: 0.3)
    
    @State private var isEditing = false
    
    init(
        text: Binding<String>,
        placeholder: String = "Search",
        onSearch: ((String) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSearch = onSearch
        self.onCancel = onCancel
    }
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(placeholder, text: $text)
                    .onChange(of: text) { newValue in
                        debouncer.debounce {
                            onSearch?(newValue)
                        }
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        onSearch?("")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if isEditing {
                Button("Cancel") {
                    text = ""
                    isEditing = false
                    
                    // Dismiss keyboard
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    
                    onCancel?()
                }
                .transition(.move(edge: .trailing))
                .animation(.default, value: isEditing)
            }
        }
        .padding(.horizontal)
        .onTapGesture {
            isEditing = true
        }
    }
}

// MARK: - Preview

struct UnifiedSearchBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            UnifiedSearchBar(
                text: .constant(""),
                placeholder: "Search items",
                onSearch: { _ in },
                onCancel: { }
            )
            .previewDisplayName("Empty")
            
            UnifiedSearchBar(
                text: .constant("Hello"),
                placeholder: "Search items",
                onSearch: { _ in },
                onCancel: { }
            )
            .previewDisplayName("With Text")
        }
        .padding(.vertical)
        .environment(\.theme, Theme.default)
    }
} 