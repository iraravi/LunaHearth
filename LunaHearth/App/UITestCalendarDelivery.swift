#if DEBUG
import Foundation

/// In-memory provider only; UI tests never ask for or modify real Apple calendars.
actor UITestCalendarDelivery: CalendarDeliveryService {
    private var ids: [UUID: String] = [:]
    func requestCalendars() async throws -> [ApplePlanningSource] {
        [ApplePlanningSource(id: "test-calendar", title: "Family test calendar", account: "Test account", writable: true)]
    }
    func deliver(_ job: CalendarDeliveryJob) async throws -> String? {
        if job.deleting { ids[job.eventID] = nil; return nil }
        let id = ids[job.eventID] ?? UUID().uuidString; ids[job.eventID] = id; return id
    }
}
#endif
