import SwiftUI
import WidgetKit

/// Watch face complications and Smart Stack cards. They read the snapshot the watch app
/// saved in the shared keychain group; they never talk to the iPhone themselves.
struct HomeEntry: TimelineEntry {
    let date: Date
    let snapshot: WatchSnapshot

    static let preview = HomeEntry(date: .now, snapshot: WatchSnapshot(
        homeName: "Home",
        shopping: [.init(id: UUID(), name: "Milk", detail: nil, aisle: "Dairy & eggs", aisleOrder: 1, isBought: false),
                   .init(id: UUID(), name: "Bananas", detail: nil, aisle: "Fruit & vegetables", aisleOrder: 0, isBought: false)],
        tasks: [.init(id: UUID(), title: "Water the plants", dueAt: .now, person: nil, isDone: false)],
        updatedAt: .now, appliedActionIDs: []))
}

struct HomeProvider: TimelineProvider {
    func placeholder(in context: Context) -> HomeEntry { .preview }
    func getSnapshot(in context: Context, completion: @escaping (HomeEntry) -> Void) {
        completion(context.isPreview ? .preview : HomeEntry(date: .now, snapshot: Self.stored()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<HomeEntry>) -> Void) {
        // The watch app reloads these when the list changes; refresh hourly so "today" stays right.
        let entry = HomeEntry(date: .now, snapshot: Self.stored())
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600))))
    }
    static func stored() -> WatchSnapshot {
        WatchSharedSnapshot.load() ?? .empty
    }
}

struct ShoppingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HomeEntry

    var body: some View {
        let left = entry.snapshot.itemsLeft
        switch family {
        case .accessoryCircular:
            VStack(spacing: 0) {
                Image(systemName: "cart").font(.caption)
                Text("\(left)").font(.title3.bold()).widgetAccentable()
            }
            .accessibilityLabel("\(left) items to buy")
        case .accessoryInline:
            Label(left == 0 ? "Shopping done" : "\(left) to buy", systemImage: "cart")
        case .accessoryCorner:
            Image(systemName: "cart").font(.title3)
                .widgetLabel { Text(left == 0 ? "Done" : "\(left) to buy") }
        default:
            VStack(alignment: .leading, spacing: 2) {
                Label(left == 0 ? "Shopping done" : "\(left) to buy", systemImage: "cart").font(.headline).widgetAccentable()
                Text(entry.snapshot.shopping.filter { !$0.isBought }.prefix(3).map(\.name).joined(separator: ", "))
                    .font(.caption).lineLimit(2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct TaskWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HomeEntry

    var body: some View {
        let next = entry.snapshot.nextTask
        let left = entry.snapshot.tasksLeft
        switch family {
        case .accessoryCircular:
            VStack(spacing: 0) {
                Image(systemName: "checklist").font(.caption)
                Text("\(left)").font(.title3.bold()).widgetAccentable()
            }
            .accessibilityLabel("\(left) tasks left today")
        case .accessoryInline:
            Label(next?.title ?? "No tasks today", systemImage: "checklist")
        case .accessoryCorner:
            Image(systemName: "checklist").font(.title3)
                .widgetLabel { Text(left == 0 ? "All done" : "\(left) left") }
        default:
            VStack(alignment: .leading, spacing: 2) {
                Label("Next task", systemImage: "checklist").font(.caption).foregroundStyle(.secondary)
                Text(next?.title ?? "Nothing due today").font(.headline).lineLimit(2).widgetAccentable()
                if left > 1 { Text("\(left - 1) more today").font(.caption2).foregroundStyle(.secondary) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ShoppingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NamIllamShopping", provider: HomeProvider()) { entry in
            ShoppingWidgetView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Shopping")
        .description("Items left to buy.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

struct TaskWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NamIllamNextTask", provider: HomeProvider()) { entry in
            TaskWidgetView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next task")
        .description("Your next household task today.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

@main
struct NamIllamWatchWidgets: WidgetBundle {
    var body: some Widget {
        ShoppingWidget()
        TaskWidget()
    }
}
