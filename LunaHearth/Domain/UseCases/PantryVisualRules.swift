import Foundation

enum PantryCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case grains, pulses, spices, produce, chilled, meat, essentials, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .grains: "Rice & grains"
        case .pulses: "Dals & beans"
        case .spices: "Spices"
        case .produce: "Fruit & vegetables"
        case .chilled: "Dairy & eggs"
        case .meat: "Meat & seafood"
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
        case .meat: "🥩"
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
            "potatoes": "potato", "onions": "onion", "eggs": "egg", "leaf": "leaves",
            "mushrooms": "mushroom", "pears": "pear", "peaches": "peach", "cherries": "cherry", "kiwis": "kiwi",
            "limes": "lime", "blueberries": "blueberry", "prawns": "prawn", "shrimps": "shrimp"
        ]
        return Set(IngredientMatching.key(name).split(separator: " ").map {
            singulars[String($0)] ?? String($0)
        })
    }
    static func category(_ name: String) -> PantryCategory {
        let words = visualWords(name)
        // More specific preparations take precedence over their source ingredient.
        if !words.isDisjoint(with: ["oil", "ghee", "sugar", "jaggery", "salt", "tea", "coffee", "honey", "sauce", "vinegar", "water", "juice", "stock", "broth", "bouillon", "ketchup", "jam", "mayonnaise", "mayo", "soda", "syrup", "pickle", "chutney", "spread", "dressing"]) { return .essentials }
        if !words.isDisjoint(with: ["flour", "rice", "pasta", "oats", "rava", "ragi", "bread", "atta", "besan", "poha", "quinoa", "millet", "noodles", "cereal", "granola", "tortilla", "tortillas", "bagel", "bun", "buns", "roti", "chapati", "naan", "spaghetti", "macaroni", "couscous", "semolina"]) { return .grains }
        if !words.isDisjoint(with: ["cumin", "coriander", "fenugreek", "mustard", "turmeric", "chilli", "chillies", "pepper", "masala", "cardamom", "cinnamon", "cloves", "tamarind", "seasoning", "rub"]) && !words.contains("leaves") && !words.contains("fresh") { return .spices }
        if !words.isDisjoint(with: ["dal", "lentils", "beans", "chickpea", "rajma", "peas"]) { return .pulses }
        if !words.isDisjoint(with: ["mutton", "lamb", "goat", "chicken", "beef", "pork", "turkey", "duck", "fish", "salmon", "tuna", "prawn", "prawns", "shrimp", "crab"]) && words.isDisjoint(with: ["milk", "egg", "vegan", "vegetarian", "plant", "style", "flavour", "flavor"]) { return .meat }
        if !words.isDisjoint(with: ["milk", "yogurt", "yoghurt", "curd", "paneer", "cheese", "butter", "egg", "cream", "kefir", "buttermilk", "mozzarella", "cheddar", "parmesan", "feta"]) { return .chilled }
        if !words.isDisjoint(with: ["tomato", "potato", "onion", "leaves", "cilantro", "coconut", "banana", "apple", "orange", "lemon", "carrot", "spinach", "garlic", "ginger", "grape", "strawberry", "watermelon", "mango", "pineapple", "avocado", "broccoli", "cucumber", "lettuce", "cabbage", "cauliflower", "okra", "bhindi", "brinjal", "eggplant", "capsicum", "mushroom", "mushrooms", "corn", "pumpkin", "zucchini", "beetroot", "radish", "peach", "pear", "plum", "kiwi", "cherry", "cherries", "blueberry", "blueberries", "berries", "lime", "papaya", "guava", "pomegranate", "fruit", "vegetable", "vegetables", "salad", "herbs", "mint"]) { return .produce }
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
            ("garlic", "🧄", .produce), ("lemon", "🍋", .produce), ("lime", "🍋", .produce),
            ("mushroom", "🍄", .produce), ("corn", "🌽", .produce), ("capsicum", "🫑", .produce),
            ("pear", "🍐", .produce), ("peach", "🍑", .produce), ("cherry", "🍒", .produce),
            ("kiwi", "🥝", .produce), ("blueberry", "🫐", .produce), ("blueberries", "🫐", .produce),
            ("eggplant", "🍆", .produce), ("brinjal", "🍆", .produce),
            ("chicken", "🍗", .meat), ("fish", "🐟", .meat), ("salmon", "🐟", .meat), ("tuna", "🐟", .meat),
            ("prawn", "🦐", .meat), ("prawns", "🦐", .meat), ("shrimp", "🦐", .meat), ("crab", "🦀", .meat),
            ("noodles", "🍜", .grains), ("pasta", "🍝", .grains), ("spaghetti", "🍝", .grains), ("bagel", "🥯", .grains),
            ("ketchup", "🍅", .essentials),
            ("egg", "🥚", .chilled), ("cheese", "🧀", .chilled),
            ("paneer", "🧀", .chilled), ("yogurt", "🥣", .chilled), ("curd", "🥣", .chilled),
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

/// On-device AI categories remembered on this phone, keyed by ingredient identity.
/// Visual only: never changes duplicate checks, pantry identity or synced household records.
enum PantryCategoryMemory {
    static let storageKey = "pantry.categories.v1"
    static let maximumEntries = 600

    static func decode(_ stored: String) -> [String: PantryCategory] {
        guard let raw = try? JSONDecoder().decode([String: String].self, from: Data(stored.utf8)) else { return [:] }
        return raw.compactMapValues(PantryCategory.init(rawValue:))
    }

    /// Names the word list cannot place and the phone has not asked about yet.
    static func unknown(_ names: [String], memory: [String: PantryCategory], limit: Int = 40) -> [String] {
        var seen = Set<String>()
        return names.compactMap { name -> String? in
            let key = IngredientMatching.key(name)
            guard !key.isEmpty, PantryVisualRules.category(name) == .other, memory[key] == nil, seen.insert(key).inserted else { return nil }
            return name.trimmingCharacters(in: .whitespacesAndNewlines)
        }.sorted().prefix(limit).map { $0 }
    }

    /// Stores every asked name, so "other" answers are not asked again on every change.
    static func remember(_ names: [String], suggestions: [PantryCategorySuggestion], stored: String) -> String {
        var all = (try? JSONDecoder().decode([String: String].self, from: Data(stored.utf8))) ?? [:]
        for (index, name) in names.enumerated() {
            let key = IngredientMatching.key(name)
            guard !key.isEmpty else { continue }
            all[key] = (suggestions.first { $0.index == index }?.category ?? .other).rawValue
        }
        if all.count > maximumEntries { all = Dictionary(uniqueKeysWithValues: all.sorted { $0.key < $1.key }.suffix(maximumEntries).map { ($0.key, $0.value) }) }
        guard let data = try? JSONEncoder().encode(all) else { return stored }
        return String(decoding: data, as: UTF8.self)
    }
}

extension PantryVisualRules {
    /// Word list first; remembered on-device AI category when the word list has no answer.
    static func category(_ name: String, memory: [String: PantryCategory]) -> PantryCategory {
        let known = category(name)
        return known == .other ? memory[IngredientMatching.key(name)] ?? .other : known
    }
    static func icon(_ name: String, memory: [String: PantryCategory]) -> String {
        icon(name, category: category(name, memory: memory))
    }
}
protocol PantryCategorizationService: Sendable {
    func categorize(_ names: [String]) async throws -> [PantryCategorySuggestion]?
}
