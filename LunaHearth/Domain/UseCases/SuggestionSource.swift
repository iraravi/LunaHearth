import Foundation

/// Where a suggested value came from. Every screen shows it beside the original so people can
/// judge it, and AI output is never applied without the person accepting it.
enum SuggestionSource: String, Codable, Sendable, CaseIterable {
    /// The person chose this exact value before (learned on this device).
    case memory
    /// A name the household already saved elsewhere, such as a pantry or shopping item.
    case savedItem
    /// Apple's on-device model.
    case ai
    /// Deterministic app rules (abbreviations, patterns, history).
    case rule

    var label: String {
        switch self {
        case .memory: "You named it"
        case .savedItem: "Your saved item"
        case .ai: "AI says"
        case .rule: "Suggested"
        }
    }

    var acceptTitle: String { self == .ai ? "Accept AI" : "Accept" }

    /// Choices the person made win over app rules, and rules over the model.
    var priority: Int {
        switch self {
        case .memory: 0
        case .savedItem: 1
        case .rule: 2
        case .ai: 3
        }
    }
}
