import EventKit
import Foundation

actor SystemCalendarDelivery: CalendarDeliveryService {
    private var eventStore: EKEventStore?
    private func store() -> EKEventStore {
        if let eventStore { return eventStore }
        let value = EKEventStore(); eventStore = value; return value
    }
    private func check() throws {
        guard !ProcessInfo.processInfo.arguments.contains("--ui-testing") else { throw ApplePlanningError.unavailable }
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { throw ApplePlanningError.permission }
    }
    func requestCalendars() async throws -> [ApplePlanningSource] {
        guard !ProcessInfo.processInfo.arguments.contains("--ui-testing") else { throw ApplePlanningError.unavailable }
        if EKEventStore.authorizationStatus(for: .event) != .fullAccess {
            guard try await store().requestFullAccessToEvents() else { throw ApplePlanningError.permission }
        }
        try check()
        return store().calendars(for: .event).filter(\.allowsContentModifications).map {
            ApplePlanningSource(id: $0.calendarIdentifier, title: $0.title, account: $0.source.title, writable: true)
        }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
    func deliver(_ job: CalendarDeliveryJob) throws -> String? {
        if job.deleting && !job.attempted && job.externalID == nil { return nil }
        try check()
        let store = store()
        guard let calendar = store.calendars(for: .event).first(where: { $0.calendarIdentifier == job.calendarID && $0.allowsContentModifications }) else { throw ApplePlanningError.missingSource }
        var event = job.externalID.flatMap { store.calendarItem(withIdentifier: $0) as? EKEvent }
        if event == nil {
            // Search only the selected calendar, in bounded original and current date windows.
            var matches: [String: EKEvent] = [:]
            for (start, end) in [(job.lookupStart, job.lookupEnd), (job.start, job.end)] {
                let predicate = store.predicateForEvents(withStart: start.addingTimeInterval(-86400), end: end.addingTimeInterval(86400), calendars: [calendar])
                for candidate in store.events(matching: predicate) where candidate.url?.absoluteString == job.marker { matches[candidate.calendarItemIdentifier] = candidate }
            }
            guard matches.count <= 1 else { throw CalendarDeliveryError.ambiguous }
            event = matches.values.first
        }
        let candidates = event.map { [CalendarDeliveryCandidate(id: $0.calendarItemIdentifier, calendarID: $0.calendar.calendarIdentifier, marker: $0.url?.absoluteString, recurring: $0.hasRecurrenceRules, writable: $0.calendar.allowsContentModifications)] } ?? []
        switch try CalendarDeliveryRules.resolve(job, candidates: candidates) {
        case .delete:
            guard let event else { throw CalendarDeliveryError.missing }
            try store.remove(event, span: .thisEvent, commit: true); return nil
        case .absent: return nil
        case .create:
            let created = EKEvent(eventStore: store); created.calendar = calendar; created.url = URL(string: job.marker); event = created
        case .update: break
        }
        guard let event else { throw CalendarDeliveryError.missing }
        event.title = job.title; event.startDate = job.start; event.endDate = job.end; event.isAllDay = false; event.notes = job.notes
        // Keep Apple-side alarms/location intact; this link owns title, dates, and notes only.
        try store.save(event, span: .thisEvent, commit: true)
        return event.calendarItemIdentifier
    }
}
