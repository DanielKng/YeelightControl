import SwiftUI

struct UnifiedTabSelector<Tab: Hashable>: View {
    @Binding var selection: Tab
    let tabs: [TabItem<Tab>]
    var style: TabStyle = .segmented
    
    @Environment(\.theme) private var theme
    
    enum TabStyle {
        case segmented
        case pills
        case underlined
    }
    
    struct TabItem<Tab: Hashable> {
        let title: String
        let icon: String?
        let tag: Tab
        
        init(_ title: String, icon: String? = nil, tag: Tab) {
            self.title = title
            self.icon = icon
            self.tag = tag
        }
    }
    
    var body: some View {
        Group {
            switch style {
            case .segmented:
                Picker("", selection: $selection) {
                    ForEach(tabs, id: \.tag) { tab in
                        HStack {
                            if let icon = tab.icon {
                                Image(systemName: icon)
                            }
                            Text(tab.title)
                        }
                        .tag(tab.tag)
                    }
                }
                .pickerStyle(.segmented)
                
            case .pills:
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(tabs, id: \.tag) { tab in
                            pillButton(for: tab)
                        }
                    }
                    .padding(.horizontal)
                }
                
            case .underlined:
                VStack(spacing: 0) {
                    HStack(spacing: 24) {
                        ForEach(tabs, id: \.tag) { tab in
                            underlinedButton(for: tab)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func pillButton(for tab: TabItem<Tab>) -> some View {
        Button {
            withAnimation {
                selection = tab.tag
            }
        } label: {
            HStack {
                if let icon = tab.icon {
                    Image(systemName: icon)
                }
                Text(tab.title)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(selection == tab.tag ? theme.colors.accent : theme.colors.surface)
            .foregroundStyle(selection == tab.tag ? .white : theme.colors.primary)
            .clipShape(Capsule())
        }
    }
    
    private func underlinedButton(for tab: TabItem<Tab>) -> some View {
        Button {
            withAnimation {
                selection = tab.tag
            }
        } label: {
            VStack(spacing: 8) {
                HStack {
                    if let icon = tab.icon {
                        Image(systemName: icon)
                    }
                    Text(tab.title)
                }
                .foregroundStyle(selection == tab.tag ? theme.colors.accent : theme.colors.secondary)
                
                Rectangle()
                    .fill(selection == tab.tag ? theme.colors.accent : .clear)
                    .frame(height: 2)
            }
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        UnifiedTabSelector(
            selection: .constant(0),
            tabs: [
                .init("First", icon: "1.circle", tag: 0),
                .init("Second", icon: "2.circle", tag: 1),
                .init("Third", icon: "3.circle", tag: 2)
            ],
            style: .segmented
        )
        
        UnifiedTabSelector(
            selection: .constant(1),
            tabs: [
                .init("Photos", icon: "photo", tag: 0),
                .init("Camera", icon: "camera", tag: 1),
                .init("Library", icon: "folder", tag: 2)
            ],
            style: .pills
        )
        
        UnifiedTabSelector(
            selection: .constant(2),
            tabs: [
                .init("Home", icon: "house", tag: 0),
                .init("Search", icon: "magnifyingglass", tag: 1),
                .init("Profile", icon: "person", tag: 2)
            ],
            style: .underlined
        )
    }
    .padding()
} 