import Testing
@testable import LunaHearth

struct HouseholdHelpTests {
    @Test func searchFindsRelevantGuidesAndAnswers() {
        #expect(HouseholdHelpTopic.pantry.matches("  EXPIRY  "))
        #expect(HouseholdHelpTopic.connected.matches("receipt"))
        #expect(HouseholdHelpTopic.calendar.matches("permission"))
        #expect(HouseholdHelpAnswer.all.contains { $0.id == "sync" && $0.matches("another device") })
        #expect(!HouseholdHelpTopic.allCases.contains { $0.matches("zz-no-such-topic") })
        #expect(HouseholdHelpTopic.allCases.allSatisfy { $0.matches("   ") })
    }

    @Test func learningProgressKeepsObservedStepsWhenChecklistIsHidden() {
        let observed = HomeSetupProgress(savedCompleted: "pantry", savedSkipped: "shopping", observed: [.shopping])
        let persisted = HomeSetupProgress.encode(observed.completed)
        let reopened = HomeSetupProgress(savedCompleted: persisted, savedSkipped: "shopping", observed: [])
        #expect(reopened.completed == [.pantry, .shopping])
        #expect(reopened.skipped.isEmpty)
        #expect(reopened.next == .receipts)
    }
}
