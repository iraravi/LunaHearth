import Foundation

/// Builds the watch's picture of the home and reads dictated words. Pure rules, no
/// WatchConnectivity, so they are unit tested on the iPhone.
enum WatchSnapshotRules {
    static let maxItems = 150
    static let maxTasks = 40

    struct ShoppingInput: Sendable {
        var id: UUID, name: String, quantity: String?, store: String?
        var neededLater: Bool, isCompleted: Bool, modifiedAt: Date
        var category: PantryCategory
    }

    struct TaskInput: Sendable {
        var id: UUID, title: String, dueAt: Date?, person: String?, isCompleted: Bool, modifiedAt: Date
    }

    /// The order a typical store is walked: fresh food first, dry goods after.
    static let aisleOrder: [PantryCategory] = [.produce, .chilled, .meat, .grains, .pulses, .spices, .essentials, .other]

    static func snapshot(homeName: String?, shopping: [ShoppingInput], tasks: [TaskInput], applied: [UUID],
                         now: Date, calendar: Calendar = .current) -> WatchSnapshot {
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? now
        // Items needed now, plus ones bought today so a mistaken tick can be undone on the watch.
        let items = shopping
            .filter { !$0.neededLater && (!$0.isCompleted || $0.modifiedAt >= today) }
            .prefix(maxItems)
            .map { input in
                let detail = [input.quantity, input.store].compactMap { value -> String? in
                    let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    return trimmed.isEmpty ? nil : trimmed
                }.joined(separator: " · ")
                return WatchSnapshot.Item(id: input.id, name: input.name, detail: detail.isEmpty ? nil : detail,
                                          aisle: input.category.title, aisleOrder: aisleOrder.firstIndex(of: input.category) ?? aisleOrder.count,
                                          isBought: input.isCompleted)
            }
        // Open tasks due today or earlier, and ones finished today.
        let dueTasks = tasks
            .filter { task in
                guard let due = task.dueAt, due < tomorrow else { return false }
                return !task.isCompleted || task.modifiedAt >= today
            }
            .sorted { ($0.dueAt ?? .distantFuture) < ($1.dueAt ?? .distantFuture) }
            .prefix(maxTasks)
            .map { WatchSnapshot.Task(id: $0.id, title: $0.title, dueAt: $0.dueAt, person: $0.person, isDone: $0.isCompleted) }
        return WatchSnapshot(homeName: homeName, shopping: Array(items), tasks: Array(dueTasks),
                             updatedAt: now, appliedActionIDs: Array(applied.suffix(50)))
    }

    /// Dictation has no commas, so "milk and bread" is two items. Known pairs such as
    /// "mac and cheese" stay one. Text that already has separators is left as it is.
    static func dictatedList(_ text: String) -> String {
        let trimmed = String(text.prefix(WatchLink.maxAddLength)).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.contains(where: { ",;\n".contains($0) }) else { return trimmed }
        var protected = trimmed
        var restore: [String: String] = [:]
        for (index, pair) in keptPairs.enumerated() {
            let token = "⟦\(index)⟧"
            if let range = protected.range(of: pair, options: [.caseInsensitive]) {
                restore[token] = String(protected[range])
                protected.replaceSubrange(range, with: token)
            }
        }
        var split = protected.replacingOccurrences(of: #"\s+and\s+"#, with: ", ", options: [.regularExpression, .caseInsensitive])
        for (token, original) in restore { split = split.replacingOccurrences(of: token, with: original) }
        return split
    }

    /// Food names with "and" inside them.
    static let keptPairs = ["mac and cheese", "macaroni and cheese", "salt and pepper", "fish and chips", "bread and butter",
                            "peanut butter and jelly", "rice and beans", "half and half", "sweet and sour", "pork and beans",
                            "salt and vinegar", "sour cream and onion", "cookies and cream", "franks and beans", "chips and salsa",
                            "oil and vinegar", "spaghetti and meatballs", "biscuits and gravy"]
}
