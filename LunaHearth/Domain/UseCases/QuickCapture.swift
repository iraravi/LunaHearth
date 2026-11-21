import Foundation

/// What one typed or spoken phrase becomes. Everything is a proposal shown for review;
/// nothing is saved until the person taps Add.
enum QuickCaptureKind: String, CaseIterable, Identifiable, Sendable, Codable {
    case shopping, task, event, expense
    var id: String { rawValue }
    var title: String {
        switch self {
        case .shopping: "Shopping"
        case .task: "Task"
        case .event: "Event"
        case .expense: "Expense"
        }
    }
    var symbol: String {
        switch self {
        case .shopping: "cart"
        case .task: "checklist"
        case .event: "calendar"
        case .expense: "creditcard"
        }
    }
}

struct QuickCaptureItem: Identifiable, Sendable, Equatable {
    var id = UUID()
    var kind: QuickCaptureKind
    var title: String
    /// Start of day unless `hasTime`.
    var date: Date?
    var hasTime = false
    var quantity = ""
    var store = ""
    /// Plain decimal such as "45" or "12.50", always one of the figures written in the text.
    var amount = ""
    var currency = ""
    var category: ExpenseCategory = .other
    var source: SuggestionSource = .rule
    /// The phrase this item came from, shown so the person can judge the reading.
    var original: String
    var included = true
    /// A household member named in the note ("Ravi: take out trash", "…, Ravi").
    var memberName = ""
    var repeatRule: TaskRepeat?
    /// Why the item starts unchecked, e.g. "Already on your list".
    var note: String?
}

struct QuickCaptureMoney: Equatable, Sendable {
    let amount: String
    let currency: String?
}

enum QuickCaptureRules {
    static let maxItems = 20
    static let maxTextLength = 2_000

    // MARK: Splitting

