import Foundation

enum PantryCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case grains, pulses, spices, produce, chilled, essentials, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .grains: "Rice & grains"
        case .pulses: "Dals & beans"
        case .spices: "Spices"
        case .produce: "Fruit & vegetables"
        case .chilled: "Dairy & eggs"
        case .essentials: "Everyday essentials"
        case .other: "Other items"
        }
    }
    var icon: String {
        switch self {
        case .grains: "🌾"
        case .pulses: "🫘"
        case .spices: "🌶️"
        case .produce: "🥬"
        case .chilled: "🥛"
        case .essentials: "🫙"
        case .other: "📦"
        }
    }
}

enum PantryVisualRules {
    // Visual vocabulary only; never broadens duplicate/ingredient identity rules.
    private static func visualWords(_ name: String) -> Set<String> {
        let singulars = [
            "bananas": "banana", "apples": "apple", "oranges": "orange",
            "grapes": "grape", "strawberries": "strawberry", "watermelons": "watermelon",
            "mangoes": "mango", "mangos": "mango", "pineapples": "pineapple",
            "avocados": "avocado", "cucumbers": "cucumber", "carrots": "carrot",
            "lemons": "lemon", "coconuts": "coconut", "tomatoes": "tomato",
            "potatoes": "potato", "onions": "onion", "eggs": "egg", "leaf": "leaves"
        ]
        return Set(IngredientMatching.key(name).split(separator: " ").map {
            singulars[String($0)] ?? String($0)
        })
    }
    static func category(_ name: String) -> PantryCategory {
        let words = visualWords(name)
        // More specific preparations take precedence over their source ingredient.
        if !words.isDisjoint(with: ["oil", "ghee", "sugar", "jaggery", "salt", "tea", "coffee", "honey", "sauce", "vinegar", "water", "juice"]) { return .essentials }
        if !words.isDisjoint(with: ["flour", "rice", "pasta", "oats", "rava", "ragi", "bread", "atta", "besan", "poha", "quinoa", "millet", "noodles"]) { return .grains }
        if !words.isDisjoint(with: ["cumin", "coriander", "fenugreek", "mustard", "turmeric", "chilli", "chillies", "pepper", "masala", "cardamom", "cinnamon", "cloves", "tamarind"]) && !words.contains("leaves") && !words.contains("fresh") { return .spices }
        if !words.isDisjoint(with: ["dal", "lentils", "beans", "chickpea", "rajma", "peas"]) { return .pulses }
        if !words.isDisjoint(with: ["milk", "yogurt", "curd", "paneer", "cheese", "butter", "egg", "cream"]) { return .chilled }
        if !words.isDisjoint(with: ["tomato", "potato", "onion", "leaves", "cilantro", "coconut", "banana", "apple", "orange", "lemon", "carrot", "spinach", "garlic", "ginger", "grape", "strawberry", "watermelon", "mango", "pineapple", "avocado", "broccoli", "cucumber", "lettuce"]) { return .produce }
        return .other
    }
    static func icon(_ name: String, category: PantryCategory) -> String {
        let words = visualWords(name)
        // Preparation wins over the source ingredient: banana bread is bread,
        // coconut water is water, and banana leaves are leaves.
        if category == .essentials {
            if words.contains("water") { return "💧" }
            if words.contains("juice") { return "🧃" }
            if words.contains("coffee") { return "☕️" }
            if words.contains("tea") { return "🍵" }
            if words.contains("honey") { return "🍯" }
            return category.icon
        }
        if category == .produce && !words.isDisjoint(with: ["leaves", "spinach", "cilantro", "lettuce"]) {
            return "🥬"
        }
        let icons: [(String, String, PantryCategory)] = [
            ("bread", "🍞", .grains), ("rice", "🍚", .grains),
            ("tomato", "🍅", .produce), ("potato", "🥔", .produce),
            ("onion", "🧅", .produce), ("coconut", "🥥", .produce),
            ("banana", "🍌", .produce), ("apple", "🍎", .produce),
            ("orange", "🍊", .produce), ("grape", "🍇", .produce),
            ("strawberry", "🍓", .produce), ("watermelon", "🍉", .produce),
            ("mango", "🥭", .produce), ("pineapple", "🍍", .produce),
            ("avocado", "🥑", .produce), ("broccoli", "🥦", .produce),
            ("cucumber", "🥒", .produce), ("carrot", "🥕", .produce),
            ("garlic", "🧄", .produce), ("lemon", "🍋", .produce),
            ("egg", "🥚", .chilled), ("cheese", "🧀", .chilled),
            ("butter", "🧈", .chilled), ("milk", "🥛", .chilled)
        ]
        for (word, icon, matchingCategory) in icons where category == matchingCategory {
            if words.contains(word) { return icon }
        }
        if category == .spices && !words.contains("chilli") && !words.contains("chillies") { return "🫙" }
        return category.icon
    }
}
struct PantryCategorySuggestion: Sendable { let index: Int; let category: PantryCategory }
protocol PantryCategorizationService: Sendable {
    func categorize(_ names: [String]) async throws -> [PantryCategorySuggestion]?
}
