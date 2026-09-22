import Foundation
import Testing
@testable import LunaHearth

@MainActor struct FamilyWeekTests {
    private func calendar() throws -> Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = try #require(TimeZone(identifier: "America/Chicago"))
        return value
    }
    @Test func busyEveningsMergeOverlapsAndIgnoreMornings() throws {
        let cal = try calendar()
        let day = try #require(cal.date(from: DateComponents(year: 2026, month: 10, day: 1)))
        let four = try #require(cal.date(bySettingHour: 16, minute: 0, second: 0, of: day))
        let halfHour = AppointmentSlot(start: four, end: four.addingTimeInterval(1800))
        #expect(!FamilyWeekRules.isBusyEvening(on: day, appointments: [halfHour, halfHour], calendar: cal))
        #expect(FamilyWeekRules.isBusyEvening(on: day, appointments: [halfHour, .init(start: halfHour.end, end: four.addingTimeInterval(3600))], calendar: cal))
        #expect(!FamilyWeekRules.isBusyEvening(on: day, appointments: [.init(start: day, end: four)], calendar: cal))
    }
    @Test func prepWindowAvoidsOvernightAndFullEveningAndPreservesDST() throws {
        let cal = try calendar()
        let day = try #require(cal.date(from: DateComponents(year: 2026, month: 11, day: 1)))
        let free = try #require(FamilyWeekRules.prepTime(on: day, appointments: [], calendar: cal))
        #expect(cal.component(.hour, from: free) == 18)
        #expect(cal.component(.minute, from: free) == 30)
        let late = AppointmentSlot(start: free, end: free.addingTimeInterval(7200))
        let earlier = try #require(FamilyWeekRules.prepTime(on: day, appointments: [late], calendar: cal))
        #expect(earlier.addingTimeInterval(1800) <= late.start)
        let full = AppointmentSlot(start: day, end: day.addingTimeInterval(2 * 86400))
        #expect(FamilyWeekRules.prepTime(on: day, appointments: [full], calendar: cal) == nil)
        let days = WeeklyMealRules.days(from: day, calendar: cal)
        #expect(days.count == 7)
        #expect(days[1].timeIntervalSince(days[0]) == 25 * 3600)
    }
    @Test func eventDayIntersectionExcludesMidnightEnd() throws {
        let cal = try calendar()
        let day = try #require(cal.date(from: DateComponents(year: 2026, month: 10, day: 1)))
        #expect(!FamilyWeekRules.occurs(start: day.addingTimeInterval(-3600), end: day, on: day, calendar: cal))
        #expect(FamilyWeekRules.occurs(start: day.addingTimeInterval(-3600), end: day.addingTimeInterval(1), on: day, calendar: cal))
    }
    @Test func wholeWeekSavesAllMealsWithDinnerPrepOnly() throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "Ravi", members: [])
        let home = try #require(repo.household?.id)
        let start = try #require(Calendar.current.date(byAdding: .day, value: 2, to: .now))
        var drafts: [EntryDraft] = []
        var prep: [UUID: Date] = [:]
        for day in WeeklyMealRules.days(from: start) {
            for type in ["Breakfast", "Lunch", "Dinner"] {
                let draft = EntryDraft(kind: .meal, title: type, date: day, mealType: type)
                drafts.append(draft)
                if type == "Dinner" { prep[draft.id] = FamilyWeekRules.prepTime(on: day, appointments: []) }
            }
        }
        try repo.saveWeeklyDrafts(drafts, householdID: home, prepTimes: prep)
        #expect(repo.meals.count == 21)
        #expect(repo.tasks.count == 7)
        for type in ["Breakfast", "Lunch", "Dinner"] { #expect(repo.meals.filter { $0.mealType == type }.count == 7) }
        #expect(repo.tasks.allSatisfy { task in repo.meals.contains { $0.id == task.mealID && $0.mealType == "Dinner" } })
    }

    @Test func remindersRequireExplicitValidSelection() throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "Ravi", members: [])
        let home = try #require(repo.household?.id)
        let day = try #require(Calendar.current.date(byAdding: .day, value: 3, to: .now))
        let draft = EntryDraft(kind: .meal, title: "Breakfast", date: day, mealType: "Breakfast")
        let prep = try #require(FamilyWeekRules.prepTime(on: day, appointments: []))
        #expect(throws: MealCookingError.self) { try repo.saveWeeklyDrafts([draft], householdID: home, prepTimes: [draft.id: prep]) }
        #expect(throws: MealCookingError.self) { try repo.saveWeeklyDrafts([draft], householdID: home, prepTimes: [UUID(): prep]) }
        #expect(repo.meals.isEmpty && repo.tasks.isEmpty)
        try repo.saveWeeklyDrafts([draft], householdID: home)
        #expect(repo.meals.count == 1 && repo.tasks.isEmpty)
    }

    @Test func mealAndOptionalPrepSaveAtomicallyAndRejectStaleSchedule() throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "Ravi", members: [])
        let home = try #require(repo.household?.id)
        let day = try #require(Calendar.current.date(byAdding: .day, value: 2, to: .now))
        let prep = try #require(FamilyWeekRules.prepTime(on: day, appointments: []))
        let draft = EntryDraft(kind: .meal, title: "Dinner", date: day, mealType: "Dinner")
        _ = try repo.saveAppointment(.init(title: "Busy", start: prep, end: prep.addingTimeInterval(1800)), householdID: home)
        #expect(throws: MealCookingError.self) { try repo.saveWeeklyDrafts([draft], householdID: home, prepTimes: [draft.id: prep]) }
        #expect(repo.meals.isEmpty && repo.tasks.isEmpty)
        let updated = try #require(FamilyWeekRules.prepTime(on: day, appointments: repo.events.map { .init(start: $0.startAt, end: $0.endAt) }))
        try repo.saveWeeklyDrafts([draft], householdID: home, prepTimes: [draft.id: updated])
        #expect(repo.meals.count == 1 && repo.tasks.count == 1)
        #expect(repo.tasks.first?.mealID == repo.meals.first?.id)
        #expect(repo.tasks.first?.dueAt == updated)
        #expect(repo.tasks.first?.assignedMemberID == nil)
        #expect(throws: MealCookingError.self) { try repo.saveWeeklyDrafts([draft], householdID: home, prepTimes: [draft.id: updated]) }
        #expect(repo.tasks.count == 1)
        let restored = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try restored.restoreBackup(repo.makeBackup())
        #expect(restored.tasks.first?.mealID == restored.meals.first?.id)
    }
}
