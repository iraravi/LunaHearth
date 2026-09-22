import Foundation

struct AssignedShoppingItem: Identifiable, Sendable, Codable, Equatable {
    let id: UUID
    let name: String
    let quantity: String
    let store: String
    let later: Bool
    let day: String?

    func neededNow(today: String) -> Bool { !later || (day.map { $0 <= today } ?? false) }
}

struct ShoppingBrief: Sendable {
    let text: String
    let usedModel: Bool
}

protocol ShoppingBriefService: Sendable {
    func summarize(_ items: [AssignedShoppingItem], today: String) async throws -> ShoppingBrief
}

protocol HouseholdPushService: Sendable {
    func enableChangeNotifications(in destination: SyncDestination) async throws
}

enum AssignedShoppingRules {
    static func summary(_ items: [AssignedShoppingItem], today: String) -> String {
        guard !items.isEmpty else { return "You’re all caught up. Nothing is assigned to you." }
        let now = items.filter { $0.neededNow(today: today) }.count
        let stores = Set(items.map(\.store).filter { !$0.isEmpty }).count
        return "\(items.count) \(items.count == 1 ? "item" : "items") assigned to you. \(now) needed now, \(items.count - now) for later. \(stores) selected \(stores == 1 ? "store" : "stores")."
    }

    /// Compare active assignments, not modification timestamps: quantity edits must not repeat alerts.
    static func newlyAssigned(previous: Set<UUID>, current: Set<UUID>) -> Set<UUID> {
        current.subtracting(previous)
    }
}

@MainActor protocol ShoppingNotificationService {
    func requestPermission() async throws -> Bool
    func post(identifier: String, newCount: Int) async throws
    func clear(identifier: String)
}
