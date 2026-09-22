import Foundation
import Testing
@testable import LunaHearth

struct CalendarDayPeriodTests {
    @Test func boundariesUseLocalTime() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Chicago"))
        for (hour, expected) in [(0, CalendarDayPeriod.morning), (11, .morning), (12, .afternoon), (16, .afternoon), (17, .evening), (23, .evening)] {
            let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: hour)))
            #expect(CalendarDayPeriod.period(start: date, on: date, calendar: calendar) == expected)
        }
    }
    @Test func overnightContinuationStartsInMorningOfSelectedDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Chicago"))
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 23)))
        let tomorrow = try #require(calendar.date(byAdding: .day, value: 1, to: start))
        #expect(CalendarDayPeriod.period(start: start, on: tomorrow, calendar: calendar) == .morning)
    }
}
