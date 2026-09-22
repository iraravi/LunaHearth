import Foundation
import Testing
@testable import LunaHearth

@MainActor struct ShoppingSuggestionsTests {
    @Test func suggestionsValidateBoundAndExcludeExistingItems() {
        let items = [ShoppingSuggestion(name: " MILK "), ShoppingSuggestion(name: ""), ShoppingSuggestion(name: "Eggs"), ShoppingSuggestion(name: "eggs"), ShoppingSuggestion(name: String(repeating: "x", count: 201))]
        let reviewed = ShoppingSuggestionRules.reviewed(items, excluding: ["milk"])
        #expect(reviewed.map(\.name) == ["Eggs"])
        #expect(ShoppingSuggestionRules.reviewed((0..<30).map { ShoppingSuggestion(name: "Item \($0)") }, excluding: []).count == 8)
    }

    @Test func fallbackIsExplicitAndUsesOnlyProvidedHistory() {
        let request = ShoppingSuggestionRequest(prompt: "Dinner", recentItems: ["Soap", "MILK", "Soap"], pendingItems: ["Milk"])
        let result = ShoppingSuggestionRules.fallback(request, reason: "Model unavailable.")
        #expect(!result.usedModel)
        #expect(result.items.map(\.name) == ["Soap"])
        #expect(result.explanation.contains("not AI-generated"))
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
