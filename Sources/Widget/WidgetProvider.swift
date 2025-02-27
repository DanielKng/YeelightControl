import WidgetKit
import SwiftUI

struct YeelightWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> YeelightWidgetEntry {
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
    
    func getSnapshot(in context: Context, completion: @escaping (YeelightWidgetEntry) -> Void) {
        let entry = YeelightWidgetEntry(
            date: Date(),
            devices: loadDevices()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<YeelightWidgetEntry>) -> Void) {
        let devices = loadDevices()
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        
        let entry = YeelightWidgetEntry(
            date: currentDate,
            devices: devices
        )
        
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
    
    private func loadDevices() -> [YeelightWidgetDevice] {
        // In a real implementation, this would load from UserDefaults or App Group
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.yourdomain.YeelightControl") else {
            return []
        }
        
        if let data = sharedDefaults.data(forKey: "widget_devices"),
           let devices = try? JSONDecoder().decode([YeelightWidgetDevice].self, from: data) {
            return devices
        }
        
        // Return sample data if no saved data
        return [
            .init(id: "1", name: "Living Room", isOn: true),
            .init(id: "2", name: "Bedroom", isOn: false),
            .init(id: "3", name: "Kitchen", isOn: true)
        ]
    }
}

struct YeelightWidgetEntry: TimelineEntry {
    let date: Date
    let devices: [YeelightWidgetDevice]
}

struct YeelightWidgetDevice: Identifiable, Codable {
    let id: String
    let name: String
    let isOn: Bool
} 