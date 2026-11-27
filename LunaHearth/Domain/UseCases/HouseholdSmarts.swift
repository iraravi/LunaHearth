import Foundation

// MARK: Repeating tasks

/// Stored in `HouseholdTask.recurrenceRule` as "FREQ=WEEKLY;INTERVAL=2". Completing a repeating
/// task adds the next one; nothing is created ahead of time.
struct TaskRepeat: Hashable, Sendable, Identifiable {
    enum Frequency: String, CaseIterable, Sendable { case daily = "DAILY", weekly = "WEEKLY", monthly = "MONTHLY" }
    var frequency: Frequency
    var interval: Int
    var id: String { rule }

    init(_ frequency: Frequency, every interval: Int = 1) {
        self.frequency = frequency; self.interval = min(max(interval, 1), 365)
    }

    init?(rule: String?) {
        guard let rule, rule.count <= 100 else { return nil }
        var values: [String: String] = [:]
        for part in rule.split(separator: ";") {
            let pair = part.split(separator: "=", maxSplits: 1).map(String.init)
            if pair.count == 2 { values[pair[0].uppercased()] = pair[1].uppercased() }
        }
        guard let frequency = values["FREQ"].flatMap(Frequency.init(rawValue:)) else { return nil }
        let interval = values["INTERVAL"].flatMap(Int.init) ?? 1
        guard (1...365).contains(interval) else { return nil }
        self.init(frequency, every: interval)
    }

    var rule: String { "FREQ=\(frequency.rawValue);INTERVAL=\(interval)" }

    static let presets = [TaskRepeat(.daily), TaskRepeat(.weekly), TaskRepeat(.weekly, every: 2), TaskRepeat(.monthly)]

    var label: String {
        let unit = switch frequency { case .daily: "day"; case .weekly: "week"; case .monthly: "month" }
        return interval == 1 ? "Every \(unit)" : "Every \(interval) \(unit)s"
    }

    /// The next due date after completing: one step after the last due date, moved forward
    /// past today so an overdue chore doesn't come back already overdue.
    func nextDue(after due: Date?, completedAt: Date, calendar: Calendar = .current) -> Date {
        let component: Calendar.Component = switch frequency { case .daily: .day; case .weekly: .weekOfYear; case .monthly: .month }
        let today = calendar.startOfDay(for: completedAt)
        var next = calendar.date(byAdding: component, value: interval, to: due ?? completedAt) ?? completedAt
        var steps = 0
        while next < today && steps < 1_000 {
            next = calendar.date(byAdding: component, value: interval, to: next) ?? next; steps += 1
        }
        return next
    }

    /// Reads "every Sunday", "every 2 weeks", "every other day", "daily", "monthly".
    static func read(_ text: String, now: Date, calendar: Calendar) -> (repeat: TaskRepeat, firstDue: Date?, rest: String)? {
        func match(_ pattern: String) -> (groups: [String], rest: String)? {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let found = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let whole = Range(found.range, in: text) else { return nil }
            let groups = (0..<found.numberOfRanges).map { Range(found.range(at: $0), in: text).map { String(text[$0]) } ?? "" }
            var rest = text; rest.replaceSubrange(whole, with: " ")
            return (groups, QuickCaptureRules.tidySpaces(rest))
        }
        func unit(_ word: String) -> Frequency { word.lowercased().hasPrefix("da") ? .daily : word.lowercased().hasPrefix("month") ? .monthly : .weekly }
        let weekdays = "sunday|monday|tuesday|wednesday|thursday|friday|saturday"
        if let found = match(#"\b(?:every|each)\s+("# + weekdays + #")\b|\b(?:on\s+)?("# + weekdays + #")s\b"#) {
            let day = found.groups[1].isEmpty ? found.groups[2] : found.groups[1]
            let first = QuickCaptureRules.extractDate(day, now: now, calendar: calendar, past: false).date
            return (TaskRepeat(.weekly), first, found.rest)
        }
        if let found = match(#"\bevery\s+other\s+(day|week|month)\b"#) { return (TaskRepeat(unit(found.groups[1]), every: 2), nil, found.rest) }
        if let found = match(#"\bevery\s+(\d{1,3})\s+(days?|weeks?|months?)\b"#), let count = Int(found.groups[1]), (1...365).contains(count) {
            return (TaskRepeat(unit(found.groups[2]), every: count), nil, found.rest)
        }
        if let found = match(#"\b(?:every|each)\s+(day|week|month)\b|\b(daily|weekly|monthly)\b"#) {
            let word = found.groups[1].isEmpty ? found.groups[2] : found.groups[1]
            return (TaskRepeat(unit(word)), nil, found.rest)
        }
        return nil
    }
}

// MARK: Task order

/// Tasks are listed by what needs attention first.
enum TaskUrgency: Int, CaseIterable, Sendable, Comparable {
    case overdue, today, soon, later, anytime, done
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
    var title: String {
        switch self {
        case .overdue: "Overdue"
        case .today: "Today"
        case .soon: "This week"
        case .later: "Later"
        case .anytime: "Anytime"
        case .done: "Done"
        }
    }

    static func of(due: Date?, completed: Bool, now: Date, calendar: Calendar = .current) -> TaskUrgency {
        if completed { return .done }
        guard let due else { return .anytime }
        let today = calendar.startOfDay(for: now)
        let day = calendar.startOfDay(for: due)
        if day < today { return .overdue }
        if day == today { return .today }
        let week = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        return day < week ? .soon : .later
    }

