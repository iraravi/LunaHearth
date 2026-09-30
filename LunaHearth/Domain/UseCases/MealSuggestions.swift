import Foundation

enum MealCookingStyle: String, CaseIterable, Identifiable, Sendable {
    case any = "Any style"
    case indian = "Indian"
    case southIndian = "South Indian"
    case northIndian = "North Indian"
    case american = "American"
    case mediterranean = "Mediterranean"
    case italian = "Italian"
    case mexican = "Mexican"
    case chinese = "Chinese"
    case japanese = "Japanese"
    case thai = "Thai"
    case korean = "Korean"
    case vietnamese = "Vietnamese"
    case middleEastern = "Middle Eastern"
    case greek = "Greek"
    case french = "French"
    case caribbean = "Caribbean"
    case british = "British"
    var id: String { rawValue }
}

struct MealSuggestionResult: Sendable {
    let ideas: [PantryMealIdea]
    let message: String
}
protocol MealSuggestionService: Sendable {
    func suggest(names: [String], style: MealCookingStyle, context: String) async throws -> MealSuggestionResult
}
protocol MealPlanningReminderService: Sendable {
    func enabled() async -> Bool
    func setEnabled(_ enabled: Bool) async throws
}
enum MealSuggestionRules {
    static func available(isUsedUp: Bool, expiryDay: String?, plannedDay: String) -> Bool {
        !isUsedUp && (expiryDay.map { $0 >= plannedDay } ?? true)
    }
    static let contextLimit = 400
    static func boundedContext(_ text: String) -> String { String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(contextLimit)) }
    static let reminderTime = DateComponents(hour: 17, minute: 0)
    static let starters: [PantryMealIdea] = [
        .init(id: "curd-rice", name: "Curd rice", ingredients: ["Rice", "Curd"], minutes: 20),
        .init(id: "egg-rice", name: "Carrot & egg rice", ingredients: ["Rice", "Carrots", "Eggs"], minutes: 25),
        .init(id: "oats", name: "Banana oats", ingredients: ["Bananas", "Oats", "Milk"], minutes: 10),
        .init(id: "dal", name: "Dal and rice", ingredients: ["Rice", "Toor dal", "Tomato", "Cumin"], minutes: 35),
        .init(id: "poha", name: "Vegetable poha", ingredients: ["Poha", "Onion", "Carrots"], minutes: 20),
        .init(id: "pasta", name: "Tomato pasta", ingredients: ["Pasta", "Tomato", "Garlic"], minutes: 25),
        .init(id: "omelette", name: "Vegetable omelette", ingredients: ["Eggs", "Onion", "Tomato"], minutes: 15),
        .init(id: "upma", name: "Vegetable upma", ingredients: ["Rava", "Onion", "Carrots"], minutes: 25),
        .init(id: "chana", name: "Chana with rice", ingredients: ["Chickpeas", "Rice", "Tomato", "Cumin"], minutes: 35),
        .init(id: "mexican-rice", name: "Bean & corn rice bowl", ingredients: ["Rice", "Black beans", "Corn", "Tomato"], minutes: 25),
        .init(id: "chinese-rice", name: "Egg & vegetable fried rice", ingredients: ["Rice", "Eggs", "Carrots", "Soy sauce"], minutes: 20),
        .init(id: "japanese-rice", name: "Mushroom & egg rice bowl", ingredients: ["Rice", "Mushrooms", "Eggs", "Soy sauce"], minutes: 25),
        .init(id: "thai-rice", name: "Basil vegetable rice", ingredients: ["Rice", "Basil", "Bell pepper", "Garlic"], minutes: 25),
        .init(id: "korean-rice", name: "Korean-style vegetable rice bowl", ingredients: ["Rice", "Carrots", "Spinach", "Gochujang"], minutes: 30),
        .init(id: "vietnamese-noodles", name: "Herb & rice noodle bowl", ingredients: ["Rice noodles", "Cucumber", "Carrots", "Mint", "Lime"], minutes: 20),
        .init(id: "middle-eastern-rice", name: "Spiced chickpea rice", ingredients: ["Chickpeas", "Rice", "Cumin", "Onion"], minutes: 30),
        .init(id: "greek-salad", name: "Greek-style chickpea salad", ingredients: ["Chickpeas", "Cucumber", "Tomato", "Feta"], minutes: 15),
        .init(id: "french-omelette", name: "Mushroom omelette", ingredients: ["Eggs", "Mushrooms", "Butter"], minutes: 15),
        .init(id: "caribbean-rice", name: "Coconut rice & kidney beans", ingredients: ["Rice", "Kidney beans", "Coconut milk", "Thyme"], minutes: 35),
        .init(id: "british-potato", name: "Jacket potato with baked beans", ingredients: ["Potato", "Baked beans", "Cheddar"], minutes: 60),
        .init(id: "chickpeas", name: "Chickpea salad", ingredients: ["Chickpeas", "Cucumber", "Tomato"], minutes: 15)
    ]
    static func starters(for style: MealCookingStyle) -> [PantryMealIdea] {
        let ids: Set<String>
        switch style {
        case .any: return starters
        case .indian: ids = ["curd-rice", "egg-rice", "dal", "poha", "upma", "chana"]
        case .southIndian: ids = ["curd-rice", "egg-rice", "upma"]
        case .northIndian: ids = ["dal", "poha", "chana"]
        case .american: ids = ["oats", "omelette", "pasta"]
        case .mediterranean: ids = ["pasta", "chickpeas", "greek-salad"]
        case .italian: ids = ["pasta"]
        case .mexican: ids = ["mexican-rice"]
        case .chinese: ids = ["chinese-rice"]
        case .japanese: ids = ["japanese-rice"]
        case .thai: ids = ["thai-rice"]
        case .korean: ids = ["korean-rice"]
        case .vietnamese: ids = ["vietnamese-noodles"]
        case .middleEastern: ids = ["middle-eastern-rice"]
        case .greek: ids = ["greek-salad"]
        case .french: ids = ["french-omelette"]
        case .caribbean: ids = ["caribbean-rice"]
        case .british: ids = ["british-potato"]
        }
        return starters.filter { ids.contains($0.id) }
    }
    static func ranked(_ ideas: [PantryMealIdea], names: [String]) -> [PantryMealIdea] {
        ideas.filter { !$0.ingredients.isEmpty && $0.missing(from: names).count < $0.ingredients.count }
            .sorted {
                let lhs = Double($0.ingredients.count - $0.missing(from: names).count) / Double($0.ingredients.count)
                let rhs = Double($1.ingredients.count - $1.missing(from: names).count) / Double($1.ingredients.count)
                return lhs == rhs ? $0.id < $1.id : lhs > rhs
            }
    }
    // Generative output is never accepted as cooking instructions.
    static func generatedIdea(id: String, name: String, ingredients: [String], minutes: Int) -> PantryMealIdea? {
        guard valid(name: name, ingredients: ingredients, minutes: minutes) else { return nil }
        var seen: Set<String> = []
        let cleaned = ingredients.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { seen.insert(IngredientMatching.key($0)).inserted }
        return PantryMealIdea(id: id, name: name.trimmingCharacters(in: .whitespacesAndNewlines), ingredients: cleaned, minutes: minutes)
    }
    static func valid(name: String, ingredients: [String], minutes: Int) -> Bool {
        AIInputRules.label(name, maximum: 100) && (1...180).contains(minutes)
        && (1...15).contains(ingredients.count) && ingredients.allSatisfy { AIInputRules.label($0, maximum: 80) }
    }
}
