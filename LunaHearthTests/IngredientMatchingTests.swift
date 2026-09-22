import Foundation
import Testing
@testable import LunaHearth

struct IngredientMatchingTests {
    @Test func aliasesNormalizeWithoutLosingIngredientForms() {
        for name in ["Cumin", "cumin seed", " CUMIN—SEEDS ", "jeera", "Jeeragam", "seeragam"] {
            #expect(IngredientMatching.same(name, "Cumin seeds"))
        }
        #expect(IngredientMatching.same("tuvar dal", "Toor dal"))
        #expect(IngredientMatching.same("aval", "poha"))
        #expect(IngredientMatching.same("tomatoes", "tomato"))
        #expect(IngredientMatching.same("ground cumin", "cumin powder"))
        for (a, b) in [("cumin", "cumin powder"), ("coriander seeds", "coriander leaves"),
                       ("rice", "basmati rice"), ("milk", "oat milk"), ("chana dal", "chickpeas"),
                       ("urad dal", "whole urad dal"), ("mustard seeds", "black mustard seeds"),
                       ("fresh turmeric", "turmeric powder"), ("", "")] {
            #expect(!IngredientMatching.same(a, b))
        }
    }
    @Test func ingredientSearchDoesNotConfuseCuminWithRice() {
        for name in ["Cumin", "Cumin seeds", "Jeera", "Organic jeeragam"] {
            #expect(IngredientMatching.matchesSearch(name, query: "cumin"))
            #expect(IngredientMatching.matchesSearch(name, query: "jeera"))
        }
        for name in ["Rice", "Basmati rice", "Rice flour", "Price label"] {
            #expect(!IngredientMatching.matchesSearch(name, query: "cumin"))
        }
        #expect(!IngredientMatching.matchesSearch("Cumin powder", query: "cumin seeds"))
        #expect(!IngredientMatching.matchesSearch("Whole cumin", query: "cumin powder"))
        #expect(IngredientMatching.matchesSearch("Organic ground cumin", query: "cumin powder"))
        #expect(IngredientMatching.matchesSearch("Jeera", query: "  CUM  "))
        #expect(!IngredientMatching.matchesSearch("Price label", query: "rice"))
        #expect(IngredientMatching.matchesSearch("Rice", query: " "))
    }
    @Test func typosAreOnlySoftMatches() {
        #expect(IngredientMatching.possibleTypo("cummin", "cumin"))
        #expect(!IngredientMatching.same("cummin", "cumin"))
        #expect(!IngredientMatching.possibleTypo("rice", "mice"))
        #expect(!IngredientMatching.possibleTypo("cumin powder", "cumin seeds"))
        #expect(!IngredientMatching.possibleTypo(String(repeating: "x", count: 201), String(repeating: "x", count: 200)))
    }
    @Test func suggestionsDeduplicateRegionalNamesAndRespectExisting() {
        let names = PantrySuggestionRules.reviewed(["Cumin seeds", "cumin", "Jeera", "Ground cumin", "Cumin powder", "Toor dal", "Arhar dal"], existing: [])
        #expect(names == ["Cumin seeds", "Ground cumin", "Toor dal"])
        #expect(PantrySuggestionRules.reviewed(["cumin seeds", "cumin powder"], existing: ["jeera"]) == ["cumin powder"])
        #expect(ShoppingSuggestionRules.reviewed([ShoppingSuggestion(name: "cumin seeds"), ShoppingSuggestion(name: "cumin powder")], excluding: ["jeera"]).map(\.name) == ["cumin powder"])
    }
    @MainActor @Test func pendingShoppingComparisonRespectsCompletedAndEditingItems() throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "", members: [])
        try repo.add(EntryDraft(kind: .grocery, title: "Cumin seeds"))
        let original = try #require(repo.groceries.first)
        #expect(repo.duplicateShoppingItem("Jeera")?.id == original.id)
        #expect(repo.duplicateShoppingItem("Jeera", excluding: original.id) == nil)
        try repo.recordPurchase(original, addToInventory: true)
        #expect(repo.duplicateShoppingItem("Jeera") == nil)
        try repo.add(EntryDraft(kind: .grocery, title: "Jeera"))
        let newer = try #require(repo.groceries.first { !$0.isCompleted })
        var separate = EntryDraft(kind: .grocery, title: "Cumin", storeName: "Different store")
        separate.allowDuplicateShoppingItem = true
        try repo.add(separate)
        try repo.deletePlanningEntry(id: newer.id, kind: .grocery)
        #expect(repo.inventory.count == 1 && repo.inventory.first?.sourceGroceryID == original.id)
        #expect(repo.groceries.count == 2)
        #expect(repo.groceries.contains { $0.storeName == "Different store" })
    }
    @Test func untrustedAIIndicesCannotReferenceOtherRecords() {
        #expect(IngredientComparison.validated([-1, 0, 0, 2, 3, 500], count: 3) == [0, 2])
        #expect(IngredientComparison.validated([0], count: 0).isEmpty)
    }
    @MainActor @Test func repositoryRejectsAliasesUnlessSeparatePackIsConfirmed() throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "", members: [])
        var draft = InventoryDraft(); draft.name = "Cumin"
        let original = try repo.saveInventory(draft)
        draft.name = "Jeera"; draft.quantity = "200 g"
        #expect(throws: InventoryError.self) { try repo.saveInventory(draft) }
        #expect(repo.inventory.count == 1)
        try repo.addPantryIdeas(["Cumin seeds", "Jeeragam"], householdID: try #require(repo.household?.id))
        #expect(repo.inventory.count == 1)
        let other = try repo.saveInventory(draft, allowSeparatePack: true)
        #expect(repo.inventory.count == 2)
        #expect(repo.inventory.first { $0.id == original }?.quantityText == nil)
        #expect(repo.inventory.first { $0.id == other }?.quantityText == "200 g")
        try repo.add(EntryDraft(kind: .grocery, title: "Cumin"))
        #expect(repo.duplicateShoppingItem("Jeera") != nil)
        #expect(throws: ShoppingEntryError.self) { try repo.add(EntryDraft(kind: .grocery, title: "Cumin seeds")) }
        try repo.deleteInventory(try #require(repo.inventory.first { $0.id == other }))
        #expect(repo.inventory.count == 1 && repo.inventory.first?.id == original)
        #expect(repo.groceries.count == 1)
    }
}
