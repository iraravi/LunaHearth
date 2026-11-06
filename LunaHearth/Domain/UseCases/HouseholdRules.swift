import Foundation

enum EntryKind: String, CaseIterable, Identifiable, Sendable {
    case event = "Event", task = "Task", grocery = "Grocery", meal = "Meal"
    case floor = "Floor", room = "Room", asset = "Home Item", warranty = "Warranty", maintenance = "Maintenance"
    /// Presentation only: saved records and sync remain available for future releases.
    static var availableForQuickAdd: [EntryKind] { [.event, .task, .grocery, .meal] }
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .event: "calendar"
        case .task: "checklist"
        case .grocery: "cart"
        case .meal: "fork.knife"
        case .floor: "square.3.layers.3d"
        case .room: "door.left.hand.open"
        case .asset: "house"
        case .warranty: "checkmark.shield"
        case .maintenance: "wrench.and.screwdriver"
        }
    }
}

struct EntryDraft: Identifiable {
    var id = UUID()
    var kind: EntryKind = .task
    var title = ""
    var date = Date.now
    var endDate = Date.now.addingTimeInterval(3600)
    var hasDate = false
    var memberID: UUID?
    var parentID: UUID?
    var notes = ""
    var quantity = ""
    var storeName = ""
    var neededLater = false
    var mealType = "Dinner"
    var mealIngredients = ""
    var mealSteps = ""
    var mealServings = 2
    var mealAmountsPerServing: [String: String] = [:]
    var category: AssetCategory = .other
    var manufacturer = ""
    var modelNumber = ""
    var serialNumber = ""
    var intervalDays = 90
    var repeats = false
    var shoppingItem = ""
    var recordID: UUID?
    var quantityUnit: ShoppingUnit = .custom
    var shoppingDate: Date = ShoppingEntryRules.tomorrow()
    var allowDuplicateShoppingItem = false

    func validate() throws {
        _ = try HouseholdRules.requiredName(title)
        if kind == .grocery && !storeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { _ = try HouseholdRules.requiredName(storeName) }
        if kind == .grocery { _ = try ShoppingEntryRules.quantityText(quantity, unit: quantityUnit) }
        if kind == .event && endDate <= date { throw HouseholdValidation.invalidEventRange }
        if (kind == .maintenance || kind == .warranty) && parentID == nil {
            throw HouseholdValidation.assetRequired
        }
        if kind == .maintenance && repeats && intervalDays < 1 {
            throw HouseholdValidation.invalidInterval
        }
    }
}

enum HouseholdValidation: LocalizedError {
    case emptyName, longName, invalidEventRange, assetRequired, invalidInterval, invalidReference, householdExists
    var errorDescription: String? {
        switch self {
        case .emptyName: "Enter a name before saving."
        case .longName: "Keep names and titles to 200 characters or fewer."
        case .invalidEventRange: "The event must end after it starts."
        case .assetRequired: "Add a home item first, then select it here."
        case .invalidInterval: "Choose an interval of at least one day."
        case .invalidReference: "This item is no longer available in your household. Close this form and try again."
        case .householdExists: "A household is already set up on this device."
        }
    }
}

enum HouseholdRules {
    static func requiredName(_ value: String) throws -> String {
        let name = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw HouseholdValidation.emptyName }
        guard name.count <= 200 else { throw HouseholdValidation.longName }
        return name
    }

    static func eventsOverlap(start: Date, end: Date, day: Date, calendar: Calendar) -> Bool {
        guard let interval = calendar.dateInterval(of: .day, for: day) else { return false }
        return start < interval.end && end > interval.start
    }

    static func isDue(_ date: Date?, on day: Date, calendar: Calendar) -> Bool {
        guard let date, let interval = calendar.dateInterval(of: .day, for: day) else { return false }
        return date < interval.end
    }

    static func nextMaintenanceDate(after completion: Date, intervalDays: Int?, calendar: Calendar) -> Date? {
        guard let intervalDays, intervalDays > 0 else { return nil }
        return calendar.date(byAdding: .day, value: intervalDays, to: completion)
    }
}

/// Gregorian civil date, independent of the viewer's time zone. Persist the key, never midnight as an instant.
struct HouseholdDay: Equatable, Sendable {
    let key: String
    init(_ date: Date, timeZone: TimeZone = .current) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        key = String(format: "%04d-%02d-%02d", parts.year ?? 1, parts.month ?? 1, parts.day ?? 1)
    }
}
