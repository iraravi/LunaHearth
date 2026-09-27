import Foundation

enum AppFeature: String, CaseIterable, Codable, Sendable {
    case ai, aiMeals, aiShopping, aiPantry, aiCategories, aiDuplicates, aiReceiptNames, aiPhoto, aiBriefs
    case receipts, receiptImport, receiptExpenses, receiptPantry, pantryPhoto, pantryTemplates
    case shoppingIdeas, shoppingAssignments, shoppingToPantry, mealIdeas, weeklyMeals, mealReminder
    case notesSharing, calendarExport, reminders

    var title: String {
        switch self {
        case .ai: "On-device AI"
        case .aiMeals: "AI meal ideas"
        case .aiShopping: "AI shopping ideas"
        case .aiPantry: "AI pantry ideas"
        case .aiCategories: "AI categories"
        case .aiDuplicates: "AI similar items"
        case .aiReceiptNames: "AI receipt names"
        case .aiPhoto: "AI photo recognition"
        case .aiBriefs: "AI summaries"
        case .receipts: "Receipt scanning"
        case .receiptImport: "Receipt import"
        case .receiptExpenses: "Receipt expenses"
        case .receiptPantry: "Receipt pantry updates"
        case .pantryPhoto: "Kitchen photos"
        case .pantryTemplates: "Pantry starter lists"
        case .shoppingIdeas: "Shopping ideas"
        case .shoppingAssignments: "Shopping assignments"
        case .shoppingToPantry: "Shopping to pantry"
        case .mealIdeas: "Meal ideas"
        case .weeklyMeals: "Weekly meal planning"
        case .mealReminder: "Meal planning reminder"
        case .notesSharing: "Share to Notes"
        case .calendarExport: "Apple Calendar export"
        case .reminders: "Apple Reminders connection"
        }
    }
    var isAI: Bool { self != .ai && rawValue.hasPrefix("ai") }
}

struct FeatureSetting: Codable, Equatable, Sendable {
    var enabled: Bool
    var message: String?
}

/// Public editorial data only. No household IDs, targeting, URLs, or executable content.
struct PublicAppConfiguration: Codable, Equatable, Sendable {
    var schemaVersion: Int = 1
    var revision: Int
    var expiresAt: Date
    var features: [String: FeatureSetting]
    var announcement: String?
    var helpText: String?

    func validated(at now: Date) throws -> Self {
        guard schemaVersion == 1, revision >= 1, expiresAt > now,
              expiresAt.timeIntervalSince(now) <= 31 * 86_400,
              features.count <= 100,
              (announcement?.count ?? 0) <= 500,
              (helpText?.count ?? 0) <= 4_000,
              features.values.allSatisfy({ ($0.message?.count ?? 0) <= 300 }) else {
            throw ConfigurationError.invalid
        }
        return self
    }
    func allows(_ feature: AppFeature, at now: Date = .now) -> Bool {
        guard expiresAt > now else { return true }
        if feature.isAI && features[AppFeature.ai.rawValue]?.enabled == false { return false }
        return features[feature.rawValue]?.enabled ?? true
    }
    func message(for feature: AppFeature, at now: Date = .now) -> String {
        let key = feature.isAI && !allows(.ai, at: now) ? AppFeature.ai.rawValue : feature.rawValue
        let text = features[key]?.message?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let text, !text.isEmpty { return text }
        return "\(feature.title) is temporarily unavailable. Your saved data is still available."
    }
}

enum ConfigurationError: Error, LocalizedError {
    case invalid
    case paused(String)
    var errorDescription: String? {
        switch self {
        case .invalid: "The published settings could not be verified. Using saved settings or app defaults."
        case .paused(let message): message
        }
    }
}

protocol PublicConfigurationFetching: Sendable {
    func fetch() async throws -> PublicAppConfiguration
}
