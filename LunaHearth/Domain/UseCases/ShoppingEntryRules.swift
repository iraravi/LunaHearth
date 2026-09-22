import Foundation

enum ShoppingUnit: String, CaseIterable, Identifiable, Codable, Sendable {
    case piece, kg, g, lb, oz, litre, ml, pack, bottle, carton, dozen, custom
    var id: String { rawValue }
    var title: String {
        switch self {
        case .piece: "pieces"
        case .litre: "L"
        case .pack: "packs"
        case .bottle: "bottles"
        case .carton: "cartons"
        case .custom: "Other"
        default: rawValue
        }
    }
}

enum ShoppingEntryError: LocalizedError {
    case invalidAmount, duplicateItem, invalidDay
    var errorDescription: String? {
        switch self {
        case .invalidAmount: "Enter an amount greater than zero, such as 2 or 0.5."
        case .duplicateItem: "This item is already on your shopping list. Review the duplicate message before adding another."
        case .invalidDay: "Choose a valid shopping date."
        }
    }
}

enum ShoppingEntryRules {
    static func amount(_ input: String, unit: ShoppingUnit) throws -> String {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count <= 100 else { throw HouseholdValidation.longName }
        if unit == .custom || value.isEmpty { return value }
        guard value.range(of: "^[0-9]+([.,][0-9]{1,3})?$", options: .regularExpression) != nil,
              let decimal = Decimal(string: value.replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US_POSIX")), decimal > 0, decimal <= 1_000_000 else { throw ShoppingEntryError.invalidAmount }
        return NSDecimalNumber(decimal: decimal).stringValue
    }
    static func quantityText(_ input: String, unit: ShoppingUnit) throws -> String {
        let value = try amount(input, unit: unit)
        guard !value.isEmpty, unit != .custom else { return value }
        let singular: String
        switch unit {
        case .piece: singular = "piece"
        case .pack: singular = "pack"
        case .bottle: singular = "bottle"
        case .carton: singular = "carton"
        default: singular = unit.title
        }
        return "\(value) \(value == "1" ? singular : unit.title)"
    }
    static func date(for key: String, timeZone: TimeZone = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = timeZone
        guard let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12)), HouseholdDay(date, timeZone: timeZone).key == key else { return nil }
        return date
    }
    static func tomorrow() -> Date { Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now }
}
