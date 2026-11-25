import Foundation

/// What the iPhone sends the watch: a small, read-only picture of the shopping list and
/// today's tasks. The iPhone stays the source of truth; the watch only sends back actions.
/// Compiled into both the iPhone app and the watch app.
struct WatchSnapshot: Codable, Sendable, Equatable {
    struct Item: Codable, Sendable, Equatable, Identifiable {
        var id: UUID
        var name: String
        /// Amount and store, already formatted for a small screen ("2 lb · Costco").
        var detail: String?
        /// Aisle heading such as "Produce"; items are grouped by it in the store.
        var aisle: String
        var aisleOrder: Int
        var isBought: Bool
    }

    struct Task: Codable, Sendable, Equatable, Identifiable {
        var id: UUID
        var title: String
        var dueAt: Date?
        var person: String?
        var isDone: Bool
    }

    var homeName: String?
    var shopping: [Item]
    var tasks: [Task]
    var updatedAt: Date
    /// Watch actions the iPhone has saved, so the watch can stop showing them as pending.
    var appliedActionIDs: [UUID]

    static let empty = WatchSnapshot(homeName: nil, shopping: [], tasks: [], updatedAt: .distantPast, appliedActionIDs: [])

    var itemsLeft: Int { shopping.filter { !$0.isBought }.count }
    var tasksLeft: Int { tasks.filter { !$0.isDone }.count }
    /// The next open task: the earliest due first, then undated ones.
    var nextTask: Task? {
        tasks.filter { !$0.isDone }.min { ($0.dueAt ?? .distantFuture) < ($1.dueAt ?? .distantFuture) }
    }

    /// Open items grouped by aisle in store order, then bought items in one group at the end.
    var aisles: [(name: String, items: [Item])] {
        let open = shopping.filter { !$0.isBought }
        let grouped = Dictionary(grouping: open, by: \.aisle)
        var result = grouped.map { (name: $0.key, items: $0.value.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) }
            .sorted { ($0.items.first?.aisleOrder ?? 0, $0.name) < ($1.items.first?.aisleOrder ?? 0, $1.name) }
        let bought = shopping.filter(\.isBought)
        if !bought.isEmpty { result.append((name: "Bought", items: bought)) }
        return result
    }

    /// Shows an action on the watch straight away, before the iPhone confirms it.
    func applying(_ action: WatchAction) -> WatchSnapshot {
        var copy = self
        switch action.kind {
        case .setBought(let id, let bought):
            if let index = copy.shopping.firstIndex(where: { $0.id == id }) { copy.shopping[index].isBought = bought }
        case .setDone(let id, let done):
            if let index = copy.tasks.firstIndex(where: { $0.id == id }) { copy.tasks[index].isDone = done }
        case .add:
            break
        }
        return copy
    }

    func encoded() throws -> Data { try WatchLink.encoder.encode(self) }
    static func decoded(_ data: Data) throws -> WatchSnapshot { try WatchLink.decoder.decode(WatchSnapshot.self, from: data) }
}

/// One thing done on the watch. Actions say the end state ("bought", "done"), so a repeated
/// delivery changes nothing.
struct WatchAction: Codable, Sendable, Equatable, Identifiable {
    enum Kind: Codable, Sendable, Equatable {
        case setBought(UUID, Bool)
        case setDone(UUID, Bool)
        /// Words dictated or typed on the watch; the iPhone reads them into items.
        case add(String)
    }

    var id = UUID()
    var kind: Kind
    var createdAt = Date()

    func encoded() throws -> Data { try WatchLink.encoder.encode(self) }
    static func decoded(_ data: Data) throws -> WatchAction { try WatchLink.decoder.decode(WatchAction.self, from: data) }
}

enum WatchLink {
    /// Keys in WatchConnectivity dictionaries.
    static let snapshotKey = "snapshot"
    static let actionKey = "action"
    /// App group shared by the watch app and its widgets.
    static let appGroup = "group.com.neuralluna.lunahearth.watch"
    static let storedSnapshotKey = "watch.snapshot.v1"
    static let pendingActionsKey = "watch.pendingActions.v1"
    /// Longest text accepted from the watch.
    static let maxAddLength = 300

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .secondsSince1970; return encoder
    }()
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .secondsSince1970; return decoder
    }()
}
