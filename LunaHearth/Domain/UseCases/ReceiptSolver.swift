import Foundation

/// The math reader. A receipt states its money several times over: every item price, every
/// "weight × price" or "count × price" row, every discount, the subtotal and the total. Those
/// equations hold on every receipt whatever the layout, so they decide what each row is.
///
/// 1. Each row is given the roles it could play (item, discount, note, name text, ignored),
///    each with a cost: how unusual that reading would be. Layout hints only set costs.
/// 2. A search over the rows in order (dynamic programming on the running total in cents)
///    keeps the cheapest readings, and counts how many readings tie.
/// 3. A list is proposed only when exactly one cheapest reading adds up, to the cent, to the
///    printed subtotal or total. No reading, or two equally good ones, proposes nothing.
///
/// Amounts are always printed values; nothing is computed or corrected here.
enum ReceiptSolver {
    struct Outcome: Sendable {
        enum Status: Equatable, Sendable { case unique, ambiguous, noSolution, notApplicable }
        var status: Status
        var lines: [ReceiptLine] = []
        var cost = 0
        var note = ""
    }

    enum Kind: Equatable {
        case item(amount: Int, name: String)
        case bare(amount: Int)
        case calc(amount: Int, quantity: String, verified: Bool)
        case discount(amount: Int, explicit: Bool)
        case note(amount: Int)
        case text
        case skip
    }

    private enum Action: Equatable { case none, item, discount }
    private struct Key: Hashable { var sum: Int; var lastRow: Int; var lastNet: Int; var count: Int }
    private struct Entry { var cost: Int; var ways: Int; var previous: Key?; var action: Action }
    private struct Option { var action: Action; var cost: Int }

    /// The most unusual reading still worth proposing: one ignored priced row, or a few soft guesses.
    static let acceptableCost = 8
    private static let searchCost = 14

    // MARK: Rows

