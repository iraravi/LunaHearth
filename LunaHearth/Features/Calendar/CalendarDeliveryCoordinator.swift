import Foundation
import Observation

@MainActor @Observable final class CalendarDeliveryCoordinator {
    private let service: any CalendarDeliveryService
    private(set) var calendars: [ApplePlanningSource] = []
    private(set) var loading = false
    private(set) var working = false
    private(set) var message: String?
    private(set) var syncMessage: String?
    private var rerun = false
    init(service: any CalendarDeliveryService = SystemCalendarDelivery()) { self.service = service }
    func connect() async -> Bool {
        guard !loading else { return false }
        loading = true; defer { loading = false }
        do {
            calendars = try await service.requestCalendars().filter(\.writable)
            message = calendars.isEmpty ? "No writable calendars are available. Create a calendar in Apple Calendar, then try again." : nil
            return !calendars.isEmpty
        } catch {
            message = (error as? ApplePlanningError)?.errorDescription ?? "Apple Calendar is unavailable. Your appointment can still be saved in LunaHearth."
            return false
        }
    }
    func run(_ repository: LocalHouseholdRepository, force: Bool = false) async {
        if working { rerun = true; return }
        working = true; defer { working = false }
        repeat {
            rerun = false
            let jobs = repository.pendingCalendarJobs(force: force)
            if !jobs.isEmpty { syncMessage = nil }
            for job in jobs {
                do {
                    guard try repository.beginCalendarDelivery(job) else { continue }
                    let id = try await service.deliver(job)
                    guard job.deleting || id?.isEmpty == false else { throw CalendarDeliveryError.uncertain }
                    try repository.finishCalendarDelivery(job, externalID: id, error: nil)
                } catch {
                    let text = (error as? ApplePlanningError)?.errorDescription ?? (error as? CalendarDeliveryError)?.errorDescription ?? "Appointment saved. Apple Calendar could not confirm the update. Open Calendar settings to retry."
                    syncMessage = text
                    try? repository.finishCalendarDelivery(job, externalID: nil, error: text, definitelyNotWritten: error is ApplePlanningError)
                }
            }
        } while rerun
    }
}
