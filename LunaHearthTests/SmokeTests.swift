import Testing
@testable import LunaHearth

struct SmokeTests {
    @Test func ruleBasedParserPreservesInput() async throws {
        let service = RuleBasedHouseholdIntelligenceService()
        let result = try await service.parse(text: "Change AC filter")
        #expect(result.title == "Change AC filter")
    }
}
