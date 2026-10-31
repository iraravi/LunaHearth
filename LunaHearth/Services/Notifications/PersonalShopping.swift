import Foundation
import Observation
import UserNotifications
import UIKit

/// Device-local preference; membership is a display filter, never authentication.
@MainActor @Observable final class PersonalShopping {
    private let defaults: UserDefaults
    private let notifications: any ShoppingNotificationService
    private(set) var revision = 0
    private(set) var message: String?
    private var processing = false
    init(defaults: UserDefaults = .standard, notifications: any ShoppingNotificationService = SystemShoppingNotifications()) { self.defaults = defaults; self.notifications = notifications }
    private func key(_ home: UUID, _ suffix: String) -> String { "shopping.personal.\(home).\(suffix)" }
    func memberID(_ home: UUID) -> UUID? {
        _ = revision
        return defaults.string(forKey: key(home, "member")).flatMap(UUID.init(uuidString:))
    }
    func alertsEnabled(_ home: UUID) -> Bool { _ = revision; return defaults.bool(forKey: key(home, "alerts")) }
    func items(_ repository: LocalHouseholdRepository) -> [AssignedShoppingItem] {
        guard let home = repository.household?.id, let member = memberID(home), repository.members.contains(where: { $0.id == member }) else { return [] }
        return repository.groceries.filter { !$0.isCompleted && $0.assignedMemberID == member }.map {
            AssignedShoppingItem(id: $0.id, name: $0.name, quantity: $0.quantityText ?? "", store: repository.shoppingStoreName(for: $0), later: $0.neededLater == true, day: $0.plannedDay)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
    func tasks(_ repository: LocalHouseholdRepository) -> [HouseholdTask] {
        guard let home = repository.household?.id, let member = memberID(home), repository.members.contains(where: { $0.id == member }) else { return [] }
        return repository.tasks.filter { !$0.isCompleted && $0.assignedMemberID == member }
            .sorted { ($0.dueAt ?? .distantFuture, $0.title) < ($1.dueAt ?? .distantFuture, $1.title) }
    }
    func taskAlertsEnabled(_ home: UUID) -> Bool { _ = revision; return defaults.bool(forKey: key(home, "taskAlerts")) }
    private func taskNotice(_ home: UUID) -> String { "tasks.personal.\(home).notification" }
    private func baselineTasks(_ repository: LocalHouseholdRepository) {
        guard let home = repository.household?.id else { return }
        defaults.set(tasks(repository).map { $0.id.uuidString }, forKey: key(home, "tasksSeen"))
    }
    func disableTasks(_ repository: LocalHouseholdRepository) {
        guard let home = repository.household?.id else { return }
        defaults.set(false, forKey: key(home, "taskAlerts")); revision += 1
        notifications.clear(identifier: taskNotice(home))
    }
    func enableTasks(_ repository: LocalHouseholdRepository, service: any HouseholdSharingService) async {
        guard let home = repository.household?.id, let member = memberID(home) else { return }
        do {
            guard try await notifications.requestPermission() else { message = "Notifications are off. Enable them in Settings to receive task alerts."; return }
            guard repository.household?.id == home, memberID(home) == member else { return }
            baselineTasks(repository)
            defaults.set(true, forKey: key(home, "taskAlerts")); revision += 1
            await preparePush(repository, service: service)
        } catch { message = "Couldn’t enable task notifications. Try again." }
    }
    private func refreshTasks(_ repository: LocalHouseholdRepository) async {
        guard let home = repository.household?.id else { return }
        let member = memberID(home)
        let current = Set(tasks(repository).map(\.id))
        let previous = Set((defaults.stringArray(forKey: key(home, "tasksSeen")) ?? []).compactMap(UUID.init(uuidString:)))
        guard taskAlertsEnabled(home), member != nil else { baselineTasks(repository); return }
        let added = current.subtracting(previous)
        if current.isEmpty || !previous.subtracting(current).isEmpty { notifications.clear(identifier: taskNotice(home)) }
        guard !added.isEmpty else { baselineTasks(repository); return }
        do {
            try await notifications.post(identifier: taskNotice(home), newCount: added.count)
            guard repository.household?.id == home, memberID(home) == member, taskAlertsEnabled(home) else {
                notifications.clear(identifier: taskNotice(home)); return
            }
            defaults.set(current.map(\.uuidString), forKey: key(home, "tasksSeen"))
        } catch { message = "Your tasks are updated. The notification could not be delivered." }
    }
    func select(_ member: UUID?, repository: LocalHouseholdRepository) {
        guard let home = repository.household?.id else { return }
        defaults.set(member?.uuidString, forKey: key(home, "member"))
        defaults.set(false, forKey: key(home, "alerts"))
        revision += 1
        baseline(repository)
        baselineTasks(repository)
        disableTasks(repository)
        notifications.clear(identifier: key(home, "notification"))
        message = nil
    }
    private func baseline(_ repository: LocalHouseholdRepository) {
        guard let home = repository.household?.id else { return }
        defaults.set(items(repository).map { $0.id.uuidString }, forKey: key(home, "seen"))
    }
    func disable(_ repository: LocalHouseholdRepository) {
        guard let home = repository.household?.id else { return }
        defaults.set(false, forKey: key(home, "alerts")); revision += 1
        notifications.clear(identifier: key(home, "notification"))
    }
    func enable(_ repository: LocalHouseholdRepository, service: any HouseholdSharingService) async {
        guard let home = repository.household?.id, let selected = memberID(home) else { return }
        do {
            let allowed = try await notifications.requestPermission()
            guard allowed else { message = "Notifications are off. You can enable them in Settings. Your items still appear here."; return }
            guard repository.household?.id == home, memberID(home) == selected else { return }
            baseline(repository)
            defaults.set(true, forKey: key(home, "alerts")); revision += 1
            await preparePush(repository, service: service)
        } catch { message = "Couldn’t enable notifications. Try again." }
    }
    func preparePush(_ repository: LocalHouseholdRepository, service: any HouseholdSharingService) async {
        guard let home = repository.household?.id, (alertsEnabled(home) || taskAlertsEnabled(home)), let config = repository.syncConfiguration, config.enabled, !config.recovery,
              let push = service as? any HouseholdPushService else { return }
        do {
            try await push.enableChangeNotifications(in: config.destination)
            UIApplication.shared.registerForRemoteNotifications()
            message = nil
        } catch { message = "Background alerts couldn’t connect to iCloud. Open the app to refresh; we’ll retry automatically." }
    }
    func selectLinkedMember(_ repository: LocalHouseholdRepository) {
        guard let home = repository.household?.id, let linked = repository.linkedCloudMemberID,
              memberID(home) != linked else { return }
        select(linked, repository: repository)
    }

    func refresh(_ repository: LocalHouseholdRepository) async {
        selectLinkedMember(repository)
        guard !processing, repository.syncConfiguration?.recovery != true, let home = repository.household?.id else { return }
        processing = true; defer { processing = false }
        await refreshTasks(repository)
        guard repository.household?.id == home else { return }
        let selectedMember = memberID(home)
        let current = Set(items(repository).map(\.id))
        let previous = Set((defaults.stringArray(forKey: key(home, "seen")) ?? []).compactMap(UUID.init(uuidString:)))
        let added = AssignedShoppingRules.newlyAssigned(previous: previous, current: current)
        guard alertsEnabled(home), memberID(home) != nil else { baseline(repository); return }
        if current.isEmpty || !previous.subtracting(current).isEmpty { notifications.clear(identifier: key(home, "notification")) }
        guard !added.isEmpty else { baseline(repository); return }
        do {
            try await notifications.post(identifier: key(home, "notification"), newCount: added.count)
            guard repository.household?.id == home, memberID(home) == selectedMember, alertsEnabled(home) else {
                notifications.clear(identifier: key(home, "notification")); return
            }
            // Persist this snapshot, so later changes during the await are processed next time.
            defaults.set(current.map(\.uuidString), forKey: key(home, "seen"))
        } catch { message = "Your shopping is updated. The notification could not be delivered." }
    }
}

@MainActor final class SystemShoppingNotifications: ShoppingNotificationService {
    func requestPermission() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }
    func post(identifier: String, newCount: Int) async throws {
        let content = UNMutableNotificationContent()
        let isTask = identifier.hasPrefix("tasks.personal.")
        content.title = isTask ? "Tasks updated" : "Shopping updated"
        content.body = isTask ? "\(newCount) new \(newCount == 1 ? "task" : "tasks") assigned to you. Open Nam Illam to see your tasks." : "\(newCount) new \(newCount == 1 ? "item" : "items") assigned to you. Open Nam Illam to see your list."
        content.sound = .default
        try await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: identifier, content: content, trigger: nil))
    }
    func clear(identifier: String) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
