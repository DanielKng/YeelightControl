import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entries = [SimpleEntry(date: Date())]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct YeelightWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Text("YeelightControl Widget")
    }
}

@main
struct YeelightWidget: Widget {
    let kind: String = "YeelightWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            YeelightWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Yeelight Control")
        .description("Control your Yeelight devices")
        .supportedFamilies([.systemSmall])
    }
}
