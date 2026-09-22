import Foundation

enum PantryUnit: String, CaseIterable, Identifiable, Sendable {
    case g, kg, oz, lb, ml, l, piece
    var id: String { rawValue }
    var label: String { self == .piece ? "pieces" : rawValue }
    var family: String { switch self { case .g, .kg, .oz, .lb: "mass"; case .ml, .l: "volume"; case .piece: "count" } }
    var factor: Decimal { switch self { case .kg, .l: 1000; case .oz: Decimal(string: "28.349523125") ?? 1; case .lb: Decimal(string: "453.59237") ?? 1; default: 1 } }
}
struct PantryAmount: Equatable, Sendable {
    let amount: Decimal
    let unit: PantryUnit
    var text: String { "\(NSDecimalNumber(decimal: amount).stringValue) \(unit.label)" }
    static func parse(_ text: String?) -> PantryAmount? {
        guard let text else { return nil }
        let parts = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
        guard parts.count == 2, let amount = number(String(parts[0])) else { return nil }
        if parts[1] == "dozen" || parts[1] == "dozens" { return .init(amount: amount * 12, unit: .piece) }
        let aliases = ["grams": "g", "gram": "g", "kilograms": "kg", "liter": "l", "litre": "l", "liters": "l", "litres": "l", "kilogram": "kg", "pound": "lb", "ounces": "oz", "ounce": "oz", "millilitre": "ml", "millilitres": "ml", "pieces": "piece", "pcs": "piece", "pounds": "lb"]
        guard let unit = PantryUnit(rawValue: aliases[String(parts[1])] ?? String(parts[1])) else { return nil }
        return .init(amount: amount, unit: unit)
    }
    static func number(_ value: String) -> Decimal? {
        guard value.range(of: "^[0-9]{1,7}(\\.[0-9]{1,3})?$", options: .regularExpression) != nil,
              let number = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")), number >= 0 else { return nil }
        return number
    }
    func subtract(_ used: PantryAmount) throws -> PantryAmount {
        guard unit.family == used.unit.family, used.amount > 0 else { throw MealCookingError.amount }
        let remaining = amount - used.amount * used.unit.factor / unit.factor
        guard remaining >= 0 else { throw MealCookingError.insufficient }
        // Canonical quantities retain three decimal places; never convert between mass and volume.
        var value = remaining; var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 3, .plain)
        return .init(amount: rounded, unit: unit)
    }
}
enum MealCookingError: LocalizedError {
    case amount, insufficient, changed, cooked, invalidRecipe
    var errorDescription: String? { switch self {
    case .amount: "Enter a measured amount and a compatible unit. Set the pack amount first if it is unknown."
    case .insufficient: "The amount used is greater than the amount saved in this pack. Review the pack amount first."
    case .changed: "This meal or pack changed. Close this review and open it again to use the latest values."
    case .cooked: "This meal is already marked cooked. Its pantry updates will not be repeated."
    case .invalidRecipe: "Use 1–20 servings, up to 40 ingredient names and 30 preparation steps. Keep each ingredient under 100 and each step under 500 characters."
    } }
}
enum PantryUseAction: String, CaseIterable, Identifiable { case keep = "Keep unchanged", amount = "Use an amount", low = "Mark low stock", finished = "Used up"; var id: String { rawValue } }
struct PantryUseReview: Identifiable {
    let id: UUID
    let modifiedAt: Date
    var action: PantryUseAction = .keep
    var amount = ""
    var unit: PantryUnit = .g
}
enum MealCookingRules {
    static func lines(_ text: String) -> [String] { text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty } }
    static func validate(servings: Int, ingredients: [String], steps: [String]) throws {
        guard (1...20).contains(servings), ingredients.count <= 40, steps.count <= 30,
              ingredients.allSatisfy({ !$0.isEmpty && $0.count <= 100 }), steps.allSatisfy({ !$0.isEmpty && $0.count <= 500 }) else { throw MealCookingError.invalidRecipe }
    }
}
struct MealPrepReminderInput: Sendable { let id: UUID; let due: Date?; let completed: Bool }
protocol MealPrepReminderService: Sendable {
    func schedule(id: UUID, householdID: UUID, due: Date) async throws
    func reconcile(householdID: UUID, tasks: [MealPrepReminderInput]) async
}

struct MealIngredientAvailability: Equatable {
    let inPantry: Bool
    let inShopping: Bool
    var label: String {
        if inPantry && inShopping { return "In pantry · Already in shopping" }
        if inPantry { return "In pantry" }
        return inShopping ? "Already in shopping" : "Need to buy"
    }
    var symbol: String { inShopping ? "checklist" : inPantry ? "checkmark.circle" : "basket" }
    static func resolve(_ name: String, pantry: [String], shopping: [String]) -> Self {
        .init(inPantry: pantry.contains { IngredientMatching.same($0, name) }, inShopping: shopping.contains { IngredientMatching.same($0, name) })
    }
}
