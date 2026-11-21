import Foundation

/// Source evidence is distinct from an optional suggestion: contradictory values must not
/// become equivalent to a missing/unreadable total in downstream reconciliation.
enum ReceiptTotalEvidence: Equatable, Sendable {
    case absent
    case unreadable
    case conflicting
    case value(String)

    var amount: String? {
        if case .value(let amount) = self { return amount }
        return nil
    }
}

enum ExpenseCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case groceries = "Groceries", home = "Home & supplies", utilities = "Bills & utilities"
    case dining = "Eating out", transport = "Transport", other = "Other"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .groceries: "basket"; case .home: "house"; case .utilities: "bolt"
        case .dining: "fork.knife"; case .transport: "car"; case .other: "ellipsis.circle"
        }
    }
}
struct ExpenseDraft {
    var merchant = ""
    var date = Date.now
    var amount = ""
    var currency = ExpenseRules.defaultCurrency
    var category: ExpenseCategory = .other
    var isRefund = false
    var notes = ""
}
struct ExpenseReportItem: Sendable {
    let id: UUID
    let merchant: String
    let day: String
    let amount: Int
    let currency: String
    let category: ExpenseCategory
    let isRefund: Bool
    let notes: String
    var signedAmount: Int { isRefund ? -amount : amount }
}
struct ExpenseMonthSummary: Sendable {
    let month: String
    let currency: String
    let items: [ExpenseReportItem]
    var spent: Int { items.filter { !$0.isRefund }.reduce(0) { $0 + $1.amount } }
    var refunded: Int { items.filter(\.isRefund).reduce(0) { $0 + $1.amount } }
    var net: Int { spent - refunded }
    func spending(in category: ExpenseCategory) -> Int { items.filter { $0.category == category && !$0.isRefund }.reduce(0) { $0 + $1.amount } }
}
enum ExpenseError: LocalizedError {
    case invalidAmount, invalidCurrency, invalidDate, tooLong
    var errorDescription: String? {
        switch self {
        case .invalidAmount: "Enter a positive amount with up to two decimal places, for example 12.50. Use Refund for money returned."
        case .invalidCurrency: "Choose a supported currency."
        case .invalidDate: "Choose a valid purchase date."
        case .tooLong: "Keep the store name under 200 characters and notes under 1,000 characters."
        }
    }
}
enum ExpenseRules {
    /// Two-decimal currencies only: amounts are stored as value × 100. Whole-unit currencies
    /// (JPY, KRW) need a minor-unit migration before they can be offered.
    static let currencies = ["USD", "INR", "EUR", "GBP", "CAD", "AUD", "NZD", "SGD", "AED", "SAR", "QAR",
                             "CHF", "SEK", "NOK", "DKK", "PLN", "ZAR", "MYR", "HKD", "MXN", "BRL", "LKR", "NPR", "BDT", "PKR"]
    /// Printed currency markers: ISO codes plus common symbols and abbreviations.
    static let currencyPattern = #"(?:"# + currencies.joined(separator: "|") + #"|Rs\.?|₹|\$|€|£|kr\.?|zł|RM|R(?=\s?\d))"#
    static var defaultCurrency: String { currencies.contains(Locale.current.currency?.identifier ?? "") ? Locale.current.currency?.identifier ?? "USD" : "USD" }
    static func minorUnits(_ input: String) throws -> Int {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.range(of: #"^[0-9]{1,10}([.,][0-9]{1,2})?$"#, options: .regularExpression) != nil,
              let decimal = Decimal(string: value.replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US_POSIX")),
              decimal > 0, decimal <= Decimal(9_999_999_999) else { throw ExpenseError.invalidAmount }
        return NSDecimalNumber(decimal: decimal * 100).intValue
    }
    static func validate(_ draft: ExpenseDraft) throws {
        _ = try HouseholdRules.requiredName(draft.merchant)
        guard draft.merchant.count <= 200, draft.notes.count <= 1_000 else { throw ExpenseError.tooLong }
        _ = try minorUnits(draft.amount)
        guard currencies.contains(draft.currency) else { throw ExpenseError.invalidCurrency }
        guard ShoppingEntryRules.date(for: HouseholdDay(draft.date).key) != nil else { throw ExpenseError.invalidDate }
    }
    static func money(_ minor: Int, currency: String) -> String { (Decimal(minor) / 100).formatted(.currency(code: currency)) }
    static func amountText(_ minor: Int) -> String { "\(minor / 100).\(abs(minor % 100) < 10 ? "0" : "")\(abs(minor % 100))" }
    static func month(_ date: Date) -> String { String(HouseholdDay(date).key.prefix(7)) }
    static func offset(_ month: String, by value: Int) -> String {
        guard let date = ShoppingEntryRules.date(for: month + "-15") else { return month }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = .current
        return Self.month(calendar.date(byAdding: .month, value: value, to: date) ?? date)
    }
    static func monthLabel(_ month: String) -> String {
        guard let date = ShoppingEntryRules.date(for: month + "-15") else { return month }
        return date.formatted(.dateTime.month(.wide).year())
    }
    static func shortMonthLabel(_ month: String) -> String {
        guard let date = ShoppingEntryRules.date(for: month + "-15") else { return month }
        return date.formatted(.dateTime.month(.abbreviated))
    }
    static func summary(_ items: [ExpenseReportItem], month: String, currency: String) -> ExpenseMonthSummary {
        ExpenseMonthSummary(month: month, currency: currency, items: items.filter { $0.day.hasPrefix(month + "-") && $0.currency == currency }.sorted { $0.day > $1.day })
    }
    static func receiptKey(_ text: String) -> String {
        ReceiptRules.hash(String(text.prefix(40_000)).lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " "))
    }
    /// Suggest only an explicitly labeled total; users confirm the complete receipt amount.
    static func receiptTotal(_ text: String) -> String? {
        receiptTotalEvidence(text).amount
    }

    static func receiptTotalEvidence(_ text: String) -> ReceiptTotalEvidence {
        let lines = String(text.prefix(40_000)).components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: #"^[*★]+\s*"#, with: "", options: .regularExpression) }.filter { !$0.isEmpty }
        let labels = [
            ReceiptVocabulary.label(ReceiptVocabulary.strongTotal),
            ReceiptVocabulary.label(ReceiptVocabulary.total),
            #"(?i)^amount\s*:\s*"#
        ]
        let printsCents = text.range(of: #"\d[.,]\d{2}(?!\d)"#, options: .regularExpression) != nil
        var selected: String?
        var labelSeen = false
        var paymentAmounts = Set<String>()
        for (priority, pattern) in labels.enumerated() {
            var amounts = Set<String>()
            for (index, line) in lines.enumerated() {
                guard let label = line.range(of: pattern, options: .regularExpression) else { continue }
                labelSeen = true
                let remainder = String(line[label.upperBound...])
                let candidate = remainder.isEmpty && index + 1 < lines.count ? lines[index + 1] : remainder
                // On a receipt that prints cents, an unmarked integer total may have lost its
                // decimal in OCR (e.g. "95.97" read as "95197"). Do not invent cents.
                if printsCents, candidate.trimmingCharacters(in: .whitespaces).range(of: #"^\d+$"#, options: .regularExpression) != nil { continue }
                if let amount = normalizedReceiptAmount(candidate) { amounts.insert(amount) }
            }
            // Conflicting totals need human review, never an arbitrary last-line choice.
            if priority == 2 { paymentAmounts = amounts }
            if selected == nil, !amounts.isEmpty {
                guard amounts.count == 1 else { return .conflicting }
                selected = amounts.first
            }
        }
        guard let selected else { return labelSeen ? .unreadable : .absent }
        // Payment evidence must agree even when the higher-priority TOTAL was readable.
        // One bill paid with two cards prints one "Amount:" per card; together they are the total.
        if paymentAmounts.count > 1, let total = try? minorUnits(selected),
           paymentAmounts.compactMap({ try? minorUnits($0) }).reduce(0, +) == total,
           paymentAmounts.count == lines.filter({ $0.range(of: labels[2], options: .regularExpression) != nil }).count {
            return .value(selected)
        }
        guard paymentAmounts.isEmpty || paymentAmounts == [selected] else {
            // Recover only a printed candidate corroborated by subtotal + tax.
            // Never repair a digit based on arithmetic alone or fabricate a total.
            func labeledAmount(_ pattern: String) -> Int? {
                let found = lines.compactMap { line -> Int? in
                    guard let label = line.range(of: pattern, options: .regularExpression) else { return nil }
                    let value = String(line[label.upperBound...]).trimmingCharacters(in: .whitespaces)
                    if ["0.00", "$0.00", "$ 0.00"].contains(value) { return 0 }
                    return normalizedReceiptAmount(value).flatMap { try? minorUnits($0) }
                }
                return Set(found).count == 1 ? found.first : nil
            }
            guard let subtotal = labeledAmount(ReceiptVocabulary.label(ReceiptVocabulary.subtotal)),
                  let tax = labeledAmount(ReceiptVocabulary.label(ReceiptVocabulary.tax)) else { return .conflicting }
            let expected = amountText(subtotal + tax)
            guard paymentAmounts == [expected] else { return .conflicting }
            return .value(expected)
        }
        return .value(selected)
    }

    static func normalizedReceiptAmount(_ input: String) -> String? {
        var value = input.trimmingCharacters(in: .whitespaces)
        let currency = currencyPattern
        value = value.replacingOccurrences(of: "(?i)^(?:" + currency + #"\s*){1,2}"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: #"(?i)\s*"# + currency + "$", with: "", options: .regularExpression)
        // Accept standard/Indian grouping, decimal commas, and whole-rupee totals.
        // A lone separator with three digits is ambiguous and is not guessed.
        if value.range(of: #"^(?:[0-9]{1,3}(?:,[0-9]{3})+|[0-9]{1,2}(?:,[0-9]{2})*,[0-9]{3})\.[0-9]{1,2}$"#, options: .regularExpression) != nil {
            value = value.replacingOccurrences(of: ",", with: "")
        } else if value.range(of: #"^[0-9]{1,3}(?:\.[0-9]{3})+,[0-9]{1,2}$"#, options: .regularExpression) != nil {
            value = value.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        }
        guard let minor = try? minorUnits(value) else { return nil }
        return amountText(minor)
    }

    static func receiptCurrency(_ text: String) -> String? {
        // Unambiguous symbols and printed ISO codes only; "$" alone could be any dollar.
        let symbols = [("INR", #"₹|\bRs\.?(?=\s*[0-9])"#), ("EUR", "€"), ("GBP", "£"), ("PLN", #"zł"#)]
        let patterns = symbols.map { ($0.0, "(?i)(" + $0.1 + ")") } + currencies.map { ($0, #"\b"# + $0 + #"\b"#) }
        let matches = Set(patterns.filter { text.range(of: $0.1, options: .regularExpression) != nil }.map(\.0))
        return matches.count == 1 ? matches.first : nil
    }
    static func csv(_ report: ExpenseMonthSummary) -> String {
        func cell(_ value: String) -> String {
            // Spreadsheet formula prefixes in user-entered text must stay literal.
            let safe = ["=", "+", "-", "@", "\t", "\r"].contains(where: { value.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix($0) }) ? "'" + value : value
            return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return (["Date,Store,Category,Type,Amount,Currency,Notes"] + report.items.map {
            [cell($0.day), cell($0.merchant), cell($0.category.rawValue), cell($0.isRefund ? "Refund" : "Expense"),
             ($0.isRefund ? "-" : "") + amountText($0.amount), cell($0.currency), cell($0.notes)].joined(separator: ",")
        }).joined(separator: "\r\n")
    }
}
