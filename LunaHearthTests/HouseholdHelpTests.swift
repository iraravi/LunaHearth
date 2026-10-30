import Testing
@testable import LunaHearth

struct HouseholdHelpTests {
    @Test func supportSearchFindsRecoveryAndSafetyInstructions() {
        let articles = HouseholdSupportArticle.all
        #expect(articles.contains { $0.id == "notifications" && $0.matches("  FOCUS  ") })
        #expect(articles.contains { $0.id == "sync" && $0.matches("reinstall") })
        #expect(articles.contains { $0.id == "safety" && $0.matches("allergens") })
        #expect(articles.allSatisfy { $0.matches("  ") })
        #expect(!articles.contains { $0.matches("zz-no-such-support") })
        #expect(Set(articles.map(\.id)).count == articles.count)
        #expect(Set(HouseholdHelpAnswer.all.map(\.id)).count == HouseholdHelpAnswer.all.count)
    }

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
