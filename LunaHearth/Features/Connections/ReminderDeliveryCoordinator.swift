import Foundation
import Observation

@MainActor @Observable final class ReminderDeliveryCoordinator {
    private let service: any ReminderDeliveryService
    private(set) var working = false
    private(set) var error: String?
    private var rerun = false
    private var retryRequested = false
    init(service: any ReminderDeliveryService = CalendarIntegrationService()) { self.service = service }

    func run(repository: LocalHouseholdRepository, connections: AppleConnections, force: Bool = false) async {
        retryRequested = retryRequested || force
        if working { rerun = true; return }
        working = true
        defer { working = false }
        repeat {
            rerun = false
            let forcePass = retryRequested
            retryRequested = false
            guard connections.remindersEnabled else { return }
            error = nil
            let jobs = repository.pendingReminderJobs(force: forcePass)
            for job in jobs {
                guard connections.remindersEnabled, repository.reminderDeliverySettings?.enabled == true else { return }
                guard repository.reminderDeliveryLinks.contains(where: { $0.taskID == job.taskID }),
                      repository.tasks.contains(where: { $0.id == job.taskID && $0.modifiedAt == job.revision }) else {
                    rerun = true; continue
                }
                do {
                    let id = try await service.deliver(job)
                    try repository.recordReminderDelivery(job, externalID: id, error: nil)
                } catch {
                    // Never store arbitrary provider errors which may include household content.
                    let message = (error as? ApplePlanningError)?.errorDescription ??
                        (error as? ReminderDeliveryError)?.errorDescription ?? "Saved locally. Apple Reminders sync couldn't finish. Try again."
                    self.error = message
                    do { try repository.recordReminderDelivery(job, externalID: nil, error: message) }
                    catch { self.error = "Your task is saved, but its sync status couldn't be saved. Reopen the app to retry." }
                }
            }
        } while rerun
    }
}
