import SwiftUI
import WidgetKit

// MARK: - Widget Configuration
struct DeviceControlWidget: Widget {
    private let kind: String = "DeviceControlWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DeviceControlProvider()) { entry in
            DeviceControlWidgetView(entry: entry)
        }
        .configurationDisplayName("Device Control")
        .description("Quick access to control your Yeelight devices.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Provider
struct DeviceControlProvider: TimelineProvider {
    func placeholder(in context: Context) -> DeviceControlEntry {
        DeviceControlEntry(date: Date(), device: .placeholder)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DeviceControlEntry) -> Void) {
        let entry = DeviceControlEntry(date: Date(), device: .placeholder)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DeviceControlEntry>) -> Void) {
        Task {
            do {
                let devices = try await DeviceManager.shared.fetchDevices()
                let currentDate = Date()
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
                
                let entries = devices.map { device in
                    DeviceControlEntry(date: currentDate, device: device)
                }
                
                let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
                completion(timeline)
            } catch {
                let entry = DeviceControlEntry(date: Date(), device: .placeholder)
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
                completion(timeline)
            }
        }
    }
}

// MARK: - Widget Entry
struct DeviceControlEntry: TimelineEntry {
    let date: Date
    let device: Device
}

// MARK: - Widget Views
struct DeviceControlWidgetView: View {
    let entry: DeviceControlEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallDeviceControlView(device: entry.device)
        case .systemMedium:
            MediumDeviceControlView(device: entry.device)
        default:
            SmallDeviceControlView(device: entry.device)
        }
    }
}

struct SmallDeviceControlView: View {
    let device: Device
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(device.isOn ? .yellow : .gray)
                
                Text(device.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
            }
            
            Spacer()
            
            if device.isOn {
                Text("ON")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(4)
            } else {
                Text("OFF")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding()
        .widgetBackground()
    }
}

struct MediumDeviceControlView: View {
    let device: Device
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundColor(device.isOn ? .yellow : .gray)
                    
                    Text(device.name)
                        .font(.headline)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if device.isOn {
                    HStack {
                        Text("Brightness: \(Int(device.brightness))%")
                            .font(.caption)
                        
                        Text("Color: \(device.colorName)")
                            .font(.caption)
                    }
                } else {
                    Text("Device is currently off")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: device.isOn ? "power" : "power")
                    .font(.title)
                    .foregroundColor(device.isOn ? .green : .red)
                    .padding()
                    .background(Circle().fill(Color.gray.opacity(0.2)))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .widgetBackground()
    }
}

// MARK: - Widget Background
extension View {
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            return containerBackground(for: .widget) {
                Color(uiColor: .systemBackground)
            }
        } else {
            return background(Color(uiColor: .systemBackground))
        }
    }
} 
} 