import Foundation
import Testing
@testable import LunaHearth

struct HouseholdRulesTests {
    @Test func validatesNamesAndEventRanges() throws {
        #expect(try HouseholdRules.requiredName("  Our Home\n") == "Our Home")
        #expect(throws: HouseholdValidation.self) { try HouseholdRules.requiredName(" \n ") }
        #expect(throws: HouseholdValidation.self) { try HouseholdRules.requiredName(String(repeating: "x", count: 201)) }
        var draft = EntryDraft(kind: .event, title: "School")
        draft.endDate = draft.date
        #expect(throws: HouseholdValidation.self) { try draft.validate() }
        draft.endDate = draft.date.addingTimeInterval(1)
        try draft.validate()
    }

    @Test func maintenanceRequiresAssetAndPositiveInterval() throws {
        var draft = EntryDraft(kind: .maintenance, title: "Filter")
        #expect(throws: HouseholdValidation.self) { try draft.validate() }
        draft.parentID = UUID()
        draft.repeats = true
        draft.intervalDays = 0
        #expect(throws: HouseholdValidation.self) { try draft.validate() }
        draft.intervalDays = 90
        try draft.validate()
    }

    @Test func dayBoundariesHandleOvernightEventsAndDST() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Chicago"))
        let day = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 12)))
        let interval = try #require(calendar.dateInterval(of: .day, for: day))
        #expect(interval.duration == 23 * 3600)
        #expect(HouseholdRules.eventsOverlap(start: interval.start.addingTimeInterval(-3600), end: interval.start.addingTimeInterval(1), day: day, calendar: calendar))
        #expect(!HouseholdRules.eventsOverlap(start: interval.start.addingTimeInterval(-3600), end: interval.start, day: day, calendar: calendar))
        #expect(!HouseholdRules.isDue(interval.end, on: day, calendar: calendar))
        #expect(!HouseholdRules.isDue(nil, on: day, calendar: calendar))
        #expect(HouseholdRules.isDue(interval.start.addingTimeInterval(-86400), on: day, calendar: calendar))
    }

    @Test func recurrenceUsesCalendarDaysAcrossDST() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Chicago"))
        let completion = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 9)))
        let next = try #require(HouseholdRules.nextMaintenanceDate(after: completion, intervalDays: 1, calendar: calendar))
        #expect(calendar.component(.hour, from: next) == 9)
        #expect(next.timeIntervalSince(completion) == 23 * 3600)
        #expect(HouseholdRules.nextMaintenanceDate(after: completion, intervalDays: nil, calendar: calendar) == nil)
    }

    @Test func civilDayUsesSelectedLocalDate() throws {
        let chicago = try #require(TimeZone(identifier: "America/Chicago"))
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = chicago
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 11, hour: 23)))
        #expect(HouseholdDay(date, timeZone: chicago).key == "2026-09-11")
        #expect(HouseholdDay(date, timeZone: tokyo).key == "2026-09-12")
    }
}
