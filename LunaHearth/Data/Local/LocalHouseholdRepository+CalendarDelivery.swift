import Foundation

extension LocalHouseholdRepository {
    /// Called inside the appointment's transaction so a saved appointment never loses its export intent.
    func configureCalendarDelivery(_ event: FamilyEvent, calendarID: String?, calendarName: String?) throws {
        let link = calendarDeliveryLinks.first { $0.eventID == event.id }
        if let calendarID, !calendarID.isEmpty {
            if let link {
                guard link.calendarID == calendarID else { throw CalendarDeliveryError.destinationLocked }
                if !link.enabled { link.token = UUID(); link.sentRevision = nil }
                link.enabled = true; link.deleteRequested = false; link.title = event.title
            } else { context.insert(CalendarDeliveryLink(event: event, calendarID: calendarID, calendarName: calendarName ?? "Apple Calendar")) }
        } else if let link {
            link.enabled = false; link.token = UUID(); link.error = nil
        }
    }
    func pendingCalendarJobs(force: Bool = false, now: Date = .now) -> [CalendarDeliveryJob] {
        calendarDeliveryLinks.compactMap { link in
            guard link.enabled || link.deleteRequested else { return nil }
            let event = events.first { $0.id == link.eventID }
            guard link.deleteRequested || event != nil else { return nil } // Remote deletions require local review.
            guard link.deleteRequested || link.sentRevision != event?.modifiedAt else { return nil }
            if !force, let attemptedAt = link.attemptedAt, now.timeIntervalSince(attemptedAt) < 60 { return nil }
            return CalendarDeliveryJob(eventID: link.eventID, householdID: link.householdID, token: link.token,
                calendarID: link.calendarID, externalID: link.externalID, title: event?.title ?? link.title,
                start: event?.startAt ?? link.lookupStart, end: event?.endAt ?? link.lookupEnd, notes: event?.notes,
                revision: event?.modifiedAt, lookupStart: link.lookupStart, lookupEnd: link.lookupEnd,
                attempted: link.attempted, deleting: link.deleteRequested)
        }
    }
    func beginCalendarDelivery(_ job: CalendarDeliveryJob) throws -> Bool {
        guard household?.id == job.householdID,
              let link = calendarDeliveryLinks.first(where: { $0.eventID == job.eventID && $0.token == job.token }),
              link.enabled || link.deleteRequested else { return false }
        if !job.deleting { guard events.contains(where: { $0.id == job.eventID && $0.modifiedAt == job.revision }) else { return false } }
        try commit(notifyDelivery: false, allowReadOnly: true) { link.attempted = true; link.attemptedAt = .now }
        return true
    }
    func finishCalendarDelivery(_ job: CalendarDeliveryJob, externalID: String?, error: String?, definitelyNotWritten: Bool = false) throws {
        guard let link = calendarDeliveryLinks.first(where: { $0.eventID == job.eventID && $0.calendarID == job.calendarID }) else { return }
        try commit(notifyDelivery: false, allowReadOnly: true) {
            if error == nil {
                if job.deleting {
                    if link.token == job.token { context.delete(link) }
                    else { link.externalID = nil; link.sentRevision = nil; link.attempted = true; link.error = "The Apple copy was removed while this link changed. Review Apple Calendar before reconnecting." }
                    return
                }
                link.externalID = externalID; link.lookupStart = job.start; link.lookupEnd = job.end; link.title = job.title
                if link.token == job.token { link.sentRevision = job.revision; link.error = nil; link.attemptedAt = nil }
            } else if link.token == job.token {
                link.error = error
                if definitelyNotWritten && !job.attempted { link.attempted = false }
            }
        }
    }
    func removeAppleCopy(_ eventID: UUID) throws {
        guard let link = calendarDeliveryLinks.first(where: { $0.eventID == eventID }) else { return }
        try commit(notifyDelivery: false, allowReadOnly: true) {
            link.deleteRequested = true; link.enabled = false; link.token = UUID(); link.attemptedAt = nil; link.error = nil
        }
    }
    func forgetCalendarLink(_ eventID: UUID) throws {
        guard let link = calendarDeliveryLinks.first(where: { $0.eventID == eventID }) else { return }
        try commit(notifyDelivery: false, allowReadOnly: true) { context.delete(link) }
    }
    func pauseCalendarDelivery(_ eventID: UUID) throws {
        guard let link = calendarDeliveryLinks.first(where: { $0.eventID == eventID }) else { return }
        try commit(notifyDelivery: false, allowReadOnly: true) { link.enabled = false; link.deleteRequested = false; link.token = UUID(); link.error = nil }
    }
}
