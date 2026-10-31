import Foundation
import UserNotifications

actor MealPrepReminder: MealPrepReminderService {
    private func key(_ home: UUID, _ id: UUID) -> String { "meal.prep.\(home).\(id)" }
    func schedule(id: UUID, householdID: UUID, due: Date) async throws {
        let center = UNUserNotificationCenter.current()
        guard try await center.requestAuthorization(options: [.alert, .sound]) else { throw PrepError.denied }
        try await post(identifier: key(householdID, id), due: due)
    }
    private func post(identifier: String, due: Date) async throws {
        guard due > .now else { return }
        let content = UNMutableNotificationContent(); content.title = "Time for meal preparation"; content.body = "Open Nam Illam to see your preparation tasks."; content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, due.timeIntervalSinceNow), repeats: false)
        try await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }
    func reconcile(householdID: UUID, tasks: [MealPrepReminderInput]) async {
        let center = UNUserNotificationCenter.current()
        let prefix = "meal.prep.\(householdID)."
        let pending = await center.pendingNotificationRequests()
        let delivered = await center.deliveredNotifications()
        for identifier in Set(pending.map(\.identifier) + delivered.map { $0.request.identifier }) where identifier.hasPrefix(prefix) {
            guard let task = tasks.first(where: { key(householdID, $0.id) == identifier }), !task.completed, let due = task.due else {
                center.removePendingNotificationRequests(withIdentifiers: [identifier]); center.removeDeliveredNotifications(withIdentifiers: [identifier]); continue
            }
            if let request = pending.first(where: { $0.identifier == identifier }),
               let scheduled = (request.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate(), abs(scheduled.timeIntervalSince(due)) > 2 {
                center.removePendingNotificationRequests(withIdentifiers: [identifier]); try? await post(identifier: identifier, due: due)
            }
        }
    }
    private enum PrepError: LocalizedError { case denied; var errorDescription: String? { "Preparation task saved. Notifications are off; enable them in Settings to receive an alert on this device." } }
}
