import Foundation
import SwiftData
import Testing
@testable import LunaHearth

private actor DeliveryFake: ReminderDeliveryService, ApplePlanningService {
    var reject = false
    var writes: [ReminderDeliveryJob] = []
    func setRejected(_ value: Bool) { reject = value }
    func deliver(_ job: ReminderDeliveryJob) throws -> String {
        if reject { throw ApplePlanningError.permission }
        writes.append(job)
        return job.externalID ?? job.taskID.uuidString
    }
    func requestAccess(_ access: PlanningAccess) {}
    func sources(_ access: PlanningAccess) -> [ApplePlanningSource] { [] }
    func events(in interval: DateInterval, calendarIDs: Set<String>) -> [AppleCalendarEvent] { [] }
    func reminders(listIDs: Set<String>, includeCompleted: Bool) -> [AppleReminder] { [] }
    func setCompleted(_ reminder: AppleReminder, completed: Bool) {}
    func createReminder(_ draft: ReminderExportDraft, listID: String) {}
}

@MainActor struct ReminderDeliveryTests {
    private func repository() throws -> LocalHouseholdRepository {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "", members: [])
        return repo
    }
    private func addTask(_ repo: LocalHouseholdRepository, title: String = "Change filter") throws {
        var draft = EntryDraft(kind: .task)
        draft.title = title; draft.hasDate = false
        try repo.add(draft)
    }
    private func connections(_ fake: DeliveryFake) async throws -> AppleConnections {
        let defaults = try #require(UserDefaults(suiteName: "ReminderDeliveryTests.\(UUID().uuidString)"))
        let connections = AppleConnections(service: fake, defaults: defaults)
        await connections.connect(.reminders)
        return connections
    }

    @Test func onlyNewTasksAfterExplicitOptInAreEnrolled() throws {
        let repo = try repository()
        try addTask(repo, title: "Old task")
        #expect(repo.reminderDeliveryLinks.isEmpty)
        try repo.configureReminderDelivery(enabled: true, listID: "chosen")
        #expect(repo.pendingReminderJobs().isEmpty)
        try addTask(repo)
        #expect(repo.tasks.count == 2)
        #expect(repo.pendingReminderJobs().count == 1)
        #expect(repo.pendingReminderJobs().first?.listID == "chosen")
    }

    @Test func failuresKeepLocalTaskAndRetryWithoutDuplicateWrites() async throws {
        let repo = try repository(), fake = DeliveryFake()
        let connections = try await connections(fake)
        let runner = ReminderDeliveryCoordinator(service: fake)
        try repo.configureReminderDelivery(enabled: true, listID: "chosen")
        try addTask(repo)
        await fake.setRejected(true)
        await runner.run(repository: repo, connections: connections)
        #expect(repo.tasks.count == 1)
        #expect(repo.pendingReminderJobs().isEmpty) // short backoff, not lost work
        #expect(repo.pendingReminderJobs(force: true).count == 1)
        #expect(repo.reminderDeliveryLinks.first?.error != nil)
        await fake.setRejected(false)
        await runner.run(repository: repo, connections: connections, force: true)
        await runner.run(repository: repo, connections: connections, force: true)
        #expect(await fake.writes.count == 1)
        #expect(repo.pendingReminderJobs(force: true).isEmpty)
        #expect(repo.reminderDeliveryLinks.first?.error == nil)
    }

    @Test func editAndCompletionUpdateSameReminderAndPreserveDestination() async throws {
        let repo = try repository(), fake = DeliveryFake()
        let connections = try await connections(fake)
        let runner = ReminderDeliveryCoordinator(service: fake)
        try repo.configureReminderDelivery(enabled: true, listID: "original")
        try addTask(repo)
        await runner.run(repository: repo, connections: connections)
        let task = try #require(repo.tasks.first)
        let id = try #require(repo.reminderDeliveryLinks.first?.externalID)
        var edit = EntryDraft.editing(task)
        edit.title = "Replace filter"; edit.hasDate = true; edit.date = .now
        try repo.add(edit)
        try repo.toggle(task)
        try repo.configureReminderDelivery(enabled: true, listID: "new-destination")
        await runner.run(repository: repo, connections: connections)
        let write = try #require(await fake.writes.last)
        #expect(write.externalID == id && write.listID == "original")
        #expect(write.completed && write.title == "Replace filter" && write.due != nil)
    }

    @Test func acknowledgementDoesNotLoseAnEditMadeDuringDelivery() throws {
        let repo = try repository()
        try repo.configureReminderDelivery(enabled: true, listID: "chosen")
        try addTask(repo)
        let old = try #require(repo.pendingReminderJobs().first)
        let task = try #require(repo.tasks.first)
        try repo.toggle(task)
        try repo.recordReminderDelivery(old, externalID: "apple-id", error: nil)
        let next = try #require(repo.pendingReminderJobs().first)
        #expect(next.completed && next.externalID == "apple-id")
        #expect(next.revision != old.revision)
    }

    @Test func disablingAndDisconnectingPreventWrites() async throws {
        let repo = try repository(), fake = DeliveryFake()
        let connections = try await connections(fake)
        let runner = ReminderDeliveryCoordinator(service: fake)
        try repo.configureReminderDelivery(enabled: true, listID: "chosen")
        try addTask(repo)
        try repo.configureReminderDelivery(enabled: false, listID: "chosen")
        await runner.run(repository: repo, connections: connections, force: true)
        #expect(await fake.writes.isEmpty)
        try addTask(repo, title: "Local only")
        #expect(repo.reminderDeliveryLinks.count == 1)
        try repo.configureReminderDelivery(enabled: true, listID: "chosen")
        connections.disconnect(.reminders)
        await runner.run(repository: repo, connections: connections, force: true)
        #expect(await fake.writes.isEmpty)
    }

    @Test func deletingTaskOrStoppingSyncRetiresOnlyLocalLink() throws {
        let repo = try repository()
        try repo.configureReminderDelivery(enabled: true, listID: "chosen")
        try addTask(repo)
        let id = try #require(repo.tasks.first?.id)
        try repo.stopReminderDelivery(taskID: id)
        #expect(repo.tasks.count == 1 && repo.reminderDeliveryLinks.isEmpty)
        try addTask(repo, title: "Second")
        let linkedID = try #require(repo.reminderDeliveryLinks.first?.taskID)
        let old = try #require(repo.pendingReminderJobs().first)
        try repo.deletePlanningEntry(id: linkedID, kind: .task)
        try repo.recordReminderDelivery(old, externalID: "late-id", error: nil)
        #expect(repo.tasks.count == 1 && repo.reminderDeliveryLinks.isEmpty)
    }

    @Test func backupRestoreDoesNotEnableAutomaticExternalWrites() throws {
        let repo = try repository()
        try repo.configureReminderDelivery(enabled: true, listID: "private-list-id")
        try addTask(repo)
        let backup = try repo.makeBackup()
        #expect(backup.records.count == 2)
        let restored = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try restored.restoreBackup(backup)
        #expect(restored.tasks.count == 1)
        #expect(restored.reminderDeliverySettings == nil && restored.reminderDeliveryLinks.isEmpty)
    }

    @Test func additiveSchemaUpgradePreservesExistingHouseholdAndStartsDisconnected() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("upgrade.store")
        let legacyTypes: [any PersistentModel.Type] = [Household.self, HouseholdMember.self, FamilyEvent.self, HouseholdTask.self,
            GroceryItem.self, MealPlanEntry.self, HomeFloor.self, Room.self, HomeAsset.self,
            Warranty.self, MaintenancePlan.self, MaintenanceHistory.self, DocumentRecord.self]
        func writeLegacy() throws {
            let schema = Schema(legacyTypes)
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
            let context = ModelContext(container)
            let home = Household(name: "Existing home")
            context.insert(home)
            context.insert(HouseholdTask(householdID: home.id, title: "Existing task"))
            try context.save()
        }
        try writeLegacy()
        let upgradedSchema = LocalStoreConfiguration.schema
        let upgraded = try ModelContainer(for: upgradedSchema, configurations: [ModelConfiguration(schema: upgradedSchema, url: url, cloudKitDatabase: .none)])
        let repo = LocalHouseholdRepository(container: upgraded)
        try repo.reload()
        #expect(repo.household?.name == "Existing home" && repo.tasks.first?.title == "Existing task")
        #expect(repo.reminderDeliverySettings == nil && repo.reminderDeliveryLinks.isEmpty)
    }

    @Test func pendingTaskAndOptInSurviveStoreReopen() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let schema = LocalStoreConfiguration.schema
        let config = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("local.store"), cloudKitDatabase: .none)
        func write() throws {
            let repo = LocalHouseholdRepository(container: try ModelContainer(for: schema, configurations: [config]))
            try repo.createHousehold(name: "Saved home", owner: "", members: [])
            try repo.configureReminderDelivery(enabled: true, listID: "chosen")
            try addTask(repo)
        }
        try write()
        let reopened = LocalHouseholdRepository(container: try ModelContainer(for: schema, configurations: [config]))
        try reopened.reload()
        #expect(reopened.reminderDeliverySettings?.enabled == true)
        #expect(reopened.pendingReminderJobs().first?.title == "Change filter")
    }
}
