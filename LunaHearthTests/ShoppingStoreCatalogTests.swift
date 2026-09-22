import Foundation
import Testing
@testable import LunaHearth

struct ShoppingStoreCatalogTests {
    @Test func chainSpellingsAndAliasesResolve() {
        #expect(ShoppingStoreCatalog.canonicalName("  wal MART ") == "Walmart")
        #expect(ShoppingStoreCatalog.canonicalName("D-Mart") == "DMart")
        #expect(ShoppingStoreCatalog.canonicalName("whole foods") == "Whole Foods Market")
        #expect(ShoppingStoreCatalog.canonicalName("Sam's Club") == "Sam’s Club")
    }
    @Test func localShopsDeduplicateWithoutMergingBranches() {
        let saved = ["Corner Shop", "corner  shop", "Walmart Plano", "Walmart Frisco", " "]
        #expect(ShoppingStoreCatalog.savedNames(saved) == ["Corner Shop", "Walmart Frisco", "Walmart Plano"])
        #expect(ShoppingStoreCatalog.canonicalName(" corner\nshop ", saved: saved) == "Corner Shop")
        #expect(ShoppingStoreCatalog.canonicalName("Walmart Plano") != "Walmart")
        #expect(ShoppingStoreCatalog.canonicalName("அம்மா கடை") == "அம்மா கடை")
    }
    @Test func searchFiltersCountryAndAvoidsSavedDuplicates() {
        #expect(ShoppingStoreCatalog.suggestions(query: "d mart", region: .india, excluding: []).map(\.name) == ["DMart", "DMart Ready"])
        #expect(ShoppingStoreCatalog.suggestions(query: "walmart", region: .india, excluding: []).isEmpty)
        #expect(ShoppingStoreCatalog.suggestions(query: "wal mart", region: .us, excluding: ["WALMART"]).isEmpty)
        #expect(ShoppingStoreCatalog.suggestions(query: "whole foods", region: .us, excluding: []).map(\.name) == ["Whole Foods Market"])
    }
    @MainActor @Test func manualAndSuggestedItemsUseTheSameStore() throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "Ravi", members: [])
        var draft = EntryDraft(kind: .grocery, title: "Milk")
        draft.storeName = "Wal Mart"
        try repo.add(draft)
        let id = try #require(repo.household?.id)
        _ = try repo.addShoppingSuggestions([ShoppingSuggestion(name: "Eggs")], householdID: id, store: "WALMART", buyer: nil)
        #expect(repo.groceries.count == 2)
        #expect(Set(repo.groceries.compactMap(\.storeName)) == ["Walmart"])
    }
}
