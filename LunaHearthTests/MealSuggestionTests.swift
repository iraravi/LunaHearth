import Foundation
import Testing
@testable import LunaHearth

struct MealSuggestionTests {
    @Test func generatedIdeasNeverSupplyCookingInstructions() throws {
        let idea = try #require(MealSuggestionRules.generatedIdea(id: "ai-0", name: "Rice bowl", ingredients: ["Rice"], minutes: 20))
        #expect(idea.steps.isEmpty)
        #expect(idea.ingredients == ["Rice"])
        #expect(MealSuggestionRules.generatedIdea(id: "ai-1", name: "", ingredients: ["Rice"], minutes: 20) == nil)
    }

    @Test func preferenceContextIsBounded() {
        #expect(MealSuggestionRules.boundedContext("  mild spice  ") == "mild spice")
        #expect(MealSuggestionRules.boundedContext(String(repeating: "a", count: 500)).count == 400)
    }
    @Test func cookingStyleFiltersOfflineIdeas() {
        let south = MealSuggestionRules.starters(for: .southIndian)
        #expect(south.contains { $0.id == "curd-rice" })
        #expect(!south.contains { $0.id == "pasta" })
        let american = MealSuggestionRules.starters(for: .american)
        #expect(american.contains { $0.id == "oats" })
        #expect(!american.contains { $0.id == "curd-rice" })
        #expect(MealSuggestionRules.starters(for: .any).count == MealSuggestionRules.starters.count)
        #expect(MealCookingStyle.allCases.allSatisfy { !MealSuggestionRules.starters(for: $0).isEmpty })
    }

    @Test func matchesPantryAndRanksCompleteIdeasFirst() throws {
        let result = MealSuggestionRules.ranked(MealSuggestionRules.starters, names: ["Rice", "Curd"])
        #expect(result.first?.id == "curd-rice")
        #expect(result.first?.missing(from: ["Rice", "Curd"]).isEmpty == true)
        #expect(!result.contains { $0.id == "pasta" })
        #expect(MealSuggestionRules.ranked(MealSuggestionRules.starters, names: []).isEmpty)
    }
    @Test func stockAvailabilityUsesPlannedCivilDay() {
        #expect(!MealSuggestionRules.available(isUsedUp: true, expiryDay: nil, plannedDay: "2026-09-15"))
        #expect(!MealSuggestionRules.available(isUsedUp: false, expiryDay: "2026-09-14", plannedDay: "2026-09-15"))
        #expect(MealSuggestionRules.available(isUsedUp: false, expiryDay: "2026-09-15", plannedDay: "2026-09-15"))
        #expect(MealSuggestionRules.available(isUsedUp: false, expiryDay: nil, plannedDay: "2026-09-15"))
    }
    @Test func rejectsMalformedProposals() {
        #expect(!MealSuggestionRules.valid(name: "", ingredients: ["Rice"], minutes: 20))
        #expect(!MealSuggestionRules.valid(name: "Rice", ingredients: [], minutes: 20))
        #expect(!MealSuggestionRules.valid(name: "Rice", ingredients: ["Rice"], minutes: -2))
    }
    @Test func dailyReminderUsesLocalFivePMThroughDST() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Chicago"))
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 1)))
        let next = try #require(calendar.nextDate(after: start, matching: MealSuggestionRules.reminderTime, matchingPolicy: .nextTime))
        #expect(calendar.component(.hour, from: next) == 17)
        #expect(calendar.component(.day, from: next) == 1)
    }
    @MainActor @Test func confirmedMealUsesRealRepositoryWithoutChangingStock() throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Test", owner: "", members: [])
        let idea = MealSuggestionRules.starters[0]
        try repo.add(EntryDraft(kind: .meal, title: idea.name, date: .now, notes: idea.ingredients.joined(separator: ", ")))
        #expect(repo.meals(on: .now).first?.title == "Curd rice")
        #expect(repo.inventory.isEmpty && repo.groceries.isEmpty)
    }
}
