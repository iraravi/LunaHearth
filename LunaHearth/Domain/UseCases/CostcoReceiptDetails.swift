import Foundation

/// Costco prints one SKU row per purchased unit and SKU-linked instant savings.
/// Enrich only exact, priced SKU rows; never infer package contents from an item code.
enum CostcoReceiptDetails {
    static func apply(text: String, lines: inout [ReceiptLine]) {
        guard text.localizedCaseInsensitiveContains("costco") else { return }
        struct Item {
            var name: String
            var count: Int
            var total: Int
            var valid = true
        }
        var items: [String: Item] = [:]
        var discounts: [String: Int] = [:]
        func captures(_ pattern: String, _ line: String) -> [String]? {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else { return nil }
            return (1..<match.numberOfRanges).compactMap { Range(match.range(at: $0), in: line).map { String(line[$0]) } }
        }
        for raw in text.prefix(40_000).components(separatedBy: .newlines) {
            let row = raw.trimmingCharacters(in: .whitespaces)
            if let part = captures(#"^(?:[EA]\s+)?\d{4,}\s+/\s*(\d{4,})\s+(\d{1,6}\.\d{2})[-−]\s*$"#, row),
               let amount = try? ExpenseRules.minorUnits(part[1]) {
                discounts[part[0], default: 0] += amount
            } else if let part = captures(#"^(?:[EA]\s+)?(\d{4,})\s+([A-Za-z][A-Za-z0-9 &.'/-]*?)\s+(\d{1,6}\.\d{2})\s*[A-Za-z]?$"#, row),
                      let amount = try? ExpenseRules.minorUnits(part[2]) {
                let key = part[0], name = part[1]
                if var item = items[key] {
                    item.valid = item.valid && item.name == name
                    item.count += 1; item.total += amount; items[key] = item
                } else { items[key] = Item(name: name, count: 1, total: amount) }
            }
        }
        for index in lines.indices {
            let matches = items.filter { $0.value.name == lines[index].name }
            guard matches.count == 1, let (sku, item) = matches.first, item.valid else { continue }
            let net = item.total - discounts[sku, default: 0]
            guard net > 0 else { continue }
            lines[index].quantity = item.count == 1 ? "1 piece" : "\(item.count) pieces"
            lines[index].amount = ExpenseRules.amountText(net)
        }
        // If a coupon was unreadable, the gross item amounts can exceed the actual bill.
        // Leave amounts for review instead of recording an inconsistent allocation.
        if let totalText = ExpenseRules.receiptTotal(text), let total = try? ExpenseRules.minorUnits(totalText) {
            let proposed = lines.reduce(0) { $0 + ((try? ExpenseRules.minorUnits($1.amount)) ?? 0) }
            if proposed > total { for index in lines.indices { lines[index].amount = "" } }
        }
    }
}