    /// Commas, semicolons, new lines and "then" separate things. "and" does not:
    /// "mac and cheese" is one item.
    static func pieces(_ text: String) -> [String] {
        let limited = String(text.prefix(maxTextLength))
        // "1,200" is one number, not two items.
        let grouped = limited.replacingOccurrences(of: #"(?<=\d),(?=\d{3}\b)"#, with: "", options: .regularExpression)
        let separated = grouped.replacingOccurrences(of: #"\s+(?:then|also)\s+"#, with: ",", options: [.regularExpression, .caseInsensitive])
        return separated.split(whereSeparator: { ",;\n•".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters.subtracting(CharacterSet(charactersIn: "$₹£€")))) }
            .filter { $0.contains(where: \.isLetter) || $0.contains(where: \.isNumber) }
            .map { String($0.prefix(200)) }
            .prefix(maxItems).map { $0 }
    }

    // MARK: Parsing

    static func parse(_ text: String, now: Date = .now, calendar: Calendar = .current, savedStores: [String] = [], memberNames: [String] = []) -> [QuickCaptureItem] {
        var storeContext = "", storeDate: Date?
        var items: [QuickCaptureItem] = []
        for original in pieces(text) {
            // "…, Ravi" on its own assigns the item before it.
            if let name = memberNames.first(where: { $0.caseInsensitiveCompare(original) == .orderedSame }) {
                if var last = items.popLast() { if last.kind != .expense { last.memberName = name }; items.append(last) }
                continue
            }
            if let item = expense(original, now: now, calendar: calendar) { items.append(item); continue }
            let (member, piece) = assignee(original, names: memberNames)
            if let repeating = TaskRepeat.read(piece, now: now, calendar: calendar) {
                let when = extractDate(repeating.rest, now: now, calendar: calendar, past: false)
                let title = taskTitle(when.rest) ?? tidy(when.rest)
                guard title.contains(where: \.isLetter) else { continue }
                items.append(QuickCaptureItem(kind: .task, title: title, date: when.date ?? repeating.firstDue, hasTime: when.hasTime,
                                              original: original, memberName: member, repeatRule: repeating.repeat))
                continue
            }
            let before = items.count
            defer { if items.count > before, !member.isEmpty { items[items.count - 1].memberName = member } }
            let when = extractDate(piece, now: now, calendar: calendar, past: false)
            if let store = store(named: when.rest, saved: savedStores) {
                storeContext = store; storeDate = when.date
                if let date = when.date {
                    items.append(QuickCaptureItem(kind: .event, title: "\(store) trip", date: date, hasTime: when.hasTime, store: store, original: original))
                }
                continue
            }
            let lower = when.rest.lowercased()
            if let date = when.date, isEvent(lower) {
                items.append(QuickCaptureItem(kind: .event, title: tidy(when.rest), date: date, hasTime: when.hasTime, original: original))
            } else if let task = taskTitle(when.rest) {
                items.append(QuickCaptureItem(kind: .task, title: task, date: when.date, hasTime: when.hasTime, original: original))
            } else if isEvent(lower) || containsWord(lower, "due") {
                // An appointment without a day still needs doing; a dated "due" is a task.
                items.append(QuickCaptureItem(kind: .task, title: tidy(when.rest), date: when.date, hasTime: when.hasTime, original: original))
            } else {
                let (quantity, name) = quantityAndName(shoppingName(when.rest))
                guard name.contains(where: \.isLetter) else { continue }
                items.append(QuickCaptureItem(kind: .shopping, title: tidy(name), date: when.date ?? storeDate, quantity: quantity, store: storeContext, original: original))
            }
        }
        return items.filter { !$0.title.isEmpty }
    }

    // MARK: People

    /// "Ravi: take out trash", "ask Ravi to call the plumber", "call the plumber for Ravi".
    /// A trailing "for Ravi" only counts on chores, so "cake for Ravi" stays a shopping item.
    static func assignee(_ piece: String, names: [String]) -> (String, String) {
        for name in names.sorted(by: { $0.count > $1.count }) where name.count >= 2 {
            let escaped = NSRegularExpression.escapedPattern(for: name)
            if let range = piece.range(of: #"^(?:ask\s+)?"# + escaped + #"\s*(?::|-|,|\s+(?:to|should|will|can|needs\s+to|has\s+to|must))\s+"#, options: [.regularExpression, .caseInsensitive]) {
                return (name, String(piece[range.upperBound...]))
            }
            if let range = piece.range(of: #"\s+(?:for|by)\s+"# + escaped + #"$"#, options: [.regularExpression, .caseInsensitive]) {
                let rest = String(piece[..<range.lowerBound])
                if taskTitle(rest) != nil || isEvent(rest.lowercased()) { return (name, rest) }
            }
        }
        return ("", piece)
    }

    // MARK: Expenses

    static func expense(_ piece: String, now: Date, calendar: Calendar) -> QuickCaptureItem? {
        guard let (money, range) = findMoney(piece) else { return nil }
        var rest = piece; rest.removeSubrange(range)
        let when = extractDate(rest, now: now, calendar: calendar, past: true)
        var words = when.rest
        if let at = words.range(of: #"\b(?:at|from|@)\s+(.+)$"#, options: [.regularExpression, .caseInsensitive]) {
            let merchant = words[at].replacingOccurrences(of: #"^(?:at|from|@)\s+"#, with: "", options: [.regularExpression, .caseInsensitive])
            words = merchant.isEmpty ? words : merchant
        }
        words = words.replacingOccurrences(of: #"^(?:i\s+)?(?:spent|paid|pay|bought|for|on)\s+"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\s+(?:for|on)$"#, with: "", options: [.regularExpression, .caseInsensitive])
        let category = category(for: piece)
        let title = tidy(words).isEmpty ? category.rawValue : tidy(words)
        return QuickCaptureItem(kind: .expense, title: title, date: when.date ?? calendar.startOfDay(for: now), amount: money.amount,
                                currency: money.currency ?? "", category: category, original: piece)
    }

    /// Every money figure written in the text. AI amounts must be one of these.
    static func money(in text: String) -> [QuickCaptureMoney] {
        var found: [QuickCaptureMoney] = [], rest = text
        while let (money, range) = findMoney(rest) { found.append(money); rest.removeSubrange(range) }
        return found
    }

    private static let number = #"(\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?|\d{1,7}(?:\.\d{1,2})?)"#
    private static func findMoney(_ text: String) -> (QuickCaptureMoney, Range<String.Index>)? {
        let patterns: [(String, (String) -> String?)] = [
            (#"([$₹£€])\s?"# + number, { symbol in ["$": "USD", "₹": "INR", "£": "GBP", "€": "EUR"][symbol] }),
            (#"\b(rs\.?|inr|usd|eur|gbp)\s?"# + number, { code($0) }),
            (number + #"\s?(dollars?|bucks|rupees?|rs|usd|inr|euros?|eur|gbp)\b"#, { code($0) }),
        ]
        for (index, (pattern, currency)) in patterns.enumerated() {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let whole = Range(match.range, in: text),
                  let first = Range(match.range(at: 1), in: text), let second = Range(match.range(at: 2), in: text) else { continue }
            let (unit, value) = index == 2 ? (text[second], text[first]) : (text[first], text[second])
            let amount = value.replacingOccurrences(of: ",", with: "")
            guard (try? ExpenseRules.minorUnits(amount)) != nil else { continue }
            return (QuickCaptureMoney(amount: amount, currency: currency(String(unit))), whole)
        }
        return nil
    }

    private static func code(_ word: String) -> String? {
        let word = word.lowercased().replacingOccurrences(of: ".", with: "")
        if word.hasPrefix("rupee") || word == "rs" || word == "inr" { return "INR" }
        if word.hasPrefix("dollar") || word == "bucks" || word == "usd" { return "USD" }
        if word.hasPrefix("euro") || word == "eur" { return "EUR" }
        if word.hasPrefix("pound") || word == "gbp" { return "GBP" }
        return nil
    }

    static func category(for text: String) -> ExpenseCategory {
        let words = Set(text.lowercased().split(whereSeparator: { !$0.isLetter }).map(String.init))
        let lower = text.lowercased()
        func any(_ list: [String]) -> Bool { list.contains { $0.contains(" ") ? lower.contains($0) : words.contains($0) } }
        if any(["gas", "fuel", "petrol", "diesel", "uber", "lyft", "ola", "taxi", "cab", "parking", "toll", "metro", "bus", "train", "shell", "chevron", "exxon", "auto"]) { return .transport }
        if any(["dinner", "lunch", "breakfast", "brunch", "restaurant", "cafe", "coffee", "pizza", "takeout", "takeaway", "swiggy", "zomato", "starbucks", "doordash", "ubereats", "biryani"]) { return .dining }
        if any(["electric", "electricity", "power", "internet", "wifi", "broadband", "water bill", "phone bill", "mobile bill", "bill", "utility", "utilities", "recharge"]) { return .utilities }
        if any(["grocery", "groceries", "supermarket", "vegetables", "veggies", "fruit", "milk", "costco", "walmart", "kroger", "aldi", "safeway", "publix", "trader", "dmart", "bigbasket", "blinkit", "zepto", "instamart"]) { return .groceries }
        if any(["hardware", "home depot", "lowe", "lowes", "ikea", "furniture", "cleaning", "supplies", "plumber", "electrician", "repair"]) { return .home }
        return .other
    }

    // MARK: Dates

    struct When: Equatable { var date: Date?; var hasTime: Bool; var rest: String }

    private static let weekdays: [(String, Int)] = [
        ("sunday", 1), ("monday", 2), ("mon", 2), ("tuesday", 3), ("tues", 3), ("tue", 3), ("wednesday", 4), ("wed", 4),
        ("thursday", 5), ("thurs", 5), ("thur", 5), ("thu", 5), ("friday", 6), ("fri", 6), ("saturday", 7),
    ]

    /// Reads today/tonight/tomorrow/yesterday, weekday names and clock times, and returns the
    /// rest of the phrase without them. `past` reads a bare weekday as the most recent one.
    static func extractDate(_ text: String, now: Date, calendar: Calendar, past: Bool) -> When {
        var rest = text, day: Date?, hour: Int?, minute = 0
        let today = calendar.startOfDay(for: now)
        func take(_ pattern: String) -> [String]? {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: rest, range: NSRange(rest.startIndex..., in: rest)),
                  let whole = Range(match.range, in: rest) else { return nil }
            let groups = (0..<match.numberOfRanges).map { Range(match.range(at: $0), in: rest).map { String(rest[$0]) } ?? "" }
            rest.replaceSubrange(whole, with: " ")
            return groups
        }
        if let groups = take(#"\b(?:(?:on|by|for|this)\s+)?(today|tonight|tomorrow|tmrw|tmr|yesterday)\b"#) {
            switch groups[1].lowercased() {
            case "yesterday": day = calendar.date(byAdding: .day, value: -1, to: today)
            case "today": day = today
            case "tonight": day = today; hour = 19
            default: day = calendar.date(byAdding: .day, value: 1, to: today)
            }
        } else if let groups = take(#"\b(?:(next|last|this|on|by|for)\s+)?(sunday|monday|tuesday|wednesday|thursday|friday|saturday|mon|tues|tue|wed|thurs|thur|thu|fri)\b"#),
                  let target = weekdays.first(where: { $0.0 == groups[2].lowercased() })?.1 {
            let current = calendar.component(.weekday, from: today)
            let modifier = groups[1].lowercased()
            if past || modifier == "last" {
                var back = (current - target + 7) % 7
                if modifier == "last" && back == 0 { back = 7 }
                day = calendar.date(byAdding: .day, value: -back, to: today)
            } else {
                var ahead = (target - current + 7) % 7
                if modifier == "next" && ahead == 0 { ahead = 7 }
                day = calendar.date(byAdding: .day, value: ahead, to: today)
            }
        }
        if let groups = take(#"\b(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.|p\.m\.)(?=\s|$|[,.])"#), let value = Int(groups[1]), (1...12).contains(value) {
            let pm = groups[3].lowercased().hasPrefix("p")
            hour = value % 12 + (pm ? 12 : 0); minute = Int(groups[2]) ?? 0
        } else if let groups = take(#"\bat\s+(\d{1,2})(?::(\d{2}))?\b"#), let value = Int(groups[1]), (0...23).contains(value) {
            // "at 5" means 5 pm for household plans; a 24-hour value is kept as written.
            hour = value <= 6 ? value + 12 : value; minute = Int(groups[2]) ?? 0
        } else if take(#"\b(?:at\s+)?noon\b"#) != nil { hour = 12 }
        guard (0...59).contains(minute) else { return When(date: nil, hasTime: false, rest: tidySpaces(text)) }
        if let hour {
            var base = day ?? today
            let timed = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
            if day == nil && !past && timed < now { base = calendar.date(byAdding: .day, value: 1, to: base) ?? base }
            day = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base)
        }
        return When(date: day, hasTime: hour != nil && day != nil, rest: tidySpaces(rest))
    }

    // MARK: Kinds

    private static let eventWords = ["appointment", "appt", "dentist", "doctor", "meeting", "party", "class", "practice", "lesson",
                                     "game", "recital", "birthday", "flight", "visit", "interview", "concert", "match", "dinner with",
                                     "lunch with", "playdate", "checkup", "check-up", "pooja", "puja", "function", "wedding"]
    private static let taskVerbs = ["call", "change", "clean", "fix", "pay", "book", "schedule", "take", "pick up", "drop", "drop off",
                                    "renew", "replace", "email", "text", "mow", "water the", "water plants", "wash", "return", "cancel", "check", "finish",
                                    "send", "file", "empty", "vacuum", "sweep", "mop", "feed", "walk", "charge", "update", "submit",
                                    "sign", "prepare", "repair", "install", "order", "write", "reply", "remind", "move", "sort", "iron",
                                    "fold", "cook", "bake", "service", "pack", "print", "post", "mail", "collect", "visit", "register"]

    static func isEvent(_ lower: String) -> Bool { eventWords.contains { containsWord(lower, $0) } }

    /// "remind me to call mom" → "Call mom"; a phrase that starts with a chore verb is a task.
    static func taskTitle(_ text: String) -> String? {
        var value = tidySpaces(text)
        for prefix in [#"^(?:please\s+)?remind\s+me\s+to\s+"#, #"^(?:i\s+)?(?:need|have|got)\s+to\s+"#, #"^(?:don'?t|do\s+not)\s+forget\s+to\s+"#, #"^todo:?\s+"#, #"^to\s+"#] {
            if let range = value.range(of: prefix, options: [.regularExpression, .caseInsensitive]) {
                value.removeSubrange(range)
                return value.contains(where: \.isLetter) ? tidy(value) : nil
            }
        }
        let lower = value.lowercased()
        guard taskVerbs.contains(where: { lower == $0 || lower.hasPrefix($0 + " ") }) else { return nil }
        return tidy(value)
    }

    private static func shoppingName(_ text: String) -> String {
        text.replacingOccurrences(of: #"^(?:(?:we|i)\s+)?(?:need\s+to\s+buy|need|buy|get|grab|pick\s+up)\s+(?:some\s+)?"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\s+(?:from|at)\s+\S.*$"#, with: "", options: [.regularExpression, .caseInsensitive])
    }

    private static let numberWords = ["a": "1", "an": "1", "one": "1", "two": "2", "three": "3", "four": "4", "five": "5", "six": "6",
                                      "seven": "7", "eight": "8", "nine": "9", "ten": "10", "twelve": "12", "a dozen": "12", "dozen": "12"]
    private static let units = #"(?:kgs?|g|grams?|lbs?|pounds?|oz|l|litres?|liters?|ml|packs?|packets?|bottles?|cartons?|dozen|bunch(?:es)?|loaf|loaves|gallons?|bags?|box(?:es)?|cans?|jars?|tins?|tubs?|rolls?|pcs?|pieces?)"#

    /// "2 kg rice" → ("2 kg", "rice"); "milk x2" → ("2", "milk"); "a dozen eggs" → ("12", "eggs").
    static func quantityAndName(_ text: String) -> (String, String) {
        let value = tidySpaces(text)
        if let range = value.range(of: #"^(\d+(?:\.\d+)?)\s*x?\s*(?:"# + units + #"\b)?(?:\s+of)?\s+"#, options: [.regularExpression, .caseInsensitive]) {
            let quantity = value[range].replacingOccurrences(of: #"\s+of\s*$|\s*x\s*$"#, with: "", options: [.regularExpression, .caseInsensitive])
            return (tidySpaces(quantity), String(value[range.upperBound...]))
        }
        if let range = value.range(of: #"\s*(?:x\s*(\d+)|(\d+)\s*x)$"#, options: [.regularExpression, .caseInsensitive]) {
            let digits = value[range].filter(\.isNumber)
            return (String(digits), String(value[..<range.lowerBound]))
        }
        let lower = value.lowercased()
        for (word, digits) in numberWords.sorted(by: { $0.key.count > $1.key.count }) where lower.hasPrefix(word + " ") {
            let remainder = String(value.dropFirst(word.count + 1))
            if let unit = remainder.range(of: #"^"# + units + #"\b(?:\s+of)?\s+"#, options: [.regularExpression, .caseInsensitive]) {
                let unitText = remainder[unit].replacingOccurrences(of: #"\s+of\s*$"#, with: "", options: [.regularExpression, .caseInsensitive])
                return (tidySpaces(digits + " " + unitText), String(remainder[unit.upperBound...]))
            }
            return (word == "a" || word == "an" ? "" : digits, remainder)
        }
        return ("", value)
    }

    // MARK: Stores

    static func store(named text: String, saved: [String]) -> String? {
        let cleaned = text.replacingOccurrences(of: #"^(?:go\s+to|going\s+to|trip\s+to|run\s+to|shop\s+at|at|to)\s+|\s+(?:trip|run|shopping|shop)$"#, with: "", options: [.regularExpression, .caseInsensitive])
        let key = storeKey(cleaned)
        guard key.count >= 3 else { return nil }
        if let name = saved.first(where: { storeKey($0) == key }) { return name }
        return ShoppingStoreCatalog.stores.first { store in ([store.name] + store.printedAs).contains { storeKey($0) == key } }?.name
    }

    private static func storeKey(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    // MARK: Text

    private static func containsWord(_ text: String, _ word: String) -> Bool {
        text.range(of: #"\b"# + NSRegularExpression.escapedPattern(for: word) + #"\b"#, options: .regularExpression) != nil
    }

    static func tidySpaces(_ text: String) -> String {
        text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Trims leftover joining words and capitalizes the first letter only, keeping brand casing.
    static func tidy(_ text: String) -> String {
        var value = tidySpaces(text)
            .replacingOccurrences(of: #"^(?:and|on|at|by|for|the|to)\s+|\s+(?:on|at|by|for|and|to)$"#, with: "", options: [.regularExpression, .caseInsensitive])
        value = tidySpaces(value).trimmingCharacters(in: .punctuationCharacters.union(.whitespaces))
        guard let first = value.first else { return "" }
        return first.uppercased() + value.dropFirst()
    }
}

// MARK: Saving

extension QuickCaptureItem {
    /// The household entry this item saves as. Expenses use `expenseDraft` instead.
    func entryDraft(now: Date = .now, calendar: Calendar = .current, memberID: UUID? = nil) -> EntryDraft? {
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        switch kind {
        case .shopping:
            var draft = EntryDraft(kind: .grocery, title: name, memberID: memberID, quantity: quantity, storeName: store, quantityUnit: .custom)
            if let date, date >= calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now {
                draft.neededLater = true; draft.shoppingDate = date
            }
            return draft
        case .task:
            var draft = EntryDraft(kind: .task, title: name, memberID: memberID)
            if let date { draft.hasDate = true; draft.date = date }
            draft.recurrenceRule = repeatRule?.rule
            return draft
        case .event:
            let start = hasTime ? (date ?? now) : calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date ?? now) ?? now
            return EntryDraft(kind: .event, title: name, date: start, endDate: start.addingTimeInterval(3600), memberID: memberID)
        case .expense:
            return nil
        }
    }

    func expenseDraft(defaultCurrency: String = ExpenseRules.defaultCurrency, now: Date = .now) -> ExpenseDraft? {
        guard kind == .expense else { return nil }
        var draft = ExpenseDraft()
        draft.merchant = title.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.amount = amount
        draft.currency = ExpenseRules.currencies.contains(currency) ? currency : defaultCurrency
        draft.category = category
        draft.date = date ?? now
        return draft
    }

    /// One line under the title: when, how much, where.
    var detail: String {
        var parts: [String] = []
        if kind == .expense, let minor = try? ExpenseRules.minorUnits(amount) {
            parts.append(ExpenseRules.money(minor, currency: ExpenseRules.currencies.contains(currency) ? currency : ExpenseRules.defaultCurrency))
            parts.append(category.rawValue)
        }
        if !quantity.isEmpty { parts.append(quantity) }
        if let repeatRule { parts.append(repeatRule.label) }
        if !memberName.isEmpty { parts.append(memberName) }
        if !store.isEmpty && kind == .shopping { parts.append(store) }
        if let date {
            parts.append(hasTime ? date.formatted(.dateTime.weekday(.abbreviated).hour().minute()) : date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
        }
        return parts.joined(separator: " · ")
    }
}
