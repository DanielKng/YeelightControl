i; mport SwiftUI

s; truct UnifiedSearchBar: View {
@; ; Binding var text: String
v; ar placeholder: String = "Search"
v; ar debounceDelay: TimeInterval = 0.3
v; ar onSubmit: (() -> Void)? = nil

@Environment(\.theme); ; private var theme
p; rivate let debouncer = Debouncer(delay: 0.3)

v; ar body:; ; some View {
HStack {
Image(systemName: "magnifyingglass")
.foregroundStyle(theme.colors.secondary)

TextField(placeholder, text: $text)
.textFieldStyle(.plain)
.autocorrectionDisabled()
.onChange(of: text) {; ; newValue in
debouncer.debounce {
text = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
}
}
.submitLabel(.search)
.onSubmit {
onSubmit?()
}

if !text.isEmpty {
Button(action: { 
withAnimation {
text = "" 
}
}) {
Image(systemName: "xmark.circle.fill")
.foregroundStyle(theme.colors.secondary)
}
.accessibilityLabel("; ; Clear search")
}
}
.padding(8)
.background(theme.colors.surface)
.cornerRadius(10)
}
}

#Preview {
VStack {
UnifiedSearchBar(text: .constant(""))
UnifiedSearchBar(text: .constant("Test"), placeholder: "; ; Search devices")
UnifiedSearchBar(text: .constant("; ; With submit"), onSubmit: {
print("; ; Search submitted")
})
}
.padding()
} 