    /// Groups in urgency order; inside a group, earliest due first, then by title.
    static func grouped<T>(_ items: [T], due: (T) -> Date?, completed: (T) -> Bool, title: (T) -> String,
                           now: Date, calendar: Calendar = .current) -> [(TaskUrgency, [T])] {
        let tagged = items.map { (of(due: due($0), completed: completed($0), now: now, calendar: calendar), $0) }
        return TaskUrgency.allCases.compactMap { urgency in
            let group = tagged.filter { $0.0 == urgency }.map(\.1).sorted {
                let a = due($0) ?? .distantFuture, b = due($1) ?? .distantFuture
                return a != b ? a < b : title($0).localizedStandardCompare(title($1)) == .orderedAscending
            }
            return group.isEmpty ? nil : (urgency, group)
        }
    }
}

// MARK: Shopping aisles

enum ShoppingAisle {
    /// A typical walk through a store: fresh food first, then bakery, chilled, meat, dry goods.
    static func order(_ category: PantryCategory) -> Int {
        switch category {
        case .produce: 0
        case .grains: 1
        case .chilled: 2
        case .meat: 3
        case .pulses: 4
        case .spices: 5
        case .essentials: 6
        case .household: 7
        case .other: 8
        }
    }

    static func sorted<T>(_ items: [T], name: (T) -> String, category: (T) -> PantryCategory) -> [T] {
        items.sorted {
            let a = order(category($0)), b = order(category($1))
            return a != b ? a < b : name($0).localizedStandardCompare(name($1)) == .orderedAscending
        }
    }
}

// MARK: Expenses

enum ExpenseInsights {
    static func merchantKey(_ merchant: String) -> String {
        merchant.lowercased().folding(options: .diacriticInsensitive, locale: nil).filter { $0.isLetter || $0.isNumber }
    }

    /// The category this household used most for the same payee, else one read from the name.
    static func suggestedCategory(for merchant: String, history: [ExpenseReportItem]) -> (category: ExpenseCategory, source: SuggestionSource)? {
        let key = merchantKey(merchant)
        guard key.count >= 2 else { return nil }
        let past = history.filter { merchantKey($0.merchant) == key && $0.category != .other }
        if !past.isEmpty {
            let counts = Dictionary(grouping: past, by: \.category).mapValues(\.count)
            if let best = counts.max(by: { $0.value != $1.value ? $0.value < $1.value : $0.key.rawValue > $1.key.rawValue }) {
                return (best.key, .memory)
            }
        }
        let read = QuickCaptureRules.category(for: merchant)
        return read == .other ? nil : (read, .rule)
    }

    /// Same payee, same amount and currency, within a day of each other: probably entered twice.
    static func possibleDuplicates(_ items: [ExpenseReportItem]) -> Set<UUID> {
        var flagged = Set<UUID>()
        let charges = items.filter { !$0.isRefund }
        let groups = Dictionary(grouping: charges) { "\(merchantKey($0.merchant))|\($0.amount)|\($0.currency)" }
        for group in groups.values where group.count > 1 {
            let dated = group.compactMap { item in ShoppingEntryRules.date(for: item.day).map { (item.id, $0) } }
            for (index, first) in dated.enumerated() {
                for second in dated[(index + 1)...] where abs(first.1.timeIntervalSince(second.1)) <= 86_400 * 1.5 {
                    flagged.insert(first.0); flagged.insert(second.0)
                }
            }
        }
        return flagged
    }

    /// One plain sentence about the month: the biggest change against last month and where it went.
    static func monthSentence(_ current: ExpenseMonthSummary, previous: ExpenseMonthSummary, previousLabel: String, inProgress: Bool) -> String? {
        guard current.spent > 0 else { return nil }
        let lead = inProgress ? "So far, " : ""
        func topMerchant(_ category: ExpenseCategory?) -> String? {
            let items = current.items.filter { !$0.isRefund && (category == nil || $0.category == category) }
            let totals = Dictionary(grouping: items) { merchantKey($0.merchant) }.mapValues { group in (group[0].merchant, group.reduce(0) { $0 + $1.amount }) }
            guard let best = totals.values.max(by: { $0.1 != $1.1 ? $0.1 < $1.1 : $0.0 > $1.0 }) else { return nil }
            let share = Double(best.1) / Double(max(items.reduce(0) { $0 + $1.amount }, 1))
            return items.count > 1 && share >= 0.4 ? best.0 : nil
        }
        let categories = ExpenseCategory.allCases.filter { current.spending(in: $0) > 0 || previous.spending(in: $0) > 0 }
        let main = categories.max { current.spending(in: $0) < current.spending(in: $1) } ?? .other
        let biggest = "\(lead)\(main.rawValue) is your biggest spend\(topMerchant(main).map { ", mostly \($0)" } ?? "")."
        guard previous.spent > 0 else { return biggest }
        // A month in progress is only compared where it has already gone past last month.
        let change = categories.map { ($0, current.spending(in: $0) - previous.spending(in: $0)) }.filter { !inProgress || $0.1 > 0 }
        guard let (category, delta) = change.max(by: { abs($0.1) < abs($1.1) }), delta != 0 else { return biggest }
        let before = previous.spending(in: category)
        let mostly = delta > 0 ? topMerchant(category).map { ", mostly \($0)" } ?? "" : ""
        if before == 0 {
            return "\(lead)\(category.rawValue) is new this month: \(ExpenseRules.money(delta, currency: current.currency))\(mostly)."
        }
        let percent = Int((Double(abs(delta)) / Double(before) * 100).rounded())
        guard percent >= 10 else { return biggest }
        return "\(lead)\(category.rawValue) \(delta > 0 ? "up" : "down") \(percent)% vs \(previousLabel)\(mostly)."
    }
}
