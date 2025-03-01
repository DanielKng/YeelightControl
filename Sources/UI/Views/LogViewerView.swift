import SwiftUI

struct LogViewerView: View {
    @StateObject private var logger = Logger.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: LogEntry.Category?
    @State private var selectedLevel: LogEntry.Level?
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: "All Levels",
                            isSelected: selectedLevel == nil,
                            action: { selectedLevel = nil }
                        )

                        ForEach(LogEntry.Level.allCases, id: \.self) { level in
                            FilterChip(
                                title: level.rawValue.capitalized,
                                isSelected: selectedLevel == level,
                                color: level.color,
                                action: { selectedLevel = level }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(.bar)

                List {
                    ForEach(filteredLogs) { log in
                        LogEntryRow(entry: log)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search logs")
            .navigationTitle("Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive, action: { logger.clearLogs() }) {
                            Label("Clear Logs", systemImage: "trash")
                        }

                        Button(action: exportLogs) {
                            Label("Export Logs", systemImage: "square.and.arrow.up")
                        }

                        Menu("Filter Category") {
                            Button("All Categories") {
                                selectedCategory = nil
                            }

                            Divider()

                            ForEach(LogEntry.Category.allCases, id: \.self) { category in
                                Button(category.rawValue.capitalized) {
                                    selectedCategory = category
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var filteredLogs: [LogEntry] {
        var logs = logger.logs

        if let level = selectedLevel {
            logs = logs.filter { $0.level == level }
        }

        if let category = selectedCategory {
            logs = logs.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            logs = logs.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
        }

        return logs
    }
}

struct LogEntryRow: View {
    let entry: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: entry.category.icon)
                    .foregroundStyle(entry.level.color)

                Text(entry.message)
                    .font(.system(.body, design: .monospaced))
            }

            HStack {
                Text(entry.timestamp, style: .time)
                Text("[\(entry.level.rawValue.uppercased())]")
                    .foregroundStyle(entry.level.color)
                Text("[\(entry.category.rawValue)]")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
} 