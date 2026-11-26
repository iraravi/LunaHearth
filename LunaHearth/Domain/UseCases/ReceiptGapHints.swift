import Foundation

/// When scanned items don't add up to the printed subtotal, points at the receipt rows that
/// would close the gap: a priced row that was not counted, or a discount that was not applied.
/// A hint is offered only when exactly one choice of one or two rows makes the items add up to
/// the cent. Hints are proposals; nothing changes until the person taps one.
struct ReceiptGapHint: Equatable, Sendable, Identifiable {
    enum Kind: Equatable, Sendable {
        /// A priced row no item covers ("1996645 METHOD BODY 4.97 A").
        case missedItem(name: String, amount: Int)
        /// A discount row not taken off its item; `lineID` is the item it belongs to.
        case missedDiscount(amount: Int, lineID: String?)
    }
    var id: String { row }
    var row: String
    var kind: Kind
}

enum ReceiptGapHints {
    static func hints(lines: [ReceiptLine], text: String) -> [ReceiptGapHint] {
        guard !lines.isEmpty, !lines.contains(where: \.amountNeedsReview) else { return [] }
        let amounts = lines.compactMap { try? ExpenseRules.minorUnits($0.amount) }
        guard amounts.count == lines.count else { return [] }
        let printed = ReceiptReconciliation.totals(text)
        guard !printed.hasConflictingAmounts, let target = printed.subtotal ?? printed.total else { return [] }
        let needed = target - amounts.reduce(0, +)
        guard needed != 0 else { return [] }

        let rows = itemRows(text)
        var candidates: [(hint: ReceiptGapHint, effect: Int)] = []
        for (index, row) in rows.enumerated() {
            switch ReceiptSolver.classify(row) {
            case .item(let amount, let name):
                let clean = name.replacingOccurrences(of: #"^(?:[EA]\s+)?\d{4,}\s+"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"\s+[A-Z]$"#, with: "", options: .regularExpression)
                candidates.append((ReceiptGapHint(row: row, kind: .missedItem(name: clean, amount: amount)), amount))
            case .discount(let amount, _):
                candidates.append((ReceiptGapHint(row: row, kind: .missedDiscount(amount: amount, lineID: owner(of: index, rows: rows, lines: lines))), -amount))
            default: continue
            }
        }
        // One row, then two rows; identical rows (the same item printed twice) count once.
        var answers: [[ReceiptGapHint]] = []
        func add(_ choice: [ReceiptGapHint]) {
            let key = choice.map(\.row).sorted()
            if !answers.contains(where: { $0.map(\.row).sorted() == key }) { answers.append(choice) }
        }
        for candidate in candidates where candidate.effect == needed { add([candidate.hint]) }
        if answers.isEmpty, candidates.count <= 120 {
            for i in candidates.indices {
                for j in candidates.indices where j > i && candidates[i].effect + candidates[j].effect == needed {
                    add([candidates[i].hint, candidates[j].hint])
                }
            }
        }
        // A discount must have an item to come off.
        answers = answers.filter { $0.allSatisfy { if case .missedDiscount(_, nil) = $0.kind { false } else { true } } }
        return answers.count == 1 ? answers[0] : []
    }

    /// Item rows: the product part of the receipt, before the subtotal.
    private static func itemRows(_ text: String) -> [String] {
        let section = ItemCodeReceiptDetails.productSection(ReceiptOCRCleanup.clean(String(text.prefix(40_000))))
            .components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        let label = ReceiptVocabulary.label(ReceiptVocabulary.subtotal + ReceiptVocabulary.strongTotal + ReceiptVocabulary.total)
        let end = section.firstIndex { $0.range(of: label, options: .regularExpression) != nil } ?? section.count
        return Array(section[..<end])
    }

    /// The scanned item a discount row belongs to: the item whose code it names, else the
    /// nearest priced row above it.
    private static func owner(of index: Int, rows: [String], lines: [ReceiptLine]) -> String? {
        func line(for row: String) -> String? {
            guard case .item(_, let name) = ReceiptSolver.classify(row) else { return nil }
            let words = normalized(name)
            let matches = lines.filter { !normalized($0.name).isEmpty && words.contains(normalized($0.name)) }
            return matches.count == 1 ? matches[0].id : nil
        }
        if let code = rows[index].range(of: #"(?<=/)\s*\d{4,}"#, options: .regularExpression) {
            let sku = rows[index][code].trimmingCharacters(in: .whitespaces)
            if let row = rows[..<index].last(where: { $0.range(of: #"^(?:[EA]\s+)?"# + sku + #"\s"#, options: .regularExpression) != nil }) {
                return line(for: row)
            }
        }
        var cursor = index - 1
        while cursor >= 0, index - cursor <= 3 {
            if let id = line(for: rows[cursor]) { return id }
            cursor -= 1
        }
        return nil
    }

    private static func normalized(_ text: String) -> String {
        text.lowercased().filter { $0.isLetter || $0.isNumber || $0 == " " }.split(separator: " ").joined(separator: " ")
    }

    /// Applies one hint to the scanned lines.
    static func apply(_ hint: ReceiptGapHint, to lines: inout [ReceiptLine], idSeed: String) {
        switch hint.kind {
        case .missedItem(let name, let amount):
            if let index = lines.firstIndex(where: { IngredientMatching.same($0.name, name) }),
               let current = try? ExpenseRules.minorUnits(lines[index].amount) {
                lines[index].amount = ExpenseRules.amountText(current + amount)
                if let count = Int(lines[index].quantity.split(separator: " ").first ?? "") { lines[index].quantity = "\(count + 1) pieces" }
                else if lines[index].quantity.isEmpty || lines[index].quantity == "1 piece" { lines[index].quantity = "2 pieces" }
            } else {
                lines.append(ReceiptLine(id: ReceiptRules.hash(idSeed + "|hint|" + hint.row), name: name, quantity: "1 piece",
                                         amount: ExpenseRules.amountText(amount)))
            }
        case .missedDiscount(let amount, let lineID):
            guard let index = lines.firstIndex(where: { $0.id == lineID }),
                  let current = try? ExpenseRules.minorUnits(lines[index].amount), amount <= current else { return }
            lines[index].amount = ExpenseRules.amountText(current - amount)
        }
    }
}
