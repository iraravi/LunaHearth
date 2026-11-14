import Foundation

/// Quantity and rate columns printed between a product name and its line amount, as on
/// "Item  Qty  Rate  Amount" bills (common in India) and weighed-goods rows anywhere:
/// `TOMATO 1.000 40.00 40.00`, `OKRA 1.25 lb 1.99 2.49`, `MILK 2 x 1.50 3.00`.
/// Columns are accepted only when quantity × rate reproduces the line amount, so a unit
/// price can never be mistaken for the amount charged.
enum ReceiptColumns {
    struct Split: Equatable { let name: String; let quantity: String }

    static let units = "kg|kgs|g|gm|gms|grams?|lb|lbs|oz|l|ltr|litres?|liters?|ml|pcs?|pc|nos?|no|ea|each|units?|stk|st"

    static func split(name: String, lineAmount: String) -> Split? {
        guard let amount = try? ExpenseRules.minorUnits(lineAmount) else { return nil }
        let pattern = #"(?i)^(.*?\p{L}.*?)\s+(\d{1,4}(?:[.,]\d{1,3})?)\s*("# + units + #")?\s*(?:[x×@]\s*)?"#
            + #"(?:"# + ExpenseRules.currencyPattern + #")?\s*(\d{1,6}[.,]\d{2})(?:\s*/\s*\p{L}{1,5})?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)) else { return nil }
        func group(_ index: Int) -> String? {
            Range(match.range(at: index), in: name).map { String(name[$0]) }
        }
        guard let product = group(1)?.trimmingCharacters(in: .whitespaces), product.count >= 2,
              let quantityText = group(2), let rateText = group(4),
              let quantity = Decimal(string: quantityText.replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US_POSIX")),
              quantity > 0, let rate = try? ExpenseRules.minorUnits(rateText) else { return nil }
        // Weighed goods round to the nearest minor unit; allow that rounding only.
        let expected = quantity * Decimal(rate)
        let difference = expected - Decimal(amount)
        guard difference > -1, difference < 1 else { return nil }
        let unit = group(3)?.lowercased()
        let isWhole = !quantityText.contains(where: { $0 == "." || $0 == "," })
        let quantityLabel: String
        switch unit {
        case nil, "pc", "pcs", "no", "nos", "ea", "each", "unit", "units", "stk", "st":
            // A bare decimal quantity such as 1.000 on a rate bill is a weight with an unknown unit.
            guard isWhole else { return Split(name: product, quantity: "") }
            let count = NSDecimalNumber(decimal: quantity).intValue
            quantityLabel = count == 1 ? "1 piece" : "\(count) pieces"
        case let unit?:
            quantityLabel = "\(normalized(quantityText)) \(unit)"
        }
        return Split(name: product, quantity: quantityLabel)
    }

    private static func normalized(_ quantity: String) -> String {
        var value = quantity.replacingOccurrences(of: ",", with: ".")
        if value.contains(".") {
            while value.hasSuffix("0") { value.removeLast() }
            if value.hasSuffix(".") { value.removeLast() }
        }
        return value
    }
}
