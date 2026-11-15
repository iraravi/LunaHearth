import Foundation
import Testing
@testable import LunaHearth

struct RepeatPurchaseRulesTests {
    private func bought(_ name: String, _ days: [String], quantity: String = "", store: String = "") -> [RepeatPurchaseRecord] {
        days.map { RepeatPurchaseRecord(name: name, quantity: quantity, merchant: store, day: $0) }
    }

    @Test func dueOnceTheUsualGapHasPassed() throws {
        let history = bought("Milk", ["2026-11-01", "2026-11-07", "2026-11-13"], quantity: "1 carton", store: "Kroger")
        #expect(RepeatPurchaseRules.due(history, today: "2026-11-18").isEmpty)
        let item = try #require(RepeatPurchaseRules.due(history, today: "2026-11-19").first)
        #expect(item.name == "Milk" && item.intervalDays == 6 && item.daysSince == 6)
        #expect(item.quantity == "1 carton" && item.store == "Kroger" && item.lastDay == "2026-11-13")
        #expect(item.detail == "Usually every 6 days · last bought 6 days ago")
    }

    @Test func needsThreeDifferentPurchaseDays() {
        let twice = bought("Eggs", ["2026-11-01", "2026-11-08"])
        #expect(RepeatPurchaseRules.due(twice, today: "2026-11-20").isEmpty)
        let sameDayRepeats = bought("Eggs", ["2026-11-01", "2026-11-01", "2026-11-08", "2026-11-08"])
        #expect(RepeatPurchaseRules.due(sameDayRepeats, today: "2026-11-20").isEmpty)
    }

    @Test func oneOddGapDoesNotSkewTheRhythm() throws {
        // Gaps 7, 7, 30, 7 → median 7.
        let history = bought("Bread", ["2026-09-01", "2026-09-08", "2026-09-15", "2026-10-15", "2026-10-22"])
        let item = try #require(RepeatPurchaseRules.due(history, today: "2026-10-29").first)
        #expect(item.intervalDays == 7)
    }

    @Test func skipsItemsAlreadyOnTheListUnderAnotherSpelling() {
        let history = bought("Jeera", ["2026-10-01", "2026-10-11", "2026-10-21"])
        #expect(RepeatPurchaseRules.due(history, today: "2026-11-01", excluding: ["cumin seeds"]).isEmpty)
        #expect(RepeatPurchaseRules.due(history, today: "2026-11-01").count == 1)
    }

    @Test func dropsHabitsThatStoppedAndOutOfRangeGaps() {
        let weekly = bought("Yogurt", ["2026-08-01", "2026-08-08", "2026-08-15"])
        #expect(RepeatPurchaseRules.due(weekly, today: "2026-08-29").count == 1)
        #expect(RepeatPurchaseRules.due(weekly, today: "2026-09-10").isEmpty)
        let daily = bought("Banana", ["2026-11-01", "2026-11-02", "2026-11-03"])
        #expect(RepeatPurchaseRules.due(daily, today: "2026-11-04").isEmpty)
        let rare = bought("Basmati", ["2026-01-01", "2026-05-01", "2026-09-01"])
        #expect(RepeatPurchaseRules.due(rare, today: "2026-11-01").isEmpty)
    }

    @Test func ignoresFutureAndMalformedDays() {
        let history = bought("Milk", ["2026-11-01", "2026-11-07", "bad", "2026-02-30", "2026-12-01"])
        #expect(RepeatPurchaseRules.due(history, today: "2026-11-20").isEmpty)
    }

    @Test func mostOverdueFirstAndUsualQuantityWins() {
        let history = bought("Milk", ["2026-11-01", "2026-11-05", "2026-11-09"], quantity: "1 carton")
            + [RepeatPurchaseRecord(name: "Milk", quantity: "2 cartons", merchant: "", day: "2026-11-09")]
            + bought("Rice", ["2026-09-11", "2026-10-01", "2026-10-21"], quantity: "5 kg") // 25 of 20 days vs Milk 6 of 4
        let due = RepeatPurchaseRules.due(history, today: "2026-11-15")
        #expect(due.map(\.name) == ["Milk", "Rice"])
        #expect(due.first?.quantity == "1 carton")
    }

    @Test func snoozeHidesUntilTheNextDueDay() throws {
        let history = bought("Milk", ["2026-11-01", "2026-11-07", "2026-11-13"])
        let item = try #require(RepeatPurchaseRules.due(history, today: "2026-11-19").first)
        let until = try #require(RepeatPurchaseRules.snoozeUntil(item, today: "2026-11-19"))
        #expect(until == "2026-11-25")
        #expect(RepeatPurchaseRules.due(history, today: "2026-11-25", snoozed: [item.key: until]).isEmpty)
        #expect(RepeatPurchaseRules.due(history, today: "2026-11-26", snoozed: [item.key: until]).count == 1)
    }

    @Test func gapsIgnoreDaylightSavingChanges() {
        #expect(RepeatPurchaseRules.dayNumber("2026-11-02")! - RepeatPurchaseRules.dayNumber("2026-10-31")! == 2)
        #expect(RepeatPurchaseRules.dayKey(RepeatPurchaseRules.dayNumber("2026-03-08")! + 1) == "2026-03-09")
    }

    @Test func snoozesAreStoredPerHousehold() throws {
        let item = try #require(RepeatPurchaseRules.due(bought("Milk", ["2026-11-01", "2026-11-07", "2026-11-13"]), today: "2026-11-19").first)
        let home = UUID(), other = UUID()
        let now = try #require(ShoppingEntryRules.date(for: "2026-11-19"))
        let stored = BuyAgainSnoozes.snooze(item, householdID: home, stored: "", now: now)
        #expect(BuyAgainSnoozes.decode(stored, householdID: home) == [item.key: "2026-11-25"])
        #expect(BuyAgainSnoozes.decode(stored, householdID: other).isEmpty)
        #expect(BuyAgainSnoozes.decode("not json", householdID: home).isEmpty)
    }
}

@MainActor struct BuyAgainRepositoryTests {
    @Test func checkedOffShoppingBuildsSuggestionsAndAddUsesTheUsualStore() throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "Owner", members: [])
        let home = try #require(repo.household?.id)
        try repo.commit {
            for (index, day) in ["2026-11-01", "2026-11-07", "2026-11-13"].enumerated() {
                let grocery = GroceryItem(householdID: home, name: "Milk", quantityText: "1 carton", storeName: index == 2 ? "Kroger" : nil, isCompleted: true)
                repo.context.insert(grocery)
                repo.appendPurchase(id: UUID(), purchaseID: UUID(), grocery: grocery, inventoryID: nil, expenseID: nil, day: day, action: "elsewhere")
            }
        }
        let now = try #require(ShoppingEntryRules.date(for: "2026-11-20"))
        let item = try #require(repo.buyAgainSuggestions(now: now).first)
        #expect(item.name == "Milk" && item.store == "Kroger" && item.quantity == "1 carton")

        try repo.addBuyAgain(item)
        let added = try #require(repo.groceries.first { !$0.isCompleted })
        #expect(added.name == "Milk" && added.quantityText == "1 carton")
        #expect(repo.shoppingStoreName(for: added) == "Kroger")
        #expect(repo.buyAgainSuggestions(now: now).isEmpty)
        #expect(throws: InventoryError.self) { try repo.addBuyAgain(item) }
    }
}
