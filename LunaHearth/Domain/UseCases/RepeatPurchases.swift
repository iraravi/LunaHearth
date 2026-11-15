import Foundation

/// One dated purchase from history (shopping check-off or receipt line).
struct RepeatPurchaseRecord: Sendable, Equatable {
    let name: String
    let quantity: String
    let merchant: String
    let day: String
}

/// "Usually bought every N days, last bought M days ago." A prompt to review, never an automatic list write.
struct RepeatPurchaseSuggestion: Identifiable, Sendable, Equatable {
    let key: String
    let name: String
    let quantity: String
    let store: String
    let intervalDays: Int
    let lastDay: String
    let daysSince: Int
    var id: String { key }

    var detail: String {
        let since = daysSince == 1 ? "1 day ago" : "\(daysSince) days ago"
        return "Usually every \(intervalDays) days · last bought \(since)"
    }
}

/// Plain arithmetic over local purchase history. No model, no network.
enum RepeatPurchaseRules {
    /// Different purchase days needed before a rhythm is trusted.
    static let minimumPurchaseDays = 3
    /// Only the most recent days count, so habits can change.
    static let recentPurchaseDays = 8
    static let shortestInterval = 2
    static let longestInterval = 90
    /// Past this many intervals the household has probably stopped buying it.
    static let staleIntervals = 3

    static func due(_ records: [RepeatPurchaseRecord], today: String, excluding pending: [String] = [],
                    snoozed: [String: String] = [:]) -> [RepeatPurchaseSuggestion] {
        guard let todayNumber = dayNumber(today) else { return [] }
        let pendingKeys = Set(pending.map(IngredientMatching.key))
        var groups: [String: [(number: Int, record: RepeatPurchaseRecord)]] = [:]
        for record in records {
            let key = IngredientMatching.key(record.name)
            guard !key.isEmpty, let number = dayNumber(record.day), number <= todayNumber else { continue }
            groups[key, default: []].append((number, record))
        }
        let suggestions: [(ratio: Double, item: RepeatPurchaseSuggestion)] = groups.compactMap { key, entries in
            guard !pendingKeys.contains(key), (snoozed[key].map { $0 < today } ?? true) else { return nil }
            let days = Array(Set(entries.map(\.number))).sorted().suffix(recentPurchaseDays)
            guard days.count >= minimumPurchaseDays, let last = days.last else { return nil }
            let gaps = zip(days.dropFirst(), days).map { $0 - $1 }
            let interval = median(gaps)
            guard (shortestInterval...longestInterval).contains(interval) else { return nil }
            let since = todayNumber - last
            guard since >= interval, since <= interval * staleIntervals else { return nil }
            let recent = entries.sorted { ($0.number, $0.record.name) > ($1.number, $1.record.name) }
            let newest = recent[0].record
            let item = RepeatPurchaseSuggestion(key: key, name: newest.name.trimmingCharacters(in: .whitespacesAndNewlines),
                quantity: usualQuantity(recent.prefix(5).map(\.record.quantity)),
                store: recent.lazy.map { $0.record.merchant.trimmingCharacters(in: .whitespacesAndNewlines) }.first { !$0.isEmpty } ?? "",
                intervalDays: interval, lastDay: newest.day, daysSince: since)
            return (Double(since) / Double(interval), item)
        }
        return suggestions.sorted {
            $0.ratio != $1.ratio ? $0.ratio > $1.ratio : $0.item.name.localizedStandardCompare($1.item.name) == .orderedAscending
        }.map(\.item)
    }

    /// Hide until the item would next be due.
    static func snoozeUntil(_ item: RepeatPurchaseSuggestion, today: String) -> String? {
        guard let number = dayNumber(today) else { return nil }
        return dayKey(number + item.intervalDays)
    }

    static func median(_ values: [Int]) -> Int {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return 0 }
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? Int((Double(sorted[middle - 1] + sorted[middle]) / 2).rounded()) : sorted[middle]
    }

    /// Most frequent non-empty quantity; the newest wins a tie.
    private static func usualQuantity(_ newestFirst: [String]) -> String {
        let values = newestFirst.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        var counts: [String: Int] = [:]
        for value in values { counts[value, default: 0] += 1 }
        let top = counts.values.max() ?? 0
        return values.first { counts[$0] == top } ?? ""
    }

    /// Day keys as whole UTC day counts, so time zones and daylight saving never shift a gap.
    static func dayNumber(_ key: String) -> Int? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, let date = utc.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])),
              utc.component(.day, from: date) == parts[2] else { return nil }
        return Int(date.timeIntervalSince1970 / 86_400)
    }
    static func dayKey(_ number: Int) -> String {
        let parts = utc.dateComponents([.year, .month, .day], from: Date(timeIntervalSince1970: Double(number) * 86_400))
        return String(format: "%04d-%02d-%02d", parts.year ?? 1, parts.month ?? 1, parts.day ?? 1)
    }
    private static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()
}
