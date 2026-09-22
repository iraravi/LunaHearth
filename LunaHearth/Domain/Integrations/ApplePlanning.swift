import Foundation

enum PlanningAccess: String, Sendable { case calendar, reminders }
enum CalendarPrivacy: String, Codable, CaseIterable, Sendable { case hidden, busyOnly, details }

struct ApplePlanningSource: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let account: String
    let writable: Bool
}

struct AppleCalendarEvent: Identifiable, Sendable, Equatable {
    let id: String
    let calendarID: String
    let title: String
    let start: Date
    let end: Date
    let allDay: Bool

    func visible(as privacy: CalendarPrivacy) -> Self? {
        guard privacy != .hidden else { return nil }
        return Self(id: id, calendarID: calendarID, title: privacy == .busyOnly ? "Busy" : title,
                    start: start, end: end, allDay: allDay)
    }
}

struct AppleReminder: Identifiable, Sendable, Equatable {
    let id: String
    let listID: String
    let title: String
    let due: Date?
    let completed: Bool
    var notes: String? = nil
}

struct CalendarExportDraft: Sendable {
    let title: String
    let start: Date
    let end: Date
    let notes: String?
}

struct ReminderExportDraft: Sendable {
    let id: UUID
    let title: String
    let due: Date?
    var purpose: ReminderPurpose = .reminders
    var appleOnly = false
    var notes: String? = nil
    func dueComponents(calendar: Calendar = .current) -> DateComponents? {
        guard let due else { return nil }
        // Household task entry asks for a day, so exporting must not invent a due time.
        var parts = calendar.dateComponents([.year, .month, .day], from: due)
        parts.calendar = calendar
        return parts
    }
    var link: URL? { URL(string: "lunahearth://\(appleOnly ? purpose.rawValue : "task")/\(id.uuidString)") }
}

protocol ApplePlanningService: Sendable {
    func createStandardReminderList(usingListID: String, title: String) async throws -> ApplePlanningSource
    func requestAccess(_ access: PlanningAccess) async throws
    func sources(_ access: PlanningAccess) async throws -> [ApplePlanningSource]
    func events(in interval: DateInterval, calendarIDs: Set<String>) async throws -> [AppleCalendarEvent]
    func reminders(listIDs: Set<String>, includeCompleted: Bool) async throws -> [AppleReminder]
    func setCompleted(_ reminder: AppleReminder, completed: Bool) async throws
    func createReminder(_ draft: ReminderExportDraft, listID: String) async throws
}

enum ApplePlanningError: LocalizedError {
    case permission, unavailable, missingSource, alreadyExported
    var errorDescription: String? {
        switch self {
        case .permission: "Access is off. Allow access in iPhone Settings, or continue using your local household."
        case .unavailable: "Apple services are unavailable here. Your local household remains available."
        case .missingSource: "This calendar or list is no longer available or cannot be changed. Choose another one."
        case .alreadyExported: "This task already has a copy in that reminder list. Open Reminders to edit it."
        }
    }
}


enum HouseholdLink {
    static func taskID(_ url: URL) -> UUID? {
        guard url.scheme == "lunahearth", url.host == "task", url.pathComponents.count == 2 else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }
}

// Providers that do not support list creation must fail explicitly.
extension ApplePlanningService {
    func createStandardReminderList(usingListID: String, title: String) async throws -> ApplePlanningSource {
        throw ApplePlanningError.unavailable
    }
}

enum ReminderPurpose: String, CaseIterable, Sendable {
    case reminders, shopping
    var title: String { self == .shopping ? "Shopping" : "Reminders" }
    var standardTitle: String { "LunaHearth " + title }
    var symbol: String { self == .shopping ? "basket.fill" : "checklist" }
}

enum ReminderScope: String, CaseIterable {
    case all = "All", today = "Today", upcoming = "Upcoming"
    func includes(_ reminder: AppleReminder, now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard self != .all else { return true }
        guard let due = reminder.due, let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else { return false }
        return self == .today ? due < tomorrow : due >= tomorrow
    }
}
