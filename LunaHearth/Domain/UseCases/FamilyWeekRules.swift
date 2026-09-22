import Foundation

/// Calendar arithmetic and bounded scheduling; no model or framework access.
enum FamilyWeekRules {
    static func occurs(start: Date, end: Date, on day: Date, calendar: Calendar = .current) -> Bool {
        guard let interval = calendar.dateInterval(of: .day, for: day) else { return false }
        return start < interval.end && end > interval.start
    }

    static func isBusyEvening(on day: Date, appointments: [AppointmentSlot], calendar: Calendar = .current) -> Bool {
        guard let start = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: day),
              let end = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: day) else { return false }
        // Merge overlap so two people at the same appointment do not double-count time.
        let slots = appointments.compactMap { slot -> AppointmentSlot? in
            let a = max(start, slot.start), b = min(end, slot.end)
            return a < b ? .init(start: a, end: b) : nil
        }.sorted { $0.start < $1.start }
        var seconds: TimeInterval = 0
        var lastEnd = start
        for slot in slots {
            seconds += max(0, slot.end.timeIntervalSince(max(lastEnd, slot.start)))
            lastEnd = max(lastEnd, slot.end)
        }
        return seconds >= 3600
    }

    /// A reviewable 30-minute prep reminder window between 4 and 7 PM.
    /// This does not claim that the full recipe fits in the window.
    static func prepTime(on day: Date, appointments: [AppointmentSlot], calendar: Calendar = .current) -> Date? {
        guard let end = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: day) else { return nil }
        for offset in stride(from: 30, through: 180, by: 15) {
            guard let start = calendar.date(byAdding: .minute, value: -offset, to: end) else { continue }
            let proposed = AppointmentSlot(start: start, end: start.addingTimeInterval(1800))
            if !appointments.contains(where: { AppointmentRules.overlaps(proposed, $0) }) { return start }
        }
        return nil
    }
}
