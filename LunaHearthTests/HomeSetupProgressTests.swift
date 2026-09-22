import Foundation
import Testing
@testable import LunaHearth

struct HomeSetupProgressTests {
    @Test func newHomeStartsWithOneRealCompletedStep() {
        let progress = HomeSetupProgress(savedCompleted: "", savedSkipped: "", observed: [])
        #expect(progress.reviewedCount == 1)
        #expect(progress.totalCount == 7)
        #expect(progress.next == .pantry)
        #expect(!progress.isFinished)
    }
    @Test func skippedIsDistinctAndRealCompletionWins() {
        let progress = HomeSetupProgress(savedCompleted: "planning", savedSkipped: "pantry,shopping,receipts,meals,sharing", observed: [.pantry])
        #expect(progress.completed == [.planning, .pantry])
        #expect(progress.skipped == [.shopping, .receipts, .meals, .sharing])
        #expect(progress.isFinished)
        #expect(progress.next == nil)
    }
    @Test func completionSurvivesRecordRemovalAndMalformedPreferences() {
        let progress = HomeSetupProgress(savedCompleted: "pantry,pantry,unknown", savedSkipped: "garbage", observed: [])
        #expect(progress.completed == [.pantry])
        #expect(progress.reviewedCount == 2)
        #expect(progress.next == .shopping)
        #expect(HomeSetupProgress.decode(HomeSetupProgress.encode(progress.completed)) == progress.completed)
    }
    @Test func existingProgressKeepsCompletedStepsAndOffersNewChapters() {
        let progress = HomeSetupProgress(savedCompleted: "pantry,shopping,planning,sharing", savedSkipped: "", observed: [])
        #expect(progress.completed.count == 4)
        #expect(progress.next == .receipts)
        #expect(!progress.isFinished)
    }
    @Test func progressIsScopedToHousehold() {
        let first = UUID(), second = UUID()
        #expect(HomeSetupProgress.storageKey(householdID: first, field: "completed") != HomeSetupProgress.storageKey(householdID: second, field: "completed"))
        #expect(HomeSetupProgress.storageKey(householdID: first, field: "completed") != HomeSetupProgress.storageKey(householdID: first, field: "skipped"))
    }
}
