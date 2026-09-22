import Testing
@testable import LunaHearth

struct PantryVisualRulesTests {
    @Test func familiarItemIconsHandlePluralAndPreparation() {
        let examples: [(String, PantryCategory, String)] = [
            ("Banana", .produce, "🍌"), ("Organic bananas", .produce, "🍌"),
            ("BANANAS", .produce, "🍌"), ("Water", .essentials, "💧"),
            ("Bottled water", .essentials, "💧"), ("Coconut water", .essentials, "💧"),
            ("Sparkling water", .essentials, "💧"), ("Watermelon", .produce, "🍉"),
            ("Banana leaves", .produce, "🥬"), ("Banana bread", .grains, "🍞"),
            ("Coconut oil", .essentials, "🫙"), ("Orange juice", .essentials, "🧃"),
            ("Coffee", .essentials, "☕️"), ("Fresh tomatoes", .produce, "🍅"),
            ("Strawberries", .produce, "🍓"), ("Spinach", .produce, "🥬"),
            ("Family special", .other, "📦")
        ]
        for (name, category, icon) in examples {
            #expect(PantryVisualRules.category(name) == category)
            #expect(PantryVisualRules.icon(name, category: category) == icon)
        }
        #expect(!IngredientMatching.same("banana", "banana leaves"))
    }
    @Test func regionalAliasesShareVisualCategories() {
        #expect(PantryVisualRules.category("Jeeragam") == .spices)
        #expect(PantryVisualRules.category("Arhar dal") == .pulses)
        #expect(PantryVisualRules.category("Aval") == .grains)
        #expect(PantryVisualRules.category("Tomatoes") == .produce)
        #expect(PantryVisualRules.icon("tomatoes", category: .produce) == "🍅")
    }
    @Test func preparationsAndUnknownNamesAreConservative() {
        #expect(PantryVisualRules.category("Coconut oil") == .essentials)
        #expect(PantryVisualRules.category("Chickpea flour") == .grains)
        #expect(PantryVisualRules.category("Coriander leaves") == .produce)
        #expect(PantryVisualRules.category("Coriander seeds") == .spices)
        #expect(PantryVisualRules.category("Eggs") == .chilled)
        #expect(PantryVisualRules.category("Family special") == .other)
        #expect(PantryVisualRules.category("") == .other)
    }
}
