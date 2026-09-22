import Foundation
import CryptoKit

struct InventoryDraft {
    var name = ""
    var isLowStock = false
    var quantity = ""
    var measuredAmount = ""
    var measuredUnit: PantryUnit? = nil
    var packDetails = ""
    var storeName = ""
    var location = ""
    var hasPackedDate = false
    var packedDate = Date.now
    var hasExpiryDate = false
    var expiryDate = Date.now
    var hasPurchasedDate = false
    var purchasedDate = Date.now
}

enum InventoryError: LocalizedError {
    case invalidDateOrder, longDetail, alreadyShopping, duplicateIngredient
    var errorDescription: String? {
        switch self {
        case .invalidDateOrder: "The expiry date must be on or after the packed date."
        case .longDetail: "Keep each optional detail under 200 characters."
        case .duplicateIngredient: "This ingredient is already at home. Use the existing entry or confirm this is a separate pack."
        case .alreadyShopping: "This item is already on your shopping list."
        }
    }
}

enum InventoryRules {
    static func canRestock(isUsedUp: Bool, expiryDay: String?, today: String = HouseholdDay(.now).key) -> Bool {
        !isUsedUp && (expiryDay.map { $0 >= today } ?? true)
    }
    static func validate(_ draft: InventoryDraft) throws {
        _ = try HouseholdRules.requiredName(draft.name)
        if draft.measuredUnit != nil, PantryAmount.number(draft.measuredAmount) == nil { throw MealCookingError.amount }
        guard [draft.quantity, draft.packDetails, draft.storeName, draft.location].allSatisfy({ $0.count <= 200 }) else { throw InventoryError.longDetail }
        if draft.hasPackedDate && draft.hasExpiryDate,
           HouseholdDay(draft.expiryDate).key < HouseholdDay(draft.packedDate).key { throw InventoryError.invalidDateOrder }
    }
    static func optional(_ value: String) -> String? {
        let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? nil : clean
    }
    static func purchaseID(householdID: UUID, groceryID: UUID) -> UUID {
        var bytes = Array(SHA256.hash(data: Data("LunaHearth.inventory.purchase.v1|\(householdID)|\(groceryID)".utf8)).prefix(16))
        bytes[6] = (bytes[6] & 0x0f) | 0x80; bytes[8] = (bytes[8] & 0x3f) | 0x80
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
    static func expiryLabel(_ day: String?, today: String) -> String {
        guard let day, let date = ShoppingEntryRules.date(for: day) else { return "No expiry date" }
        let label = date.formatted(date: .abbreviated, time: .omitted)
        return day < today ? "Past expiry · \(label)" : day == today ? "Expiry today" : "Expires \(label)"
    }
    static func needsDateAttention(_ day: String?, today: Date = .now) -> Bool {
        guard let day, ShoppingEntryRules.date(for: day) != nil else { return false }
        let horizon = Calendar.current.date(byAdding: .day, value: 7, to: today) ?? today
        return day <= HouseholdDay(horizon).key
    }
}

enum PantryStyle: String, CaseIterable, Identifiable, Sendable {
    case southIndian = "South Indian", indian = "North Indian", american = "American basics", everyday = "Everyday basics"
    var id: String { rawValue }
    var starters: [String] { template.flatMap(\.names) }
}
enum PantryIdeasOutcome: Sendable, Equatable {
    case generated, unavailable, notEnabled, modelNotReady, failed, noNewIdeas
    var explanation: String {
        switch self {
        case .generated: "AI suggestions are ready. Nothing is saved until you select items and tap Add."
        case .unavailable: "On-device AI is unavailable on this device. You can still choose from the starter ideas below; custom instructions were not applied."
        case .notEnabled: "Apple Intelligence is turned off. Enable it in Settings → Apple Intelligence & Siri, then try again. These are starter ideas; custom instructions were not applied."
        case .modelNotReady: "Apple’s on-device model is not ready yet. Try again once it is ready. These are starter ideas; custom instructions were not applied."
        case .failed: "AI couldn’t finish this request. Try a shorter description. These are starter ideas; custom instructions were not applied."
        case .noNewIdeas: "AI returned no new ingredients after checking your saved pantry. Try a different request or cooking style. Nothing was added."
        }
    }
}
struct PantryIdeas: Sendable {
    let names: [String]
    let outcome: PantryIdeasOutcome
    var usedModel: Bool { outcome == .generated || outcome == .noNewIdeas }
}
protocol PantrySuggestionService: Sendable {
    func suggest(style: PantryStyle, request: String, existing: [String]) async throws -> PantryIdeas
}
enum PantrySuggestionRules {
    static func reviewed(_ names: [String], existing: [String]) -> [String] {
        var seen = Set(existing.map(IngredientMatching.key))
        return names.prefix(300).compactMap { value in
            let name = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, name.count <= 200, seen.insert(IngredientMatching.key(name)).inserted else { return nil }
            return name
        }.prefix(150).map { $0 }
    }
}


enum InventoryExpiryState: Equatable {
    case unknown, past, today, soon, later
}
extension InventoryRules {
    static func expiryState(_ day: String?, today: String) -> InventoryExpiryState {
        guard let day, ShoppingEntryRules.date(for: day) != nil,
              let reference = ShoppingEntryRules.date(for: today, timeZone: TimeZone(secondsFromGMT: 0) ?? .current) else { return .unknown }
        if day < today { return .past }
        if day == today { return .today }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        guard let horizon = calendar.date(byAdding: .day, value: 7, to: reference) else { return .later }
        return day <= HouseholdDay(horizon, timeZone: calendar.timeZone).key ? .soon : .later
    }
}
