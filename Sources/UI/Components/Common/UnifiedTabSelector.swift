import SwiftUI
import Core

struct UnifiedTabSelector<TabType: Hashable>: View {
    @Binding var selection: TabType
    let items: [TabItem<TabType>]
    let style: TabStyle
    
    @Environment(\.theme) private var theme
    
    init(selection: Binding<TabType>, items: [TabItem<TabType>], style: TabStyle = .underline) {
        self._selection = selection
        self.items = items
        self.style = style
    }
    
    struct TabItem<ItemType: Hashable> {
        let value: ItemType
        let label: String
        let icon: String?
        
        init(value: ItemType, label: String, icon: String? = nil) {
            self.value = value
            self.label = label
            self.icon = icon
        }
    }
    
    enum TabStyle {
        case underline
        case pill
        case segmented
    }
    
    var body: some View {
        VStack(spacing: 0) {
            switch style {
            case .underline:
                underlineStyle
            case .pill:
                pillStyle
            case .segmented:
                segmentedStyle
            }
        }
    }
    
    private var underlineStyle: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(items, id: \.value) { item in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = item.value
                        }
                    } label: {
                        VStack(spacing: 8) {
                            if let icon = item.icon {
                                Image(systemName: icon)
                                    .font(.system(size: 16))
                            }
                            
                            Text(item.label)
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(selection == item.value ? .accentColor : .secondary)
                    }
                }
            }
            
            // Underline indicator
            GeometryReader { geometry in
                let tabWidth = geometry.size.width / CGFloat(items.count)
                let index = items.firstIndex { $0.value == selection } ?? 0
                
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: tabWidth, height: 2)
                    .offset(x: tabWidth * CGFloat(index))
                    .animation(.easeInOut(duration: 0.2), value: selection)
            }
            .frame(height: 2)
        }
    }
    
    private var pillStyle: some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.value) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = item.value
                    }
                } label: {
                    HStack(spacing: 6) {
                        if let icon = item.icon {
                            Image(systemName: icon)
                                .font(.system(size: 14))
                        }
                        
                        Text(item.label)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(selection == item.value ? Color.accentColor : Color.clear)
                    )
                    .foregroundColor(selection == item.value ? .white : .primary)
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.1))
        )
        .padding(.horizontal)
    }
    
    private var segmentedStyle: some View {
        Picker("", selection: $selection) {
            ForEach(items, id: \.value) { item in
                HStack {
                    if let icon = item.icon {
                        Image(systemName: icon)
                    }
                    Text(item.label)
                }
                .tag(item.value)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

// MARK: - Preview

struct UnifiedTabSelector_Previews: PreviewProvider {
    enum PreviewTab: String, CaseIterable {
        case first = "First"
        case second = "Second"
        case third = "Third"
    }
    
    static var previews: some View {
        VStack(spacing: 40) {
            StateWrapper(initialValue: PreviewTab.first) { selection in
                UnifiedTabSelector(
                    selection: selection,
                    items: PreviewTab.allCases.map { tab in
                        UnifiedTabSelector<PreviewTab>.TabItem(
                            value: tab,
                            label: tab.rawValue,
                            icon: iconFor(tab)
                        )
                    },
                    style: .underline
                )
            }
            .previewDisplayName("Underline Style")
            
            StateWrapper(initialValue: PreviewTab.first) { selection in
                UnifiedTabSelector(
                    selection: selection,
                    items: PreviewTab.allCases.map { tab in
                        UnifiedTabSelector<PreviewTab>.TabItem(
                            value: tab,
                            label: tab.rawValue,
                            icon: iconFor(tab)
                        )
                    },
                    style: .pill
                )
            }
            .previewDisplayName("Pill Style")
            
            StateWrapper(initialValue: PreviewTab.first) { selection in
                UnifiedTabSelector(
                    selection: selection,
                    items: PreviewTab.allCases.map { tab in
                        UnifiedTabSelector<PreviewTab>.TabItem(
                            value: tab,
                            label: tab.rawValue
                        )
                    },
                    style: .segmented
                )
            }
            .previewDisplayName("Segmented Style")
        }
        .padding()
        .environment(\.theme, Theme.default)
    }
    
    private static func iconFor(_ tab: PreviewTab) -> String {
        switch tab {
        case .first: return "1.circle"
        case .second: return "2.circle"
        case .third: return "3.circle"
        }
    }
    
    struct StateWrapper<Value, Content: View>: View {
        @State private var value: Value
        let content: (Binding<Value>) -> Content
        
        init(initialValue: Value, content: @escaping (Binding<Value>) -> Content) {
            self._value = State(initialValue: initialValue)
            self.content = content
        }
        
        var body: some View {
            content($value)
        }
    }
} 