    static func classify(_ raw: String) -> Kind {
        let row = raw.trimmingCharacters(in: .whitespaces)
        guard !row.isEmpty, row.count <= 250 else { return .skip }
        if let amount = ReceiptMultilineDetails.lineAmount(row) {
            return .calc(amount: amount, quantity: ReceiptMultilineDetails.countQuantity(of: row) ?? "", verified: true)
        }
        if let amount = ReceiptMultilineDetails.weightAmount(row) {
            return .calc(amount: amount, quantity: ReceiptMultilineDetails.weightQuantity(of: row) ?? "", verified: true)
        }
        if let amount = ReceiptItemDiscounts.discountAmount(row) { return .discount(amount: amount, explicit: true) }
        if let amount = bareAmount(row) { return .bare(amount: amount) }
        let price = row.range(of: ReceiptRules.pricePattern, options: .regularExpression)
        let amount = price.flatMap { amountValue(String(row[$0])) }
        if ReceiptRules.isNonProductRow(row) {
            guard let amount else { return .skip }
            if row.range(of: #"(?i)^\s*\d+(?:[.,]\d+)?\s*(?:\p{L}+\s*)?(?:@|x|×|at)\s*"#, options: .regularExpression) != nil {
                return .calc(amount: amount, quantity: "", verified: false)
            }
            return row.range(of: annotation, options: .regularExpression) != nil ? .note(amount: amount) : .skip
        }
        if let amount, ReceiptVocabulary.contains(ReceiptVocabulary.discount, in: row) { return .discount(amount: amount, explicit: false) }
        if row.range(of: ReceiptRules.excludedRow, options: .regularExpression) != nil { return .skip }
        if let price, let amount {
            let name = String(row[..<price.lowerBound]).trimmingCharacters(in: .whitespaces)
            return name.contains(where: \.isLetter) ? .item(amount: amount, name: name) : .skip
        }
        if price == nil, row.filter(\.isLetter).count >= 2,
           row.range(of: #"\d[.,]\d{2}(?!\d)"#, options: .regularExpression) == nil { return .text }
        return .skip
    }

    /// Price notes under an item whose printed amount is already net.
    private static let annotation = #"(?i)^\W*(?:temporary|regular|reg\.?|orig(?:inal)?|list|sale|was)\s+price\b|\byou\s+saved\b|\d\s*%\s*off\b"#

    private static func amountValue(_ text: String) -> Int? {
        let value = text.replacingOccurrences(of: #"\s*[A-Za-z]$"#, with: "", options: .regularExpression)
        guard !value.contains("-"), !value.contains("−"),
              let normalized = ExpenseRules.normalizedReceiptAmount(value),
              let minor = try? ExpenseRules.minorUnits(normalized), minor > 0 else { return nil }
        return minor
    }

    /// A price alone on its row ("$3.99", "3.99 F"), printed under its name.
    private static func bareAmount(_ row: String) -> Int? {
        guard row.range(of: #"^(?:[₹$€£]\s*)?\d[\d,]*[.,]\d{2}(?:\s*[A-Z])?$"#, options: .regularExpression) != nil else { return nil }
        return amountValue(row)
    }

    static func printedItemCount(_ text: String) -> Int? {
        let pattern = #"(?im)^\W*(?:items?\s+count|no\.?\s+of\s+items|number\s+of\s+items|total\s+items|#\s*items(?:\s+sold)?|items\s+sold)\s*[:#=]?\s*(\d{1,3})\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let found = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            .compactMap { Range($0.range(at: 1), in: text).flatMap { Int(text[$0]) } }
        return Set(found).count == 1 ? found.first : nil
    }

    // MARK: Search

    static func solve(text: String) -> Outcome {
        let bounded = String(text.prefix(40_000))
        let section = ItemCodeReceiptDetails.productSection(bounded).components(separatedBy: .newlines)
        let printed = ReceiptReconciliation.totals(bounded)
        guard !printed.hasConflictingAmounts else { return Outcome(status: .notApplicable, note: "Printed totals disagree with each other.") }
        var targets: [Int] = []
        for value in [printed.subtotal, printed.total].compactMap({ $0 }) where !targets.contains(value) { targets.append(value) }
        guard !targets.isEmpty else { return Outcome(status: .notApplicable, note: "No readable subtotal or total to check against.") }

        func isLabel(_ row: String, _ words: [String]) -> Bool {
            row.trimmingCharacters(in: .whitespaces).range(of: ReceiptVocabulary.label(words), options: .regularExpression) != nil
        }
        let end = section.firstIndex { isLabel($0, ReceiptVocabulary.subtotal) }
            ?? section.firstIndex { isLabel($0, ReceiptVocabulary.strongTotal + ReceiptVocabulary.total) } ?? section.count
        let rows = section[..<end].map { $0.trimmingCharacters(in: .whitespaces) }
        guard rows.count <= 400 else { return Outcome(status: .notApplicable, note: "Too many rows.") }
        let kinds = rows.map(classify)

        // Which item row each discount or note could reduce: the nearest priced row above,
        // past other notes and discounts only. A new name in between ends the item.
        let target: [Int?] = kinds.indices.map { index in
            switch kinds[index] {
            case .discount, .note: break
            default: return nil
            }
            var cursor = index - 1
            while cursor >= 0, index - cursor <= 4 {
                switch kinds[cursor] {
                case .item, .bare, .calc: return cursor
                case .note, .discount, .skip: cursor -= 1
                case .text: return nil
                }
            }
            return nil
        }
        // Name rows directly above a price that has none of its own.
        // A second, wrapped name row counts only inside the item list (money printed above it),
        // so a store name or header never becomes part of the first product.
        func isNameRow(_ index: Int) -> Bool {
            kinds[index] == .text && !rows[index].contains(":") && !rows[index].hasPrefix("*")
                && !ReceiptRules.isNonProductRow(rows[index]) && rows[index].range(of: ReceiptRules.excludedRow, options: .regularExpression) == nil
        }
        func carriesMoney(_ index: Int) -> Bool {
            switch kinds[index] { case .text, .skip: false; default: true }
        }
        func nameRows(above index: Int) -> [Int] {
            guard index >= 1, isNameRow(index - 1) else { return [] }
            if index >= 3, isNameRow(index - 2), ReceiptRules.plainNameRow(rows[index - 2]), carriesMoney(index - 3) {
                return [index - 2, index - 1]
            }
            return [index - 1]
        }
        // A count/weight row repeating the amount of the priced item above it is that item's breakdown.
        func isBreakdown(_ index: Int, amount: Int) -> Bool {
            var cursor = index - 1
            while cursor >= 0, index - cursor <= 2 {
                if case .item(let above, _) = kinds[cursor] { return above == amount }
                if kinds[cursor] != .skip { return false }
                cursor -= 1
            }
            return false
        }
        func options(_ index: Int) -> (amount: Int, [Option]) {
            switch kinds[index] {
            case .item(let amount, _):
                return (amount, [Option(action: .item, cost: 0), Option(action: .none, cost: 6)])
            case .bare(let amount):
                return nameRows(above: index).isEmpty ? (0, [Option(action: .none, cost: 0)])
                    : (amount, [Option(action: .item, cost: 1), Option(action: .none, cost: 6)])
            case .calc(let amount, _, let verified):
                if verified, isBreakdown(index, amount: amount) { return (0, [Option(action: .none, cost: 0)]) }
                let named = !nameRows(above: index).isEmpty
                if verified { return named ? (amount, [Option(action: .item, cost: 0), Option(action: .none, cost: 6)]) : (0, [Option(action: .none, cost: 6)]) }
                return named ? (amount, [Option(action: .item, cost: 3), Option(action: .none, cost: 3)]) : (0, [Option(action: .none, cost: 3)])
            case .discount(let amount, let explicit):
                guard target[index] != nil else { return (0, [Option(action: .none, cost: explicit ? 5 : 1)]) }
                return explicit ? (amount, [Option(action: .discount, cost: 0), Option(action: .none, cost: 5)])
                    : (amount, [Option(action: .discount, cost: 3), Option(action: .none, cost: 1)])
            case .note(let amount):
                return target[index] == nil ? (0, [Option(action: .none, cost: 0)])
                    : (amount, [Option(action: .none, cost: 0), Option(action: .discount, cost: 5)])
            case .text, .skip:
                return (0, [Option(action: .none, cost: 0)])
            }
        }

        let countPrinted = printedItemCount(bounded)
        let deductions = kinds.reduce(0) { total, kind in
            switch kind { case .discount(let amount, _), .note(let amount): total + amount; default: total }
        }
        let ceiling = (targets.max() ?? 0) + deductions
        var layers: [[Key: Entry]] = []
        var current: [Key: Entry] = [Key(sum: 0, lastRow: -1, lastNet: 0, count: 0): Entry(cost: 0, ways: 1, previous: nil, action: .none)]
        for index in rows.indices {
            let (amount, choices) = options(index)
            var next: [Key: Entry] = [:]
            func add(_ key: Key, cost: Int, from: Key, ways: Int, action: Action) {
                guard cost <= searchCost, key.sum >= 0, key.sum <= ceiling else { return }
                if let existing = next[key] {
                    if cost < existing.cost { next[key] = Entry(cost: cost, ways: ways, previous: from, action: action) }
                    else if cost == existing.cost { next[key]?.ways = min(2, existing.ways + ways) }
                } else { next[key] = Entry(cost: cost, ways: ways, previous: from, action: action) }
            }
            for (key, entry) in current {
                for choice in choices {
                    let cost = entry.cost + choice.cost
                    switch choice.action {
                    case .none:
                        add(key, cost: cost, from: key, ways: entry.ways, action: .none)
                    case .item:
                        add(Key(sum: key.sum + amount, lastRow: index, lastNet: amount, count: countPrinted == nil ? 0 : key.count + 1),
                            cost: cost, from: key, ways: entry.ways, action: .item)
                    case .discount:
                        guard key.lastRow == target[index], amount <= key.lastNet else { continue }
                        add(Key(sum: key.sum - amount, lastRow: key.lastRow, lastNet: key.lastNet - amount, count: key.count),
                            cost: cost, from: key, ways: entry.ways, action: .discount)
                    }
                }
            }
            guard next.count <= 200_000 else { return Outcome(status: .notApplicable, note: "Too many possible readings.") }
            layers.append(next)
            current = next
        }

        for goal in targets {
            let finals = current.filter { $0.key.sum == goal }
            guard let best = finals.values.map(\.cost).min() else { continue }
            var atBest = finals.filter { $0.value.cost == best }
            if let countPrinted, atBest.values.reduce(0, { $0 + $1.ways }) > 1 {
                let matching = atBest.filter { $0.key.count == countPrinted }
                if !matching.isEmpty { atBest = matching }
            }
            guard atBest.values.reduce(0, { $0 + $1.ways }) == 1, let final = atBest.first?.key else {
                return Outcome(status: .ambiguous, cost: best, note: "More than one reading adds up to \(ExpenseRules.amountText(goal)).")
            }
            guard best <= acceptableCost else {
                return Outcome(status: .noSolution, cost: best, note: "Adding up needs too many guesses (cost \(best)).")
            }
            var actions = Array(repeating: Action.none, count: rows.count)
            var key = final
            for index in rows.indices.reversed() {
                guard let entry = layers[index][key], let previous = entry.previous else { break }
                actions[index] = entry.action
                key = previous
            }
            let lines = buildLines(rows: rows, kinds: kinds, actions: actions, target: target, nameRows: nameRows, text: bounded)
            guard ReceiptReconciliation.check(lines: lines, text: bounded) == .verified else {
                return Outcome(status: .noSolution, cost: best, note: "Items add up but the printed totals do not agree.")
            }
            return Outcome(status: .unique, lines: lines, cost: best, note: "One reading adds up to \(ExpenseRules.amountText(goal)) (cost \(best)).")
        }
        return Outcome(status: .noSolution, note: "No reading of the rows adds up to the printed totals.")
    }

    // MARK: Lines

    private static func buildLines(rows: [String], kinds: [Kind], actions: [Action], target: [Int?],
                                   nameRows: (Int) -> [Int], text: String) -> [ReceiptLine] {
        let fingerprint = ReceiptRules.hash(text.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " "))
        let taxLetters = taxColumnLetters(rows: rows, kinds: kinds).union(ReceiptRules.taxFlags(text))
        func tidy(_ name: String) -> String {
            var value = name.replacingOccurrences(of: #"^(?:[EA]\s+)?\d{4,}\s+"#, with: "", options: .regularExpression)
            if !taxLetters.isEmpty {
                value = value.replacingOccurrences(of: #"\s+(?:"# + taxLetters.sorted().joined(separator: "|") + ")$", with: "", options: .regularExpression)
            }
            return ReceiptMultilineDetails.cleanName(value)
        }
        var lines: [ReceiptLine] = []
        var lineAt: [Int: Int] = [:]
        var net: [Int] = []
        for index in rows.indices where actions[index] == .item {
            var name = ""
            var quantity = ""
            var amount = 0
            switch kinds[index] {
            case .item(let printed, let printedName):
                amount = printed
                name = printedName
                if let prefix = name.range(of: #"^\d{1,3}\s*[xX×]\s+"#, options: .regularExpression) {
                    quantity = "\(name[prefix].prefix(while: \.isNumber)) pieces"
                    name.removeSubrange(prefix)
                }
                if let columns = ReceiptColumns.split(name: name, lineAmount: ExpenseRules.amountText(printed)) {
                    name = columns.name; quantity = columns.quantity
                }
                // A product name wrapped onto the row above, inside the item list.
                if index >= 2, kinds[index - 1] == .text, ReceiptRules.plainNameRow(rows[index - 1]), !rows[index - 1].contains(":"),
                   ![.text, .skip].contains(kinds[index - 2]) || rows[index - 2].range(of: #"^\W*\*+\s*\p{L}+\s*\*+\W*$"#, options: .regularExpression) != nil {
                    name = rows[index - 1] + " " + name
                }
            case .bare(let printed):
                amount = printed
                name = nameRows(index).map { rows[$0] }.joined(separator: " ")
            case .calc(let printed, let printedQuantity, _):
                amount = printed
                quantity = printedQuantity
                name = nameRows(index).map { rows[$0] }.joined(separator: " ")
            default: continue
            }
            let cleaned = tidy(name.trimmingCharacters(in: .whitespaces))
            lineAt[index] = lines.count
            net.append(amount)
            lines.append(ReceiptLine(id: ReceiptRules.hash("\(fingerprint)|\(index)"), name: cleaned.isEmpty ? name : cleaned,
                                     quantity: quantity, amount: ""))
        }
        for index in rows.indices where actions[index] == .discount {
            guard let row = target[index], let line = lineAt[row] else { continue }
            switch kinds[index] {
            case .discount(let amount, _), .note(let amount): net[line] -= amount
            default: break
            }
        }
        for index in lines.indices { lines[index].amount = ExpenseRules.amountText(net[index]) }
        // The same product printed twice is one review row with the amounts added.
        var merged: [ReceiptLine] = []
        for line in lines {
            if let index = merged.firstIndex(where: { IngredientMatching.same($0.name, line.name) }) {
                let a = Int(merged[index].quantity.split(separator: " ").first ?? "") ?? (merged[index].quantity.isEmpty ? 1 : nil)
                let b = Int(line.quantity.split(separator: " ").first ?? "") ?? (line.quantity.isEmpty ? 1 : nil)
                merged[index].quantity = a.flatMap { a in b.map { "\(a + $0) pieces" } } ?? ""
                let total = (try? ExpenseRules.minorUnits(merged[index].amount)) ?? 0
                merged[index].amount = ExpenseRules.amountText(total + ((try? ExpenseRules.minorUnits(line.amount)) ?? 0))
            } else { merged.append(line) }
        }
        return merged
    }

    /// A single capital letter printed before or after most prices is a tax column ("F", "T", "N").
    private static func taxColumnLetters(rows: [String], kinds: [Kind]) -> Set<String> {
        var counts: [String: Int] = [:]
        var priced = 0
        for (index, kind) in kinds.enumerated() {
            switch kind {
            case .item, .calc: break
            default: continue
            }
            priced += 1
            let row = rows[index]
            guard let price = row.range(of: ReceiptRules.pricePattern, options: .regularExpression) else { continue }
            let before = String(row[..<price.lowerBound])
            if let letter = before.range(of: #"\s([A-Z])$"#, options: .regularExpression) {
                counts[String(before[letter].trimmingCharacters(in: .whitespaces)), default: 0] += 1
            }
        }
        return Set(counts.filter { $0.value >= 2 && $0.value * 2 >= priced }.keys)
    }
}
