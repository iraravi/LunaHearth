import Foundation
import SwiftData
import Testing
@testable import LunaHearth

struct TodayAttentionTests {
    private func shopping(_ name: String, later: Bool = false, day: String? = nil) -> AssignedShoppingItem {
        AssignedShoppingItem(id: UUID(), name: name, quantity: "", store: "", later: later, day: day)
    }
    private func pack(_ name: String, expiry: String? = nil, used: Bool = false, low: Bool = false) -> TodayPantryItem {
        TodayPantryItem(id: UUID(), name: name, expiryDay: expiry, isUsedUp: used, isLowStock: low)
    }

    @Test func shoppingPrioritizesOverdueAndLeavesUndatedLaterAlone() {
        let items = [shopping("Now"), shopping("Tomorrow", later: true, day: "2026-09-14"),
                     shopping("Today", later: true, day: "2026-09-13"), shopping("Old", later: true, day: "2026-09-11"),
                     shopping("Undated", later: true), shopping("Invalid", later: true, day: "2026-02-30")]
        let due = TodayAttentionRules.shopping(items, today: "2026-09-13")
        #expect(due.map(\.name) == ["Old", "Now", "Today"])
        #expect(due.filter { TodayAttentionRules.isOverdue($0, today: "2026-09-13") }.map(\.name) == ["Old"])
    }

    @Test func datesCrossYearAndDaylightSavingsWithoutRecommendingExpiredFood() {
        let items = [pack("Past", expiry: "2026-12-30"), pack("Today", expiry: "2026-12-31"),
                     pack("Seven", expiry: "2027-01-07"), pack("Eight", expiry: "2027-01-08"),
                     pack("Used", expiry: "2026-12-01", used: true), pack("Unknown"), pack("Invalid", expiry: "bad")]
        #expect(TodayAttentionRules.dates(items, today: "2026-12-31").map(\.name) == ["Past", "Today", "Seven"])
        #expect(TodayAttentionRules.dates([pack("DST", expiry: "2026-03-14")], today: "2026-03-07").count == 1)
        #expect(TodayAttentionRules.dates([pack("DST", expiry: "2026-03-15")], today: "2026-03-07").isEmpty)
    }

    @Test func restockGroupsAliasesAndExcludesUsedPacks() {
        let items = [pack("Cumin", low: true), pack("Cumin seeds", low: true), pack("Milk", used: true, low: true), pack("Rice")]
        #expect(TodayAttentionRules.restock(items).count == 1)
        #expect(IngredientMatching.same(TodayAttentionRules.restock(items)[0].name, "Cumin seeds"))
    }

    @Test func dailyBriefHasExactFallbackAndOnlyCountsAreEncoded() throws {
        let empty = TodayBriefFacts(shoppingNeededNow: 0, shoppingOverdue: 0, pantryDatesToCheck: 0, pantryPastExpiry: 0, lowStockIngredients: 0, eventsToday: 0, remindersDue: 0, homeCareAlerts: 0)
        #expect(empty.fallback == "Nothing needs attention in your saved lists today.")
        let facts = TodayBriefFacts(shoppingNeededNow: 3, shoppingOverdue: 1, pantryDatesToCheck: 2, pantryPastExpiry: 1, lowStockIngredients: 1, eventsToday: 0, remindersDue: 0, homeCareAlerts: 0)
        #expect(facts.fallback == "3 shopping items needed now · 2 pantry dates to check · 1 low-stock ingredient.")
        let payload = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(facts)) as? [String: Int])
        #expect(payload.count == 8)
    }

    @MainActor @Test func todayUsesSelectedMemberAndLocalRestockNeverDuplicates() throws {
        let repository = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repository.createHousehold(name: "Home", owner: "Ravi", members: [("Kira", .adult)])
        let member = try #require(repository.members.first { $0.displayName == "Ravi" })
        var assigned = EntryDraft(kind: .grocery, title: "Milk"); assigned.memberID = member.id
        try repository.add(assigned)
        try repository.add(EntryDraft(kind: .grocery, title: "Bread"))
        var draft = InventoryDraft(); draft.name = "Cumin seeds"; draft.isLowStock = true
        let id = try repository.saveInventory(draft)
        let item = try #require(repository.inventory.first { $0.id == id })
        let suite = "today-tests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let personal = PersonalShopping(defaults: defaults, notifications: TodayTestNotifications())
        #expect(TodayAttentionData(repository: repository, personal: personal, now: .now).shopping.count == 2)
        personal.select(member.id, repository: repository)
        #expect(TodayAttentionData(repository: repository, personal: personal, now: .now).shopping.map(\.name) == ["Milk"])
        try repository.restockInventory(item)
        #expect(throws: InventoryError.self) { try repository.restockInventory(item) }
        #expect(repository.groceries.filter { IngredientMatching.same($0.name, "Cumin") }.count == 1)
        #expect(item.isLowStock == true && !item.isUsedUp)
    }
}

@MainActor private final class TodayTestNotifications: ShoppingNotificationService {
    func requestPermission() async throws -> Bool { false }
    func post(identifier: String, newCount: Int) async throws {}
    func clear(identifier: String) {}
}
