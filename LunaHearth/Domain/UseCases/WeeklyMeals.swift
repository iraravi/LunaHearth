import Foundation

struct WeeklyMealDemand: Sendable {
    let name: String
    let day: String
    let perServing: String?
    let servings: Int
}
struct WeeklyPantryPack: Sendable {
    let name: String
    let quantity: String?
    let expiry: String?
}
struct WeeklyShoppingNeed: Identifiable, Equatable, Sendable {
    var id: String { name }
    let name: String
    var amount: String?
    var needsAmountReview: Bool
    var covered: Bool
    var alreadyListed: Bool
    var detail: String {
        if alreadyListed { return "Already in shopping · check its amount" }
        if needsAmountReview { return "Check amounts · recipe or pantry amount unknown" }
        if covered { return "Covered by measured pantry stock" }
        return amount.map { "Buy \($0)" } ?? "Choose an amount before buying"
    }
}
enum WeeklyMealRules {
    static func days(from date: Date, calendar: Calendar = .current) -> [Date] {
        let start = calendar.startOfDay(for: date)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
    static func validateAmounts(_ amounts: [String: String], names: [String]) throws {
        guard amounts.count <= 40, amounts.allSatisfy({ key, value in
            names.contains(key) && PantryAmount.parse(value).map { $0.amount > 0 } == true
        }) else { throw MealCookingError.amount }
    }
    static func shopping(demands: [WeeklyMealDemand], pantry: [WeeklyPantryPack], pending: [String]) -> [WeeklyShoppingNeed] {
        let orderedPacks = pantry.sorted { ($0.expiry ?? "9999") < ($1.expiry ?? "9999") }
        var available = orderedPacks.map { PantryAmount.parse($0.quantity).map { $0.amount * $0.unit.factor } }
        var rows: [WeeklyShoppingNeed] = []
        var units: [String: PantryUnit] = [:]
        var totals: [String: Decimal] = [:]
        for demand in demands.sorted(by: { $0.day < $1.day }) {
            let index: Int
            if let found = rows.firstIndex(where: { IngredientMatching.same($0.name, demand.name) }) { index = found }
            else { rows.append(.init(name: demand.name, needsAmountReview: false, covered: true, alreadyListed: pending.contains { IngredientMatching.same($0, demand.name) })); index = rows.count - 1 }
            let key = rows[index].name
            guard let portion = PantryAmount.parse(demand.perServing), portion.amount > 0, (1...20).contains(demand.servings) else {
                rows[index].needsAmountReview = true; rows[index].covered = false; continue
            }
            if let unit = units[key], unit.family != portion.unit.family { rows[index].needsAmountReview = true }
            units[key] = units[key] ?? portion.unit
            var needed = portion.amount * portion.unit.factor * Decimal(demand.servings)
            var unknownStock = false
            for packIndex in orderedPacks.indices where IngredientMatching.same(orderedPacks[packIndex].name, demand.name) && (orderedPacks[packIndex].expiry.map { $0 >= demand.day } ?? true) {
                guard let quantity = PantryAmount.parse(orderedPacks[packIndex].quantity), quantity.unit.family == portion.unit.family, let remaining = available[packIndex] else { unknownStock = true; continue }
                let used = min(remaining, needed); needed -= used; available[packIndex] = remaining - used
            }
            if needed > 0 {
                rows[index].covered = false
                if unknownStock { rows[index].needsAmountReview = true }
                totals[key, default: 0] += needed
            }
        }
        for index in rows.indices {
            let key = rows[index].name
            if !rows[index].needsAmountReview, let total = totals[key], let unit = units[key] {
                var value = total / unit.factor; var rounded = Decimal()
                NSDecimalRound(&rounded, &value, 3, .up)
                rows[index].amount = PantryAmount(amount: rounded, unit: unit).text
            }
        }
        return rows.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
