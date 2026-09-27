import EventKit
import Foundation

actor CalendarIntegrationService: ApplePlanningService, ReminderDeliveryService {
    private var eventStore: EKEventStore?
    private var pendingExports: Set<UUID> = []
    private func store() -> EKEventStore {
        if let eventStore { return eventStore }
        let value = EKEventStore()
        eventStore = value
        return value
    }
    private func check(_ access: PlanningAccess) throws {
        guard !ProcessInfo.processInfo.arguments.contains("--ui-testing") else { throw ApplePlanningError.unavailable }
        guard EKEventStore.authorizationStatus(for: access == .calendar ? .event : .reminder) == .fullAccess else {
            throw ApplePlanningError.permission
        }
    }
    func requestAccess(_ access: PlanningAccess) async throws {
        if access == .reminders { try FeatureAccess.require(.reminders) }
        guard !ProcessInfo.processInfo.arguments.contains("--ui-testing") else { throw ApplePlanningError.unavailable }
        let status = EKEventStore.authorizationStatus(for: access == .calendar ? .event : .reminder)
        if status == .fullAccess { return }
        guard status == .notDetermined || (access == .calendar && status == .writeOnly) else { throw ApplePlanningError.permission }
        let allowed: Bool
        if access == .calendar { allowed = try await store().requestFullAccessToEvents() }
        else { allowed = try await store().requestFullAccessToReminders() }
        guard allowed else { throw ApplePlanningError.permission }
    }
    func sources(_ access: PlanningAccess) throws -> [ApplePlanningSource] {
        try check(access)
        return store().calendars(for: access == .calendar ? .event : .reminder).map {
            ApplePlanningSource(id: $0.calendarIdentifier, title: $0.title,
                                account: $0.source.title, writable: $0.allowsContentModifications)
        }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
    func createStandardReminderList(usingListID: String, title: String) throws -> ApplePlanningSource {
        try FeatureAccess.require(.reminders)
        try check(.reminders)
        let store = store()
        guard let reference = store.calendars(for: .reminder).first(where: { $0.calendarIdentifier == usingListID && $0.allowsContentModifications }) else { throw ApplePlanningError.missingSource }
        let existing = store.calendars(for: .reminder).first {
            $0.source.sourceIdentifier == reference.source.sourceIdentifier && $0.title == title && $0.allowsContentModifications
        }
        let list = existing ?? EKCalendar(for: .reminder, eventStore: store)
        if existing == nil {
            list.title = title
            list.source = reference.source
            try store.saveCalendar(list, commit: true)
        }
        return ApplePlanningSource(id: list.calendarIdentifier, title: list.title, account: list.source.title, writable: list.allowsContentModifications)
    }
    func events(in interval: DateInterval, calendarIDs: Set<String>) throws -> [AppleCalendarEvent] {
        try check(.calendar)
        guard !calendarIDs.isEmpty else { return [] }
        let store = store()
        let calendars = store.calendars(for: .event).filter { calendarIDs.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else { return [] } // nil/empty predicates must never fall back to all calendars.
        return store.events(matching: store.predicateForEvents(withStart: interval.start, end: interval.end, calendars: calendars)).map {
            AppleCalendarEvent(id: "\($0.calendarItemIdentifier)-\($0.startDate.timeIntervalSince1970)", calendarID: $0.calendar.calendarIdentifier,
                               title: $0.title ?? "Untitled event", start: $0.startDate, end: $0.endDate, allDay: $0.isAllDay)
        }.sorted { $0.start < $1.start }
    }
    func reminders(listIDs: Set<String>, includeCompleted: Bool) async throws -> [AppleReminder] {
        try check(.reminders)
        guard !listIDs.isEmpty else { return [] }
        let store = store()
        let calendars = store.calendars(for: .reminder).filter { listIDs.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else { return [] }
        let predicate = includeCompleted ? store.predicateForReminders(in: calendars) :
            store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: calendars)
        // EventKit exposes this fetch through a callback. Only Sendable values leave it.
        let values: [AppleReminder]? = await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders?.map {
                    AppleReminder(id: $0.calendarItemIdentifier, listID: $0.calendar.calendarIdentifier,
                                  title: $0.title ?? "Untitled reminder", due: $0.dueDateComponents.flatMap {
                                      ($0.calendar ?? Calendar.current).date(from: $0)
                                  }, completed: $0.isCompleted, notes: $0.notes)
                })
            }
        }
        try check(.reminders)
        guard let values else { throw ReminderDeliveryError.readFailed }
        return values.sorted { ($0.due ?? .distantFuture) < ($1.due ?? .distantFuture) }
    }
    func setCompleted(_ reminder: AppleReminder, completed: Bool) throws {
        try check(.reminders)
        let store = store()
        guard let item = store.calendarItem(withIdentifier: reminder.id) as? EKReminder,
              item.calendar.calendarIdentifier == reminder.listID, item.calendar.allowsContentModifications else {
            throw ApplePlanningError.missingSource
        }
        item.isCompleted = completed
        try store.save(item, commit: true)
    }
    func createReminder(_ draft: ReminderExportDraft, listID: String) async throws {
        try FeatureAccess.require(.reminders)
        try check(.reminders)
        guard !pendingExports.contains(draft.id) else { throw ApplePlanningError.alreadyExported }
        pendingExports.insert(draft.id)
        defer { pendingExports.remove(draft.id) }
        let store = store()
        guard let calendar = store.calendars(for: .reminder).first(where: { $0.calendarIdentifier == listID }),
              calendar.allowsContentModifications else { throw ApplePlanningError.missingSource }
        let predicate = store.predicateForReminders(in: [calendar])
        let duplicate: Bool? = await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { values in
                continuation.resume(returning: values?.contains { $0.url == draft.link })
            }
        }
        try check(.reminders)
        guard let duplicate else { throw ReminderDeliveryError.readFailed }
        if duplicate && draft.appleOnly { return } // Retry after an uncertain acknowledgement is safe.
        guard !duplicate else { throw ApplePlanningError.alreadyExported }
        let item = EKReminder(eventStore: store)
        item.calendar = calendar; item.title = draft.title; item.url = draft.link
        item.dueDateComponents = draft.dueComponents()
        item.notes = draft.notes
        try store.save(item, commit: true)
    }
    func deliver(_ job: ReminderDeliveryJob) async throws -> String {
        try check(.reminders)
        guard !pendingExports.contains(job.taskID) else { throw ReminderDeliveryError.readFailed }
        pendingExports.insert(job.taskID)
        defer { pendingExports.remove(job.taskID) }
        let store = store()
        guard let calendar = store.calendars(for: .reminder).first(where: { $0.calendarIdentifier == job.listID }),
              calendar.allowsContentModifications else { throw ApplePlanningError.missingSource }
        var identifier = job.externalID
        if identifier == nil {
            // Recover a write that reached EventKit before the local acknowledgement was saved.
            // A failed fetch must never be mistaken for an empty list and create a duplicate.
            let predicate = store.predicateForReminders(in: [calendar])
            let marker = job.draft.link
            let matches: [String]? = await withCheckedContinuation { continuation in
                store.fetchReminders(matching: predicate) { values in
                    continuation.resume(returning: values?.filter { $0.url == marker }.map(\.calendarItemIdentifier))
                }
            }
            guard let matches else { throw ReminderDeliveryError.readFailed }
            guard matches.count <= 1 else { throw ReminderDeliveryError.ambiguous }
            identifier = matches.first
        }
        try Task.checkCancellation()
        try check(.reminders)
        guard let destination = store.calendars(for: .reminder).first(where: { $0.calendarIdentifier == job.listID }),
              destination.allowsContentModifications else { throw ApplePlanningError.missingSource }
        let item: EKReminder
        if let identifier {
            guard let existing = store.calendarItem(withIdentifier: identifier) as? EKReminder,
                  existing.calendar.calendarIdentifier == job.listID, existing.url == job.draft.link else {
                // Do not resurrect a reminder the user deleted in Apple Reminders.
                throw ReminderDeliveryError.missingReminder
            }
            item = existing
        } else {
            item = EKReminder(eventStore: store)
            item.calendar = destination; item.url = job.draft.link
        }
        item.title = job.title
        item.dueDateComponents = job.draft.dueComponents()
        item.isCompleted = job.completed
        try store.save(item, commit: true)
        return item.calendarItemIdentifier
    }

}
