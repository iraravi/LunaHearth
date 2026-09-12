import Foundation

struct ParsedHouseholdInput: Sendable, Equatable {
    enum Kind: String, Sendable { case event, task, grocery, maintenance, unknown }
    let kind: Kind
    let title: String
    let date: Date?
}

protocol HouseholdIntelligenceService: Sendable {
    func parse(text: String) async throws -> ParsedHouseholdInput
}

actor RuleBasedHouseholdIntelligenceService: HouseholdIntelligenceService {
    func parse(text: String) async throws -> ParsedHouseholdInput {
        ParsedHouseholdInput(kind: .unknown, title: text.trimmingCharacters(in: .whitespacesAndNewlines), date: nil)
    }
}
