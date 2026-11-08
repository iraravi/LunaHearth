import Foundation

enum CalendarDayPeriod: String, CaseIterable, Sendable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"

    static func period(start: Date, on day: Date, calendar: Calendar = .current) -> Self {
        let hour = calendar.component(.hour, from: max(start, calendar.startOfDay(for: day)))
        if hour < 12 { return .morning }
        if hour < 17 { return .afternoon }
        return .evening
    }

    var symbol: String {
        switch self {
        case .morning: "sun.horizon.fill"
        case .afternoon: "sun.max.fill"
        case .evening: "moon.stars.fill"
        }
    }
}

/// Calendar tasks show their due day; unfinished backlog and undated work belong to Today.
enum CalendarTaskVisibility {
    static func includes(due: Date?, completed: Bool, day: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard let due else { return !completed && calendar.isDate(day, inSameDayAs: now) }
        if calendar.isDate(due, inSameDayAs: day) { return true }
        return !completed && calendar.isDate(day, inSameDayAs: now) && due < calendar.startOfDay(for: day)
    }
}
