import Foundation

extension LocalHouseholdRepository {
    /// Items the household usually rebuys by now, skipping anything already on the list.
    func buyAgainSuggestions(now: Date = .now, snoozed: [String: String] = [:]) -> [RepeatPurchaseSuggestion] {
        guard let home = household?.id else { return [] }
        let records = purchases.filter { $0.householdID == home }.map {
            RepeatPurchaseRecord(name: $0.name, quantity: $0.quantity, merchant: $0.merchant, day: $0.day)
        }
        return RepeatPurchaseRules.due(records, today: HouseholdDay(now).key,
            excluding: groceries.filter { !$0.isCompleted }.map(\.name), snoozed: snoozed)
    }

    /// Adds one reviewed suggestion with its usual quantity and store through the normal add path.
    func addBuyAgain(_ item: RepeatPurchaseSuggestion) throws {
        try FeatureAccess.require(.buyAgain)
        guard household != nil else { throw HouseholdValidation.invalidReference }
        guard duplicateShoppingItem(item.name) == nil else { throw InventoryError.alreadyShopping }
        var draft = EntryDraft(kind: .grocery, title: item.name)
        draft.storeName = item.store
        if !item.quantity.isEmpty, (try? ShoppingEntryRules.quantityText(item.quantity, unit: .custom)) != nil {
            draft.quantity = item.quantity; draft.quantityUnit = .custom
        }
        try add(draft)
    }
}

/// "Not now" is remembered on this device only; it hides an item until it would next be due.
enum BuyAgainSnoozes {
    static let storageKey = "buyAgain.snoozed.v1"

    static func decode(_ stored: String, householdID: UUID?) -> [String: String] {
        guard let householdID, let all = try? JSONDecoder().decode([String: String].self, from: Data(stored.utf8)) else { return [:] }
        let prefix = householdID.uuidString + "|"
        return Dictionary(uniqueKeysWithValues: all.compactMap { key, day in
            key.hasPrefix(prefix) ? (String(key.dropFirst(prefix.count)), day) : nil
        })
    }

    /// Returns the new stored value, dropping snoozes that have already ended.
    static func snooze(_ item: RepeatPurchaseSuggestion, householdID: UUID, stored: String, now: Date = .now) -> String {
        let today = HouseholdDay(now).key
        var all = (try? JSONDecoder().decode([String: String].self, from: Data(stored.utf8))) ?? [:]
        all = all.filter { $0.value >= today }
        if let until = RepeatPurchaseRules.snoozeUntil(item, today: today) { all[householdID.uuidString + "|" + item.key] = until }
        guard let data = try? JSONEncoder().encode(all) else { return stored }
        return String(decoding: data, as: UTF8.self)
    }
}
