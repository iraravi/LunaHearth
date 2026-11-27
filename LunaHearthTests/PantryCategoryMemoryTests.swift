import Foundation
import Testing
@testable import LunaHearth

struct PantryCategoryMemoryTests {
    @Test func wordListCoversEverydayItems() {
        #expect(PantryVisualRules.category("Mushrooms") == .produce)
        #expect(PantryVisualRules.category("Greek yoghurt") == .chilled)
        #expect(PantryVisualRules.category("Tomato ketchup") == .essentials)
        #expect(PantryVisualRules.category("Whole wheat tortillas") == .grains)
        #expect(PantryVisualRules.icon("Chicken thighs", category: .meat) == "🍗")
        #expect(PantryVisualRules.icon("Button mushrooms", category: .produce) == "🍄")
    }

    @Test func onlyUnrecognisedNamesAreAskedOnce() {
        let names = ["Milk", "Hummus", "hummus ", "Sriracha", "Rice"]
        let ask = PantryCategoryMemory.unknown(names, memory: [:])
        #expect(ask == ["Hummus", "Sriracha"])
        let stored = PantryCategoryMemory.remember(ask, suggestions: [PantryCategorySuggestion(index: 0, category: .chilled)], stored: "")
        let memory = PantryCategoryMemory.decode(stored)
        #expect(memory[IngredientMatching.key("Hummus")] == .chilled)
        #expect(memory[IngredientMatching.key("Sriracha")] == .other) // remembered, so not asked again
        #expect(PantryCategoryMemory.unknown(names, memory: memory).isEmpty)
    }

    @Test func rememberedCategoryReplacesTheBoxButNeverOverridesTheWordList() {
        let memory: [String: PantryCategory] = [IngredientMatching.key("Hummus"): .chilled, IngredientMatching.key("Milk"): .meat]
        #expect(PantryVisualRules.category("Hummus", memory: memory) == .chilled)
        #expect(PantryVisualRules.icon("Hummus", memory: memory) == "🥛")
        #expect(PantryVisualRules.category("Milk", memory: memory) == .chilled)
        #expect(PantryVisualRules.icon("Mystery item", memory: [:]) == "📦")
        #expect(PantryCategoryMemory.decode("not json").isEmpty)
    }
}

struct PantryHouseholdCategoryTests {
    @Test func commonNonFoodWordsAreHouseholdOffline() {
        #expect(PantryVisualRules.category("Dish soap") == .household)
        #expect(PantryVisualRules.category("Paper towels") == .household)
        #expect(PantryVisualRules.category("Basmati rice") == .grains)
    }

    @Test func aiOrPersonCanMarkABrandAsNotFood() {
        // "Method body" has no word the offline list knows; the AI answer or the editor toggle places it.
        #expect(PantryVisualRules.isFood("Method body", memory: [:]))
        let stored = PantryCategoryMemory.setHousehold("Method body", true, stored: "")
        let memory = PantryCategoryMemory.decode(stored)
        #expect(!PantryVisualRules.isFood("Method body", memory: memory))
        let cleared = PantryCategoryMemory.decode(PantryCategoryMemory.setHousehold("Method body", false, stored: stored))
        #expect(PantryVisualRules.isFood("Method body", memory: cleared))
    }

    @Test func personsNotFoodChoiceBeatsTheWordList() {
        // "Coconut oil" reads as essentials, but someone bought it as hair oil.
        let memory = PantryCategoryMemory.decode(PantryCategoryMemory.setHousehold("Coconut oil", true, stored: ""))
        #expect(PantryVisualRules.category("Coconut oil", memory: memory) == .household)
        #expect(PantryVisualRules.category("Coconut oil", memory: [:]) == .essentials)
    }
}
