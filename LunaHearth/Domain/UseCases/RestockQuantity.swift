import Foundation

/// Sum only known compatible measures, or counts of the exact same packaging type.
/// An unknown existing balance is never assumed to be zero.
enum RestockQuantity {
    static func combined(existing: String?, purchased: String?) -> String? {
        if let current = PantryAmount.parse(existing), let incoming = PantryAmount.parse(purchased),
           current.unit.family == incoming.unit.family, incoming.amount > 0 {
            let result = current.amount + incoming.amount * incoming.unit.factor / current.unit.factor
            guard let number = bounded(result), number > current.amount else { return nil }
            return PantryAmount(amount: number, unit: current.unit).text
        }
        guard let current = package(existing), let incoming = package(purchased), current.unit == incoming.unit,
              incoming.amount > 0, let result = bounded(current.amount + incoming.amount) else { return nil }
        let label = result == 1 ? current.unit : current.unit == "box" ? "boxes" : current.unit + "s"
        return "\(NSDecimalNumber(decimal: result).stringValue) \(label)"
    }
    static func detail(existing: String?, purchased: String?) -> String {
        if let result = combined(existing: existing, purchased: purchased) {
            return "\(existing ?? "") + \(purchased ?? "") → \(result). Low stock clears."
        }
        return "Low stock clears. Amount stays unchanged because quantities are missing or use incompatible units. Edit the pantry amount or add a separate pack."
    }
    private static func bounded(_ value: Decimal) -> Decimal? {
        guard value >= 0, value <= (Decimal(string: "9999999.999") ?? 0) else { return nil }
        var value = value; var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 3, .plain)
        return rounded
    }
    private static func package(_ text: String?) -> (amount: Decimal, unit: String)? {
        guard let text else { return nil }
        let parts = text.lowercased().split(whereSeparator: \.isWhitespace)
        guard parts.count == 2, let amount = PantryAmount.number(String(parts[0])) else { return nil }
        let unit = String(parts[1])
        for known in ["pack", "bottle", "carton", "tub", "bag", "can", "jar", "box"] {
            let plural = known == "box" ? "boxes" : known + "s"
            if unit == known || unit == plural { return (amount, known) }
        }
        return nil
    }
}
