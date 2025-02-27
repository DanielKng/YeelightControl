import WidgetKit
import SwiftUI

/// The main entry point for the YeelightControl widget extension
/// Configures and provides all available widget types
@main
struct YeelightWidgetBundle: WidgetBundle {
    // MARK: - Properties
    
    /// The collection of widgets provided by this bundle
    @WidgetBundleBuilder
    var body: some Widget {
        // Quick control widget for individual devices
        DeviceControlWidget()
        
        // Scene activation widget
        SceneWidget()
        
        // Group control widget
        GroupControlWidget()
        
        // Status overview widget
        StatusWidget()
    }
}

// MARK: - Device Control Widget

/// Widget for controlling individual Yeelight devices
/// Provides quick access to power, brightness, and color controls
struct DeviceControlWidget: Widget {
    // MARK: - Properties
    
    /// Widget configuration
    let kind: String = "DeviceControlWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: DeviceSelectionIntent.self,
            provider: DeviceControlProvider()
        ) { entry in
            DeviceControlWidgetView(entry: entry)
        }
        .configurationDisplayName("Device Control")
        .description("Control a single Yeelight device")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Scene Widget

/// Widget for activating predefined scenes
/// Allows quick activation of saved lighting scenes
struct SceneWidget: Widget {
    // MARK: - Properties
    
    /// Widget configuration
    let kind: String = "SceneWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: SceneSelectionIntent.self,
            provider: SceneProvider()
        ) { entry in
            SceneWidgetView(entry: entry)
        }
        .configurationDisplayName("Scene Activation")
        .description("Quickly activate your favorite scenes")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Group Control Widget

/// Widget for controlling groups of Yeelight devices
/// Provides controls for device groups or rooms
struct GroupControlWidget: Widget {
    // MARK: - Properties
    
    /// Widget configuration
    let kind: String = "GroupControlWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: GroupSelectionIntent.self,
            provider: GroupControlProvider()
        ) { entry in
            GroupControlWidgetView(entry: entry)
        }
        .configurationDisplayName("Group Control")
        .description("Control a group of Yeelight devices")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Status Widget

/// Widget for displaying status of all Yeelight devices
/// Shows an overview of device states
struct StatusWidget: Widget {
    // MARK: - Properties
    
    /// Widget configuration
    let kind: String = "StatusWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: StatusProvider()
        ) { entry in
            StatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Device Status")
        .description("See the status of all your devices")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    DeviceControlWidget()
} timeline: {
    DeviceWidgetEntry(date: Date(), device: .preview, isReachable: true)
}

#Preview(as: .systemMedium) {
    SceneWidget()
} timeline: {
    SceneWidgetEntry(date: Date(), scene: .preview, devices: [.preview])
}

struct YeelightLargeWidget: Widget {
    let kind: String = "YeelightLargeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: YeelightWidgetProvider()) { entry in
            YeelightLargeWidgetView(entry: entry)
        }
        .configurationDisplayName("Yeelight Controls")
        .description("Control multiple lights with quick actions.")
        .supportedFamilies([.systemLarge])
    }
}

struct YeelightLargeWidgetView: View {
    var entry: YeelightWidgetProvider.Entry
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.orange)
                Text("Yeelight Controls")
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 4)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(entry.devices) { device in
                    DeviceWidgetButton(device: device)
                }
            }
            
            Spacer()
            
            HStack {
                Link(destination: URL(string: "yeelight://scenes")!) {
                    Label("Scenes", systemImage: "theatermasks.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Link(destination: URL(string: "yeelight://discover")!) {
                    Label("Discover", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .widgetBackground(Color(.systemBackground))
    }
}

struct DeviceWidgetButton: View {
    let device: YeelightWidgetDevice
    
    var body: some View {
        Link(destination: URL(string: "yeelight://device/\(device.id)")!) {
            VStack(spacing: 4) {
                Image(systemName: device.isOn ? "lightbulb.fill" : "lightbulb")
                    .font(.system(size: 20))
                    .foregroundStyle(device.isOn ? .orange : .gray)
                
                Text(device.name)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
}

extension View {
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(color, for: .widget)
        } else {
            return background(color)
        }
    }
} 