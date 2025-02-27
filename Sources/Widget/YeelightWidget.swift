import WidgetKit
import SwiftUI

struct YeelightWidget: Widget {
    let kind: String = "YeelightWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: YeelightWidgetProvider()) { entry in
            YeelightWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Controls")
        .description("Control your favorite lights with a single tap.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct YeelightWidgetView: View {
    var entry: YeelightWidgetProvider.Entry
    @Environment(\.widgetFamily) private var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    var entry: YeelightWidgetProvider.Entry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.orange)
                Text("Yeelight")
                    .font(.headline)
                Spacer()
            }
            
            if let device = entry.devices.first {
                Link(destination: URL(string: "yeelight://device/\(device.id)")!) {
                    VStack(spacing: 4) {
                        Image(systemName: device.isOn ? "lightbulb.fill" : "lightbulb")
                            .font(.system(size: 24))
                            .foregroundStyle(device.isOn ? .orange : .gray)
                        
                        Text(device.name)
                            .font(.subheadline)
                            .lineLimit(1)
                        
                        Text(device.isOn ? "On" : "Off")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
            } else {
                Text("No devices")
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Link(destination: URL(string: "yeelight://discover")!) {
                Text("Discover Devices")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding()
        .widgetBackground(Color(.systemBackground))
    }
}

struct MediumWidgetView: View {
    var entry: YeelightWidgetProvider.Entry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.orange)
                Text("Yeelight Controls")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                ForEach(entry.devices.prefix(4)) { device in
                    DeviceWidgetButton(device: device)
                }
            }
            
            Spacer()
            
            HStack {
                Link(destination: URL(string: "yeelight://scenes")!) {
                    Text("Scenes")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Link(destination: URL(string: "yeelight://discover")!) {
                    Text("Discover")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .widgetBackground(Color(.systemBackground))
    }
}

#Preview(as: .systemSmall) {
    YeelightWidget()
} timeline: {
    YeelightWidgetEntry(
        date: Date(),
        devices: [
            .init(id: "1", name: "Living Room", isOn: true),
            .init(id: "2", name: "Bedroom", isOn: false),
            .init(id: "3", name: "Kitchen", isOn: true)
        ]
    )
}

#Preview(as: .systemMedium) {
    YeelightWidget()
} timeline: {
    YeelightWidgetEntry(
        date: Date(),
        devices: [
            .init(id: "1", name: "Living Room", isOn: true),
            .init(id: "2", name: "Bedroom", isOn: false),
            .init(id: "3", name: "Kitchen", isOn: true),
            .init(id: "4", name: "Office", isOn: false)
        ]
    )
} 