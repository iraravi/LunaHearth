import Foundation

enum AppointmentKind: String, CaseIterable, Codable, Sendable {
    case appointment = "Appointment", doctor = "Doctor", school = "School", sport = "Sport", work = "Work", family = "Family"
    var symbol: String {
        switch self {
        case .appointment: "calendar.badge.clock"
        case .doctor: "stethoscope"
        case .school: "backpack.fill"
        case .sport: "figure.run"
        case .work: "briefcase.fill"
        case .family: "person.2.fill"
        }
    }
}
enum AppointmentRepeat: String, CaseIterable, Sendable { case never = "Does not repeat", daily = "Days", weekly = "Weeks", monthly = "Months" }
struct AppointmentDraft: Identifiable {
    var id = UUID()
    var title = ""
    var start = Date.now
    var end = Date.now.addingTimeInterval(3600)
    var memberID: UUID?
    var kind = AppointmentKind.appointment
    var notes = ""
    var reminderMinutes: Int? = nil
    var frequency = AppointmentRepeat.never
    var interval = 1
    var count = 4
    var recordID: UUID?
    var expectedModified: Date?
}
struct AppointmentSlot: Equatable, Sendable { let start: Date; let end: Date }
enum AppointmentRules {
    static let reminderChoices = [0, 15, 60, 1440]
    static func slots(_ draft: AppointmentDraft, calendar: Calendar = .current) throws -> [AppointmentSlot] {
        _ = try HouseholdRules.requiredName(draft.title)
        guard draft.end > draft.start, draft.end.timeIntervalSince(draft.start) <= 7 * 86400,
              draft.start.timeIntervalSince1970.isFinite, draft.end.timeIntervalSince1970.isFinite,
              (1...30).contains(draft.interval), (1...52).contains(draft.count),
              draft.reminderMinutes == nil || reminderChoices.contains(draft.reminderMinutes ?? -1) else { throw AppointmentError.invalid }
        let component: Calendar.Component = draft.frequency == .monthly ? .month : draft.frequency == .weekly ? .weekOfYear : .day
        let count = draft.frequency == .never || draft.recordID != nil ? 1 : draft.count
        return try (0..<count).map { index in
            guard let start = calendar.date(byAdding: component, value: index * draft.interval, to: draft.start),
                  let end = calendar.date(byAdding: component, value: index * draft.interval, to: draft.end), end > start else { throw AppointmentError.invalid }
            return AppointmentSlot(start: start, end: end)
        }
    }
    static func overlaps(_ a: AppointmentSlot, _ b: AppointmentSlot) -> Bool { a.start < b.end && b.start < a.end }
}
enum AppointmentError: LocalizedError {
    case invalid, conflict, stale
    var errorDescription: String? {
        switch self {
        case .invalid: "Check the title, dates, reminder, and repeat settings. Appointments can last up to seven days and repeat up to 52 times."
        case .conflict: "These times overlap another appointment. Review the warning and choose Save anyway to continue."
        case .stale: "This appointment or household changed. Close this form and open it again before saving."
        }
    }
}
