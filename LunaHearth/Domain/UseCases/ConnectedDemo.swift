import Foundation

struct PantryMealIdea: Identifiable, Sendable {
    let id: String
    let name: String
    let ingredients: [String]
    let minutes: Int
    var steps: [String] = []
    func missing(from names: [String]) -> [String] {
        ingredients.filter { ingredient in !names.contains { IngredientMatching.same($0, ingredient) } }
    }
}

enum ConnectedDemo {
    static let receipt = """
    LUNA DEMO MARKET
    SAMPLE RECEIPT - NOT A REAL PURCHASE

    Rice                         5.00
    Curd                         3.00
    Carrots                      2.00
    Eggs                         4.00
    2 x Bananas                  2.00

    TOTAL                       16.00
    USD
    Thank you
    """
    static let ideas = [
        PantryMealIdea(id: "curd-rice", name: "Curd rice", ingredients: ["Rice", "Curd"], minutes: 20),
        PantryMealIdea(id: "egg-rice", name: "Carrot & egg rice", ingredients: ["Rice", "Carrots", "Eggs"], minutes: 25),
        PantryMealIdea(id: "banana-oats", name: "Banana oats", ingredients: ["Bananas", "Oats", "Milk"], minutes: 10)
    ]
}
