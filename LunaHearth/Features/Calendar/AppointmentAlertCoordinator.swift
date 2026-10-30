import Foundation
import Observation

@MainActor @Observable final class AppointmentAlertCoordinator {
    private let service: any AppointmentAlertService
    private let defaults: UserDefaults
    private(set) var message: String?
    private var refreshing = false
    private var refreshAgain = false
    init(service: any AppointmentAlertService = SystemAppointmentAlerts(), defaults: UserDefaults = .standard) { self.service = service; self.defaults = defaults }
    func enable() async -> Bool {
        do {
            guard try await service.requestPermission() else { message = "Notifications are off. You can enable them in iOS Settings."; return false }
            message = nil; return true
        } catch { message = "Could not enable notifications. Try again."; return false }
    }
    func refresh(_ repository: LocalHouseholdRepository) async {
        if refreshing { refreshAgain = true; return }
        refreshing = true; defer { refreshing = false }
        repeat {
            refreshAgain = false
            let member = defaults.string(forKey: "calendar.alertMember").flatMap(UUID.init(uuidString:))
            let enabled = defaults.bool(forKey: "calendar.alertsEnabled") && repository.members.contains { $0.id == member }
            let alerts: [AppointmentAlert] = enabled ? repository.events.compactMap { event in
                guard event.assignedMemberID == nil || event.assignedMemberID == member,
                      let minutes = event.reminderMinutes, AppointmentRules.reminderChoices.contains(minutes) else { return nil }
                return AppointmentAlert(id: event.id, householdID: event.householdID, date: event.startAt.addingTimeInterval(-Double(minutes) * 60))
            } : []
            do { try await service.replace(alerts); message = nil }
            catch { message = "Appointments are saved. Some device alerts could not be scheduled; open Calendar to retry." }
            // Edits, opt-out and household changes during the await must replace stale alerts.
        } while refreshAgain
    }
}
