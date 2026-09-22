import Foundation

struct CalendarDeliveryJob: Sendable {
    let eventID: UUID
    let householdID: UUID
    let token: UUID
    let calendarID: String
    let externalID: String?
    let title: String
    let start: Date
    let end: Date
    let notes: String?
    let revision: Date?
    let lookupStart: Date
    let lookupEnd: Date
    let attempted: Bool
    let deleting: Bool
    var marker: String { "lunahearth://appointment/\(householdID.uuidString)/\(eventID.uuidString)" }
}
protocol CalendarDeliveryService: Sendable {
    func requestCalendars() async throws -> [ApplePlanningSource]
    func deliver(_ job: CalendarDeliveryJob) async throws -> String?
}
enum CalendarDeliveryError: LocalizedError {
    case missing, ambiguous, uncertain, destinationLocked
    var errorDescription: String? {
        switch self {
        case .missing: "The linked Apple event is missing, moved, or changed into a repeating event. Review it in Apple Calendar; a new copy was not created."
        case .ambiguous: "More than one Apple event has this link. Resolve the duplicates in Apple Calendar before retrying."
        case .uncertain: "The previous export could not be confirmed. Check Apple Calendar before resetting this link; retry will not create another copy."
        case .destinationLocked: "This appointment is already linked to a calendar. Pause syncing to keep its Apple copy; its destination cannot be changed here."
        }
    }
}

struct CalendarDeliveryCandidate: Sendable {
    let id: String
    let calendarID: String
    let marker: String?
    let recurring: Bool
    let writable: Bool
}
enum CalendarDeliveryResolution: Equatable, Sendable { case create, update(String), delete(String), absent }
enum CalendarDeliveryRules {
    static func resolve(_ job: CalendarDeliveryJob, candidates: [CalendarDeliveryCandidate]) throws -> CalendarDeliveryResolution {
        guard candidates.count <= 1 else { throw CalendarDeliveryError.ambiguous }
        if let event = candidates.first {
            guard event.calendarID == job.calendarID, event.marker == job.marker, !event.recurring, event.writable else { throw CalendarDeliveryError.missing }
            return job.deleting ? .delete(event.id) : .update(event.id)
        }
        if job.deleting && !job.attempted && job.externalID == nil { return .absent }
        guard job.externalID == nil else { throw CalendarDeliveryError.missing }
        guard !job.attempted else { throw CalendarDeliveryError.uncertain }
        return .create
    }
}
