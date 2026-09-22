import Foundation
import SwiftData

/// Device-only, durable export outbox. Never included in household backups or CloudKit records.
@Model final class CalendarDeliveryLink {
    @Attribute(.unique) var eventID: UUID
    var householdID: UUID
    var token: UUID
    var calendarID: String
    var calendarName: String
    var externalID: String?
    var title: String
    var lookupStart: Date
    var lookupEnd: Date
    var enabled: Bool
    var deleteRequested: Bool
    var attempted: Bool
    var attemptedAt: Date?
    var sentRevision: Date?
    var error: String?
    init(event: FamilyEvent, calendarID: String, calendarName: String) {
        eventID = event.id; householdID = event.householdID; token = UUID()
        self.calendarID = calendarID; self.calendarName = calendarName
        title = event.title; lookupStart = event.startAt; lookupEnd = event.endAt
        enabled = true; deleteRequested = false; attempted = false
    }
}
