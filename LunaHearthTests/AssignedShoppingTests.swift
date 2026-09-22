import Foundation
import Testing
@testable import LunaHearth

@MainActor struct AssignedShoppingTests {
    private func setup() throws -> (LocalHouseholdRepository, UserDefaults, RecordingShoppingNotifications, PersonalShopping) {
        let repository = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repository.createHousehold(name: "Home", owner: "Ravi", members: [("Kira", .adult)])
        let defaults = try #require(UserDefaults(suiteName: "PersonalShoppingTests.\(UUID())"))
        let notifications = RecordingShoppingNotifications()
        return (repository, defaults, notifications, PersonalShopping(defaults: defaults, notifications: notifications))
    }
    @Test func filtersByMemberAndKeepsOneSharedItem() throws {
        let (repo, _, _, personal) = try setup()
        let kira = try #require(repo.members.first { $0.displayName == "Kira" })
        try repo.add(EntryDraft(kind: .grocery, title: "Milk", memberID: kira.id))
        try repo.add(EntryDraft(kind: .grocery, title: "Rice"))
        #expect(personal.items(repo).isEmpty)
        personal.select(kira.id, repository: repo)
        #expect(personal.items(repo).map(\.name) == ["Milk"])
        try repo.toggle(try #require(repo.groceries.first { $0.name == "Milk" }))
        #expect(personal.items(repo).isEmpty)
        #expect(repo.tasks.isEmpty)
    }
    @Test func alertsBatchDeduplicateAcrossRelaunchAndAllowReassignment() async throws {
        let (repo, defaults, notices, personal) = try setup()
        let kira = try #require(repo.members.first { $0.displayName == "Kira" })
        personal.select(kira.id, repository: repo)
        await personal.enable(repo, service: CloudKitHouseholdService()) // No sync configuration; no network calls.
        for index in 1...10 { try repo.add(EntryDraft(kind: .grocery, title: "Item \(index)", memberID: kira.id)) }
        await personal.refresh(repo)
        #expect(notices.counts == [10])
        let relaunched = PersonalShopping(defaults: defaults, notifications: notices)
        await relaunched.refresh(repo)
        #expect(notices.counts == [10])
        let item = try #require(repo.groceries.first)
        try repo.toggle(item)
        await relaunched.refresh(repo)
        try repo.toggle(item)
        await relaunched.refresh(repo)
        #expect(notices.counts == [10, 1])
        relaunched.select(nil, repository: repo)
        await relaunched.refresh(repo)
        #expect(notices.counts == [10, 1])
    }
    @Test func buyingOneItemClearsStaleNoticeWhileOtherItemsRemain() async throws {
        let (repo, _, notices, personal) = try setup()
        let kira = try #require(repo.members.first { $0.displayName == "Kira" })
        personal.select(kira.id, repository: repo)
        await personal.enable(repo, service: CloudKitHouseholdService())
        try repo.add(EntryDraft(kind: .grocery, title: "Milk", memberID: kira.id))
        try repo.add(EntryDraft(kind: .grocery, title: "Rice", memberID: kira.id))
        await personal.refresh(repo)
        let prior = notices.cleared.count
        try repo.recordPurchase(try #require(repo.groceries.first { $0.name == "Milk" }), addToInventory: true)
        await personal.refresh(repo)
        #expect(personal.items(repo).map(\.name) == ["Rice"])
        #expect(notices.cleared.count > prior)
        #expect(notices.counts == [2])
    }
    @Test func choosingMemberDoesNotAlertForHistoricalItemsAndDeniedPermissionWorks() async throws {
        let (repo, _, notices, personal) = try setup()
        let kira = try #require(repo.members.first { $0.displayName == "Kira" })
        try repo.add(EntryDraft(kind: .grocery, title: "Milk", memberID: kira.id))
        personal.select(kira.id, repository: repo)
        notices.allowed = false
        await personal.enable(repo, service: CloudKitHouseholdService())
        await personal.refresh(repo)
        #expect(personal.items(repo).count == 1)
        #expect(notices.counts.isEmpty)
        #expect(personal.message != nil)
    }
    @Test func taskAlertsAreSeparateOptInAndPersistDeduplication() async throws {
        let (repo, defaults, notices, personal) = try setup()
        let kira = try #require(repo.members.first { $0.displayName == "Kira" })
        try repo.add(EntryDraft(kind: .task, title: "Existing chore", memberID: kira.id))
        personal.select(kira.id, repository: repo)
        await personal.enable(repo, service: CloudKitHouseholdService())
        try repo.add(EntryDraft(kind: .task, title: "Before task opt in", memberID: kira.id))
        await personal.refresh(repo)
        #expect(notices.counts.isEmpty)
        await personal.enableTasks(repo, service: CloudKitHouseholdService())
        await personal.refresh(repo)
        #expect(notices.counts.isEmpty)
        try repo.add(EntryDraft(kind: .task, title: "Take bins out", memberID: kira.id))
        try repo.add(EntryDraft(kind: .task, title: "Unassigned chore"))
        await personal.refresh(repo)
        #expect(notices.counts == [1])
        #expect(notices.identifiers.last?.hasPrefix("tasks.personal.") == true)
        #expect(personal.tasks(repo).count == 3)
        let relaunched = PersonalShopping(defaults: defaults, notifications: notices)
        await relaunched.refresh(repo)
        #expect(notices.counts == [1])
        let task = try #require(repo.tasks.first { $0.title == "Take bins out" })
        let clearedBefore = notices.cleared.count
        try repo.toggle(task)
        await relaunched.refresh(repo)
        #expect(notices.cleared.count > clearedBefore)
        #expect(personal.tasks(repo).count == 2)
        try repo.toggle(task)
        await relaunched.refresh(repo)
        #expect(notices.counts == [1, 1])
        relaunched.select(nil, repository: repo)
        #expect(!relaunched.taskAlertsEnabled(try #require(repo.household?.id)))
        #expect(relaunched.tasks(repo).isEmpty)
    }
    @Test func deniedTaskPermissionNeverEnablesAlerts() async throws {
        let (repo, _, notices, personal) = try setup()
        personal.select(try #require(repo.members.first?.id), repository: repo)
        notices.allowed = false
        await personal.enableTasks(repo, service: CloudKitHouseholdService())
        #expect(!personal.taskAlertsEnabled(try #require(repo.household?.id)))
        #expect(notices.counts.isEmpty)
    }
    @Test func nowLaterAndCivilDatesProduceGroundedSummary() {
        let items = [
            AssignedShoppingItem(id: UUID(), name: "Milk", quantity: "2 cartons", store: "Store", later: false, day: nil),
            AssignedShoppingItem(id: UUID(), name: "Rice", quantity: "1 kg", store: "Store", later: true, day: "2026-09-12"),
            AssignedShoppingItem(id: UUID(), name: "Tea", quantity: "", store: "", later: true, day: "2026-09-13"),
            AssignedShoppingItem(id: UUID(), name: "Soap", quantity: "", store: "", later: true, day: nil)
        ]
        #expect(AssignedShoppingRules.summary(items, today: "2026-09-12") == "4 items assigned to you. 2 needed now, 2 for later. 1 selected store.")
        #expect(AssignedShoppingRules.summary([], today: "2026-09-12").contains("caught up"))
    }
}

@MainActor private final class RecordingShoppingNotifications: ShoppingNotificationService {
    var allowed = true
    var counts: [Int] = []
    var identifiers: [String] = []
    func requestPermission() async throws -> Bool { allowed }
    func post(identifier: String, newCount: Int) async throws { counts.append(newCount); identifiers.append(identifier) }
    var cleared: [String] = []
    func clear(identifier: String) { cleared.append(identifier) }
}
