import SwiftUI

@main
struct NamIllamWatchApp: App {
    @State private var store = WatchStore()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(store)
                .tint(WatchTheme.accent)
                .task { store.start() }
        }
    }
}

enum WatchTheme {
    /// The app's gold accent, readable on the watch's black background.
    static let accent = Color(red: 0xF4 / 255, green: 0xD9 / 255, blue: 0xA0 / 255)
    static let midnight = Color(red: 0x14 / 255, green: 0x1B / 255, blue: 0x33 / 255)
}

struct WatchRootView: View {
    @Environment(WatchStore.self) private var store

    var body: some View {
        TabView {
            NavigationStack { WatchShoppingView() }
            NavigationStack { WatchTasksView() }
        }
        .tabViewStyle(.verticalPage)
    }
}

/// Dictate or type; the iPhone reads it into shopping items and tasks.
struct WatchAddButton: View {
    @Environment(WatchStore.self) private var store
    let prompt: String

    var body: some View {
        TextFieldLink(prompt: Text(prompt)) {
            Label("Add", systemImage: "plus")
        } onSubmit: { text in
            store.add(text)
        }
        .accessibilityIdentifier("watch.add")
    }
}

struct WatchShoppingView: View {
    @Environment(WatchStore.self) private var store

    var body: some View {
        let snapshot = store.shown
        List {
            if !store.hasSynced {
                WatchWaitingView()
            } else if snapshot.shopping.isEmpty && store.waitingAdds.isEmpty {
                Text("Nothing to buy right now.").foregroundStyle(.secondary)
            }
            ForEach(snapshot.aisles, id: \.name) { aisle in
                Section(aisle.name) {
                    ForEach(aisle.items) { item in
                        Button { store.setBought(item, !item.isBought) } label: {
                            HStack(spacing: 10) {
                                Image(systemName: item.isBought ? "checkmark.circle.fill" : "circle")
                                    .font(.title3).foregroundStyle(item.isBought ? .green : WatchTheme.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name).strikethrough(item.isBought).lineLimit(2)
                                    if let detail = item.detail { Text(detail).font(.caption2).foregroundStyle(.secondary).lineLimit(1) }
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }
                        .accessibilityLabel("\(item.name)\(item.detail.map { ", \($0)" } ?? ""), \(item.isBought ? "bought" : "to buy")")
                        .accessibilityHint(item.isBought ? "Marks it as still needed" : "Marks it as bought")
                    }
                }
            }
            if !store.waitingAdds.isEmpty {
                Section("Sending to iPhone") {
                    ForEach(store.waitingAdds, id: \.self) { Text($0).foregroundStyle(.secondary) }
                }
            }
            Section { WatchAddButton(prompt: "Milk, bread and eggs") }
        }
        .navigationTitle("Shopping \(snapshot.itemsLeft > 0 ? "· \(snapshot.itemsLeft)" : "")")
        .containerBackground(WatchTheme.midnight.gradient, for: .navigation)
    }
}

struct WatchTasksView: View {
    @Environment(WatchStore.self) private var store

    var body: some View {
        let snapshot = store.shown
        List {
            if !store.hasSynced {
                WatchWaitingView()
            } else if snapshot.tasks.isEmpty {
                Text("No tasks due today.").foregroundStyle(.secondary)
            }
            ForEach(snapshot.tasks) { task in
                Button { store.setDone(task, !task.isDone) } label: {
                    HStack(spacing: 10) {
                        Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                            .font(.title3).foregroundStyle(task.isDone ? .green : WatchTheme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title).strikethrough(task.isDone).lineLimit(3)
                            if let line = Self.detail(task) { Text(line).font(.caption2).foregroundStyle(.secondary) }
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .accessibilityLabel("\(task.title), \(task.isDone ? "done" : "not done")")
                .accessibilityHint(task.isDone ? "Marks it as not done" : "Marks it as done")
            }
            Section { WatchAddButton(prompt: "Call the plumber today") }
        }
        .navigationTitle("Today")
        .containerBackground(WatchTheme.midnight.gradient, for: .navigation)
    }

    static func detail(_ task: WatchSnapshot.Task) -> String? {
        var parts: [String] = []
        if let due = task.dueAt {
            let calendar = Calendar.current
            if due < calendar.startOfDay(for: .now) { parts.append("Overdue") }
            else if due == calendar.startOfDay(for: due) { parts.append("Today") }
            else { parts.append(due.formatted(date: .omitted, time: .shortened)) }
        }
        if let person = task.person { parts.append(person) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

struct WatchWaitingView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "iphone.and.arrow.forward").font(.title3).foregroundStyle(WatchTheme.accent)
            Text("Open Nam Illam on your iPhone to bring your lists here.").font(.footnote)
        }
        .padding(.vertical, 4)
    }
}
