import Foundation
import Testing
@testable import LunaHearth

@MainActor struct ShoppingSuggestionsTests {
    @Test func pantryRiceIsExcludedFromFallbackAndSave() throws {
        let request = ShoppingSuggestionRequest(prompt: "", recentItems: ["Rice", "Chicken"], pendingItems: [], pantryItems: [" rice "])
        #expect(ShoppingSuggestionRules.fallback(request, reason: "Fallback").items.map(\.name) == ["Chicken"])
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "Ravi", members: [])
        let id = try #require(repo.household?.id)
        var rice = InventoryDraft(); rice.name = "Rice"
        try repo.saveInventory(rice)
        #expect(try repo.addShoppingSuggestions([.init(name: "RICE"), .init(name: "Chicken")], householdID: id, store: "", buyer: nil) == 1)
        #expect(repo.groceries.map(\.name) == ["Chicken"])
        let pack = try #require(repo.inventory.first)
        pack.isLowStock = true
        #expect(!repo.stockedShoppingSuggestionNames.contains("Rice"))
        pack.isLowStock = false; pack.isUsedUp = true
        #expect(repo.stockedShoppingSuggestionNames.isEmpty)
        pack.isUsedUp = false; pack.expiryDay = "2000-01-01"
        #expect(repo.stockedShoppingSuggestionNames.isEmpty)
    }

    @Test func suggestionsValidateBoundAndExcludeExistingItems() {
        let items = [ShoppingSuggestion(name: " MILK "), ShoppingSuggestion(name: ""), ShoppingSuggestion(name: "Eggs"), ShoppingSuggestion(name: "eggs"), ShoppingSuggestion(name: String(repeating: "x", count: 201))]
        let reviewed = ShoppingSuggestionRules.reviewed(items, excluding: ["milk"])
        #expect(reviewed.map(\.name) == ["Eggs"])
        #expect(ShoppingSuggestionRules.reviewed((0..<30).map { ShoppingSuggestion(name: "Item \($0)") }, excluding: []).count == 8)
    }

    @Test func fallbackIsExplicitAndUsesOnlyProvidedHistory() {
        let request = ShoppingSuggestionRequest(prompt: "", recentItems: ["Soap", "MILK", "Soap"], pendingItems: ["Milk"])
        let result = ShoppingSuggestionRules.fallback(request, reason: "Model unavailable.")
        #expect(!result.usedModel)
        #expect(result.items.map(\.name) == ["Soap"])
        #expect(result.explanation.contains("not AI-generated"))
    }

    @Test func dishRequestNeverFallsBackToUnrelatedHistoryOrBasics() {
        for plan in ["Chicken biryani", "chicken briyani", "chicken biriyani", "Vegetarian dinner without chicken"] {
            let request = ShoppingSuggestionRequest(prompt: plan, recentItems: ["Lentils", "Soap"], pendingItems: [], pantryItems: ["Rice"])
            let result = ShoppingSuggestionRules.fallback(request, reason: "AI unavailable.")
            #expect(request.relevantHistory.isEmpty)
            #expect(result.items.isEmpty)
            #expect(!result.usedModel)
            #expect(result.explanation.contains("No ingredients were generated"))
        }
        let general = ShoppingSuggestionRequest(prompt: " \n ", recentItems: ["Lentils"], pendingItems: [])
        #expect(general.relevantHistory == ["Lentils"])
        #expect(ShoppingSuggestionRules.fallback(general, reason: "Offline").items.map(\.name) == ["Lentils"])
    }

    @Test func mainIngredientSurvivesPantryAndListReviewUnlessAlreadyRecorded() {
        let generated: [ShoppingSuggestion] = [.init(name: "Chicken"), .init(name: "Rice"), .init(name: "Onion")]
        #expect(ShoppingSuggestionRules.reviewed(generated, excluding: ["Rice"]).map(\.name) == ["Chicken", "Onion"])
        #expect(ShoppingSuggestionRules.reviewed(generated, excluding: ["Rice", "chicken"]).map(\.name) == ["Onion"])
    }

    @Test func reviewIsRequiredAndBatchIsAtomicWithDuplicateAndHouseholdChecks() throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "Ravi", members: [])
        let id = try #require(repo.household?.id), buyer = try #require(repo.members.first?.id)
        let ideas = ShoppingSuggestionRules.fallback(ShoppingSuggestionRequest(prompt: "", recentItems: ["Milk", "Eggs"], pendingItems: []), reason: "Fallback")
        #expect(repo.groceries.isEmpty)
        try repo.add(EntryDraft(kind: .grocery, title: "Milk"))
        #expect(throws: HouseholdValidation.self) { try repo.addShoppingSuggestions(ideas.items, householdID: UUID(), store: "Market", buyer: buyer) }
        #expect(throws: HouseholdValidation.self) { try repo.addShoppingSuggestions([ShoppingSuggestion(name: "Bread"), ShoppingSuggestion(name: "")], householdID: id, store: "Market", buyer: buyer) }
        #expect(repo.groceries.count == 1)
        let count = try repo.addShoppingSuggestions(ideas.items, householdID: id, store: "Market", buyer: buyer, neededLater: true)
        #expect(count == 1)
        let egg = try #require(repo.groceries.first { $0.name == "Eggs" })
        #expect(egg.assignedMemberID == buyer)
        #expect(egg.storeName == "Market")
        #expect(egg.neededLater == true)
        #expect(try repo.addShoppingSuggestions(ideas.items, householdID: id, store: "Market", buyer: buyer) == 0)
        #expect(repo.groceries.count == 2)
    }
}
