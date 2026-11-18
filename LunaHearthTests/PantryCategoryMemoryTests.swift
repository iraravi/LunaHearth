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
