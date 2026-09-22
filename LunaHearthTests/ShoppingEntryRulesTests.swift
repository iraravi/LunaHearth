import Foundation
import Testing
@testable import LunaHearth

@MainActor struct ShoppingEntryRulesTests {
    @Test func amountsAndUnitsAreValidatedWithoutGuessing() throws {
        #expect(try ShoppingEntryRules.quantityText("2", unit: .piece) == "2 pieces")
        #expect(try ShoppingEntryRules.quantityText("1", unit: .piece) == "1 piece")
        #expect(try ShoppingEntryRules.quantityText("0,5", unit: .kg) == "0.5 kg")
        #expect(try ShoppingEntryRules.quantityText("2.25", unit: .lb) == "2.25 lb")
        #expect(try ShoppingEntryRules.quantityText("", unit: .piece).isEmpty)
        #expect(try ShoppingEntryRules.quantityText("small bunch", unit: .custom) == "small bunch")
        for invalid in ["-2", "0", "2 tomatoes", "1,2,3", "NaN", "1000001", "1.2345"] {
            #expect(throws: ShoppingEntryError.self) { try ShoppingEntryRules.quantityText(invalid, unit: .kg) }
        }
    }
    @Test func shoppingDatesAreCivilDaysAcrossTimeZones() throws {
        let india = try #require(TimeZone(identifier: "Asia/Kolkata"))
        let chicago = try #require(TimeZone(identifier: "America/Chicago"))
        for zone in [india, chicago] {
            let date = try #require(ShoppingEntryRules.date(for: "2026-11-01", timeZone: zone))
            #expect(HouseholdDay(date, timeZone: zone).key == "2026-11-01")
        }
        #expect(ShoppingEntryRules.date(for: "2026-02-30") == nil)
        #expect(ShoppingEntryRules.date(for: "tomorrow") == nil)
    }
    private func repo() throws -> LocalHouseholdRepository {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "", members: [])
        return repo
    }
    @Test func duplicateItemRequiresExplicitSeparateEntryAndIgnoresCompleted() throws {
        let repo = try repo()
        try repo.add(EntryDraft(kind: .grocery, title: "Tomato"))
        var duplicate = EntryDraft(kind: .grocery, title: " tomato ")
        #expect(repo.duplicateShoppingItem(duplicate.title) != nil)
        #expect(throws: ShoppingEntryError.self) { try repo.add(duplicate) }
        #expect(repo.groceries.count == 1)
        duplicate.allowDuplicateShoppingItem = true
        try repo.add(duplicate)
        #expect(repo.groceries.count == 2)
        for item in repo.groceries { try repo.toggle(item) }
        #expect(repo.duplicateShoppingItem("tomato") == nil)
    }
    @Test func quantitiesDatesAndEditsSurvivePrivateBackup() throws {
        let repo = try repo()
        let day = try #require(ShoppingEntryRules.date(for: "2026-11-01"))
        try repo.add(EntryDraft(kind: .grocery, title: "Tomato", quantity: "2", storeName: "DMart", neededLater: true, quantityUnit: .piece, shoppingDate: day))
        let item = try #require(repo.groceries.first)
        #expect(item.quantityText == "2 pieces")
        #expect(item.quantityAmount == "2" && item.quantityUnit == "piece")
        #expect(item.plannedDay == "2026-11-01")
        let restored = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try restored.restoreBackup(repo.makeBackup())
        let copy = try #require(restored.groceries.first)
        var draft = EntryDraft.editing(copy)
        #expect(draft.quantityUnit == .piece && draft.quantity == "2")
        #expect(HouseholdDay(draft.shoppingDate).key == "2026-11-01")
        draft.neededLater = false; draft.quantity = "0.5"; draft.quantityUnit = .kg
        try restored.add(draft)
        #expect(copy.plannedDay == nil && copy.quantityText == "0.5 kg")
    }
    @Test func legacyQuantityRemainsEditableWithoutReinterpretation() {
        let item = GroceryItem(householdID: UUID(), name: "Tomatoes", quantityText: "a large bunch")
        let draft = EntryDraft.editing(item)
        #expect(draft.quantityUnit == .custom)
        #expect(draft.quantity == "a large bunch")
    }
    @Test func duplicateStoreMessageMatchesTheSaveRule() throws {
        let repo = try repo()
        let store = try repo.addStore(name: "Anand Stores", branch: "Adyar")
        #expect(repo.matchingStore("anand stores", branch: " ADYAR ")?.id == store.id)
        #expect(repo.matchingStore("Anand Stores", branch: "Mylapore") == nil)
        #expect(try repo.addStore(name: "anand stores", branch: " ADYAR ").id == store.id)
    }
}
