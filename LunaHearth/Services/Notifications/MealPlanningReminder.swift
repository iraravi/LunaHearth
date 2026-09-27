import Foundation
import UserNotifications

actor MealPlanningReminder: MealPlanningReminderService {
    static let identifier = "meal.planning.daily"
    func enabled() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return false }
        return await center.pendingNotificationRequests().contains { $0.identifier == Self.identifier }
    }
    func setEnabled(_ enabled: Bool) async throws {
        if enabled { try FeatureAccess.require(.mealReminder) }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
        center.removeDeliveredNotifications(withIdentifiers: [Self.identifier])
        guard enabled else { return }
        guard try await center.requestAuthorization(options: [.alert, .sound]) else { throw ReminderError.denied }
        let content = UNMutableNotificationContent()
        content.title = "What's for tomorrow?"
        content.body = "Open Meal ideas to plan with your pantry."
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: MealSuggestionRules.reminderTime, repeats: true)
        try await center.add(UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger))
    }
    private enum ReminderError: LocalizedError {
        case denied
        var errorDescription: String? { "Notifications are off. Allow LunaHearth notifications in Settings, then enable the reminder here." }
    }
}
