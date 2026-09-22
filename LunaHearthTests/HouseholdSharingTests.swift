import CloudKit
import Foundation
import SwiftData
import Testing
@testable import LunaHearth

private actor SharedHomeServer {
    var values: [UUID: RemoteHouseholdRecord] = [:]
    var offline = false
    var revoked = false
    var writable = true
    var partial = false
    var version = 0
    var holdFetch = false
    func setHoldFetch(_ value: Bool) { holdFetch = value }
    func delete() throws {
        if offline { throw HouseholdSharingError.noAccount }
        values = [:]; revoked = true
    }
    func setOffline(_ value: Bool) { offline = value }
    func setRevoked(_ value: Bool) { revoked = value }
    func setWritable(_ value: Bool) { writable = value }
    func setPartial(_ value: Bool) { partial = value }
    func fetch() async throws -> HouseholdChanges {
        while holdFetch { try await Task.sleep(for: .milliseconds(10)) }
        if offline { throw HouseholdSharingError.noAccount }
        if revoked { throw HouseholdSharingError.accessLost }
        return HouseholdChanges(records: Array(values.values), token: Data("token-\(version)".utf8), reset: false, writable: writable)
    }
    func save(_ writes: [HouseholdSyncWrite]) throws -> HouseholdWriteResult {
        if offline { throw HouseholdSharingError.noAccount }
        if revoked { throw HouseholdSharingError.accessLost }
        guard writable else { throw HouseholdSharingError.readOnly }
        var saved: [RemoteHouseholdRecord] = []
        for write in writes {
            if partial && !saved.isEmpty { return HouseholdWriteResult(saved: saved, needsRetry: true) }
            let id = write.entity.record.id
            if values[id]?.systemFields != write.systemFields { return HouseholdWriteResult(saved: saved, needsRetry: true) }
            version += 1
            let value = RemoteHouseholdRecord(entity: write.entity, systemFields: Data("version-\(version)".utf8))
            values[id] = value; saved.append(value)
        }
        return HouseholdWriteResult(saved: saved, needsRetry: false)
    }
}

private actor SharingFake: HouseholdSharingService, HouseholdInvitationLookupService, NamedHouseholdInvitationService {
    private(set) var recipientLookupCount = 0
    func resolveRecipient(email: String, in destination: SyncDestination) -> String { recipientLookupCount += 1; return "kira" }
    func inviteRecipient(accountID: String, in destination: SyncDestination, title: String) throws -> URL {
        guard let url = URL(string: "https://www.icloud.com/share/named-invitation") else { throw HouseholdSharingError.invalidData }
        return url
    }
    func invitation(for url: URL) -> HouseholdInvitation { HouseholdInvitation(id: UUID(), title: "Kira Home") }
    let server: SharedHomeServer
    let account: String
    let invitedHousehold: UUID?
    nonisolated let linksCurrentMemberAutomatically: Bool
    init(server: SharedHomeServer, account: String, invitedHousehold: UUID? = nil, linksCurrentMemberAutomatically: Bool = false) { self.server = server; self.account = account; self.invitedHousehold = invitedHousehold; self.linksCurrentMemberAutomatically = linksCurrentMemberAutomatically }
    func createHome(householdID: UUID) -> SyncDestination {
        SyncDestination(householdID: householdID, zoneName: "LHHousehold-\(householdID.uuidString)", ownerName: "owner", accountID: account, isOwner: true)
    }
    func deleteHome(in destination: SyncDestination) async throws {
        guard destination.isOwner else { throw HouseholdSharingError.readOnly }
        try await server.delete()
    }
    func availableHomes() -> [CloudHome] { [] }
    func changes(in destination: SyncDestination, since token: Data?) async throws -> HouseholdChanges { try await server.fetch() }
    func save(_ changes: [HouseholdSyncWrite], in destination: SyncDestination) async throws -> HouseholdWriteResult { try await server.save(changes) }
    func prepareShare(in destination: SyncDestination, title: String) -> HouseholdShareTicket { HouseholdShareTicket(id: UUID()) }
    func accept(_ invitation: HouseholdInvitation) throws -> SyncDestination {
        guard let id = invitedHousehold else { throw HouseholdSharingError.unavailable }
        return SyncDestination(householdID: id, zoneName: "LHHousehold-\(id.uuidString)", ownerName: "owner", accountID: account, isOwner: false)
    }
}

@MainActor struct HouseholdSharingTests {
    private func repo(_ name: String) throws -> LocalHouseholdRepository {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: name, owner: "", members: [])
        return repo
    }
    private func participantDestination(_ id: UUID) -> SyncDestination {
        SyncDestination(householdID: id, zoneName: "LHHousehold-\(id.uuidString)", ownerName: "owner", accountID: "kira", isOwner: false)
    }

    @Test func nativeJoinCreatesOneProfilePerAccountAndSyncsAdminNames() async throws {
        let server = SharedHomeServer(), owner = try repo("Home")
        let ownerService = SharingFake(server: server, account: "owner", linksCurrentMemberAutomatically: true)
        let controller = HouseholdSharingController(service: ownerService)
        await controller.enable(owner)
        let home = try #require(owner.household?.id)
        #expect(owner.members.count == 1)
        let receiver = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        let joinService = SharingFake(server: server, account: "recipient", invitedHousehold: home, linksCurrentMemberAutomatically: true)
        let joining = HouseholdSharingController(service: joinService)
        joining.invitation = HouseholdInvitation(id: UUID(), title: "Home")
        await joining.acceptInvitation(receiver)
        let person = try #require(receiver.linkedCloudMemberID)
        #expect(receiver.members.count == 2)
        await controller.sync(owner, force: true)
        try owner.renameFamilyMember(person, name: "Kira")
        try owner.add(EntryDraft(kind: .task, title: "Buy milk", memberID: person))
        await controller.sync(owner, force: true)
        await joining.sync(receiver, force: true)
        #expect(receiver.members.first { $0.id == person }?.displayName == "Kira")
        #expect(receiver.tasks.first?.assignedMemberID == person)
        #expect(receiver.linkedCloudMemberID == person)
        #expect(throws: HouseholdSharingError.self) { try receiver.renameFamilyMember(person, name: "Another name") }
        let secondDevice = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        let secondJoin = HouseholdSharingController(service: joinService)
        secondJoin.invitation = HouseholdInvitation(id: UUID(), title: "Home")
        await secondJoin.acceptInvitation(secondDevice)
        #expect(secondDevice.members.count == 2)
        #expect(secondDevice.linkedCloudMemberID == person)
        await controller.sync(owner, force: true)
        #expect(owner.members.count == 2)
        #expect(await ownerService.recipientLookupCount == 0)
        #expect(await joinService.recipientLookupCount == 0)
    }

    @Test func nativeInvitationDoesNotRequireEmailDiscovery() async throws {
        let owner = try repo("Home")
        let service = SharingFake(server: SharedHomeServer(), account: "owner")
        let controller = HouseholdSharingController(service: service)
        await controller.enable(owner)
        await controller.prepareInvitation(owner)
        #expect(controller.shareTicket != nil)
        #expect(await service.recipientLookupCount == 0)
    }

    @Test func namedInvitationWaitsForBusySyncAndCanBeCancelled() async throws {
        let owner = try repo("Home")
        let server = SharedHomeServer()
        let controller = HouseholdSharingController(service: SharingFake(server: server, account: "owner"))
        await controller.enable(owner)
        await server.setHoldFetch(true)
        let syncing = Task { await controller.sync(owner, force: true) }
        while !controller.working { await Task.yield() }
        let invitation = Task {
            try await controller.prepareNamedInvitation(ownerName: "Ravi", name: "Kira", email: "kira@example.com", repository: owner)
        }
        try await Task.sleep(for: .milliseconds(150))
        #expect(owner.members.isEmpty)
        await server.setHoldFetch(false)
        await syncing.value
        _ = try await invitation.value
        #expect(owner.members.count == 2)

        await server.setHoldFetch(true)
        let nextSync = Task { await controller.sync(owner, force: true) }
        while !controller.working { await Task.yield() }
        let cancelled = Task {
            try await controller.prepareNamedInvitation(ownerName: "Ravi", name: "Changed", email: "kira@example.com", repository: owner)
        }
        cancelled.cancel()
        do { _ = try await cancelled.value; Issue.record("Cancelled invitation should not prepare a profile") }
        catch is CancellationError {} catch { Issue.record("Expected cancellation") }
        #expect(owner.members.contains { $0.displayName == "Kira" })
        #expect(!owner.members.contains { $0.displayName == "Changed" })
        await server.setHoldFetch(false)
        await nextSync.value
    }

    @Test func namedInvitationCreatesProfilesAndSelectsRecipientAutomatically() async throws {
        let server = SharedHomeServer(), owner = try repo("Kira Home")
        let controller = HouseholdSharingController(service: SharingFake(server: server, account: "ipad"))
        await controller.enable(owner)
        _ = try await controller.prepareNamedInvitation(ownerName: "Ravi", name: "Kira", email: "kira@example.com", repository: owner)
        let member = try #require(owner.members.first { $0.displayName == "Kira" })
        try owner.add(EntryDraft(kind: .task, title: "Water plants", memberID: member.id))
        await controller.sync(owner, force: true)
        let receiver = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        let joining = HouseholdSharingController(service: SharingFake(server: server, account: "kira", invitedHousehold: try #require(owner.household?.id)))
        joining.invitation = HouseholdInvitation(id: UUID(), title: "Kira Home")
        await joining.acceptInvitation(receiver)
        #expect(receiver.members.count == 2)
        #expect(receiver.linkedCloudMemberID == member.id)
        let suite = "NamedMemberTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let personal = PersonalShopping(defaults: defaults, notifications: SharingTestNotifications())
        personal.selectLinkedMember(receiver)
        #expect(personal.memberID(try #require(receiver.household?.id)) == member.id)
        #expect(personal.tasks(receiver).map(\.title) == ["Water plants"])
        // Repeated refresh must not reset enabled notification preferences.
        let home = try #require(receiver.household?.id)
        defaults.set(true, forKey: "shopping.personal.\(home).taskAlerts")
        personal.selectLinkedMember(receiver)
        #expect(personal.taskAlertsEnabled(home))
        _ = try await controller.prepareNamedInvitation(ownerName: "Ravi", name: "Kira Rose", email: "kira@example.com", repository: owner)
        await joining.sync(receiver, force: true)
        #expect(receiver.members.count == 2)
        #expect(receiver.members.first { $0.id == member.id }?.displayName == "Kira Rose")
        #expect(receiver.tasks.first?.assignedMemberID == member.id)
    }

    @Test func namedMembersKeepExistingOwnerAndNeverMatchByDisplayName() async throws {
        let server = SharedHomeServer(), owner = try repo("Home")
        let controller = HouseholdSharingController(service: SharingFake(server: server, account: "ipad"))
        await controller.enable(owner)
        try owner.prepareNamedMembers(ownerName: "Ravi", recipientName: "Ravi", accountID: "first")
        let ownerID = owner.members.first { $0.role == .owner }?.id
        try owner.prepareNamedMembers(ownerName: "Ravi", recipientName: "Ravi", accountID: "second")
        #expect(owner.members.count == 3)
        #expect(Set(owner.members.map(\.id)).count == 3)
        #expect(owner.members.first { $0.role == .owner }?.id == ownerID)
        #expect(SharedMemberIdentity.memberID(householdID: UUID(), accountID: "first") != owner.members.first { $0.role != .owner }?.id)
    }

    @Test func offlineNamedInvitationKeepsLocalNamesForRetryWithoutGrantingAccess() async throws {
        let server = SharedHomeServer(), owner = try repo("Home")
        let controller = HouseholdSharingController(service: SharingFake(server: server, account: "ipad"))
        await controller.enable(owner)
        await server.setOffline(true)
        await #expect(throws: (any Error).self) {
            _ = try await controller.prepareNamedInvitation(ownerName: "Ravi", name: "Kira", email: "kira@example.com", repository: owner)
        }
        #expect(owner.members.count == 2)
        await server.setOffline(false)
        _ = try await controller.prepareNamedInvitation(ownerName: "Ravi", name: "Kira", email: "kira@example.com", repository: owner)
        #expect(owner.members.count == 2)
    }

    @Test func pausedSharingCannotPrepareOrSendANamedInvitation() async throws {
        let server = SharedHomeServer(), owner = try repo("Home")
        let controller = HouseholdSharingController(service: SharingFake(server: server, account: "ipad"))
        await controller.enable(owner)
        let destination = try #require(owner.syncConfiguration?.destination)
        try owner.pauseForCloudDeletion(destination)
        await #expect(throws: HouseholdSharingError.notReady) {
            _ = try await controller.prepareNamedInvitation(ownerName: "Ravi", name: "Kira", email: "kira@example.com", repository: owner)
        }
        #expect(owner.members.isEmpty)
    }

    @Test func invitationCanJoinAnEmptyDeviceWithoutCreatingAHome() async throws {
        let server = SharedHomeServer(), owner = try repo("Kira Home")
        let empty = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        let ownerController = HouseholdSharingController(service: SharingFake(server: server, account: "ipad"))
        await ownerController.enable(owner)
        let receiver = HouseholdSharingController(service: SharingFake(server: server, account: "phone", invitedHousehold: try #require(owner.household?.id)))
        await receiver.lookupInvitation("https://www.icloud.com/share/test-invitation")
        #expect(receiver.invitation?.title == "Kira Home")
        #expect(empty.households.isEmpty)
        await receiver.acceptInvitation(empty)
        #expect(empty.household?.id == owner.household?.id)
        #expect(empty.households.count == 1)
        #expect(empty.syncConfiguration?.isOwner == false)
        #expect(receiver.invitation == nil)
    }
    @Test func invitationURLValidationRejectsUntrustedDestinations() {
        #expect(HouseholdInvitationLink.url(from: " https://www.icloud.com/share/abc ") != nil)
        for text in ["http://www.icloud.com/share/abc", "https://www.icloud.com.attacker.test/share/abc", "https://www.icloud.com@attacker.test/share/abc", "https://www.icloud.com/share/", "https://example.com/share/abc", "file:///share/abc"] {
            #expect(HouseholdInvitationLink.url(from: text) == nil)
        }
    }
    @Test func invalidInvitationIsVisibleWithoutAHome() async {
        let receiver = HouseholdSharingController(service: SharingFake(server: SharedHomeServer(), account: "phone"))
        await receiver.lookupInvitation("https://example.com/share/abc")
        #expect(receiver.invitation == nil)
        #expect(receiver.invitationError != nil)
        #expect(!receiver.lookingUpInvitation)
    }

    @Test func purchaseHistorySyncsWithLinksAndSurvivesExpenseDeletion() async throws {
        let server = SharedHomeServer(), owner = try repo("Family"), participant = try repo("Personal")
        let home = try #require(owner.household?.id)
        let ravi = HouseholdSharingController(service: SharingFake(server: server, account: "ravi"))
        let kira = HouseholdSharingController(service: SharingFake(server: server, account: "kira", invitedHousehold: home))
        await ravi.enable(owner)
        kira.invitation = HouseholdInvitation(id: UUID(), title: "Family")
        await kira.acceptInvitation(participant)
        var expense = ExpenseDraft(); expense.merchant = "Costco"; expense.amount = "4.00"
        let text = "Milk 4.00"
        try owner.importReceipt(ReceiptRules.scan(text: text).lines, householdID: home, storeName: "Costco", expense: expense, receiptKey: ExpenseRules.receiptKey(text))
        await ravi.sync(owner, force: true); await kira.sync(participant, force: true)
        #expect(ravi.message == nil && kira.message == nil)
        let entry = try #require(participant.purchases.first)
        #expect(entry.expenseID == participant.expenses.first?.id)
        #expect(entry.inventoryID == participant.inventory.first?.id)
        #expect(entry.groceryID == participant.groceries.first?.id)
        try owner.deleteExpense(try #require(owner.expenses.first))
        await ravi.sync(owner, force: true); await kira.sync(participant, force: true)
        #expect(participant.expenses.isEmpty && participant.purchases.count == 1)
        #expect(participant.purchases.first?.id == entry.id)
        #expect(kira.message == nil)
    }

    @Test func expensesSyncUpdatesAndDeletionAcrossHouseholdMembers() async throws {
        let server = SharedHomeServer(), owner = try repo("Family"), participant = try repo("Personal")
        let ravi = HouseholdSharingController(service: SharingFake(server: server, account: "ravi"))
        let kira = HouseholdSharingController(service: SharingFake(server: server, account: "kira", invitedHousehold: try #require(owner.household?.id)))
        await ravi.enable(owner)
        kira.invitation = HouseholdInvitation(id: UUID(), title: "Family")
        await kira.acceptInvitation(participant)
        var draft = ExpenseDraft(); draft.merchant = "Market"; draft.amount = "50.25"; draft.currency = "INR"
        try owner.saveExpense(draft)
        await ravi.sync(owner, force: true); await kira.sync(participant, force: true)
        #expect(ravi.message == nil && kira.message == nil)
        let copied = try #require(participant.expenses.first)
        #expect(copied.amountMinorUnits == 5025 && copied.currencyCode == "INR")
        draft.amount = "60.00"; try participant.saveExpense(draft, editing: copied.id)
        await kira.sync(participant, force: true); await ravi.sync(owner, force: true)
        #expect(owner.expenses.first?.amountMinorUnits == 6000)
        try owner.deleteExpense(try #require(owner.expenses.first))
        await ravi.sync(owner, force: true); await kira.sync(participant, force: true)
        #expect(owner.expenses.isEmpty && participant.expenses.isEmpty)
    }

    @Test func inventoryPurchaseSyncsAndDeletionUsesTombstones() async throws {
        let server = SharedHomeServer(), owner = try repo("Family"), participant = try repo("Personal")
        let ravi = HouseholdSharingController(service: SharingFake(server: server, account: "ravi"))
        let kira = HouseholdSharingController(service: SharingFake(server: server, account: "kira", invitedHousehold: try #require(owner.household?.id)))
        await ravi.enable(owner)
        kira.invitation = HouseholdInvitation(id: UUID(), title: "Family")
        await kira.acceptInvitation(participant)
        try owner.add(EntryDraft(kind: .grocery, title: "Rice", quantity: "2 kg", storeName: "DMart"))
        await ravi.sync(owner, force: true); await kira.sync(participant, force: true)
        try participant.recordPurchase(try #require(participant.groceries.first), addToInventory: true)
        await kira.sync(participant, force: true); await ravi.sync(owner, force: true)
        #expect(ravi.message == nil && kira.message == nil)
        #expect(owner.groceries.first?.purchaseDisposition == "inventory")
        let pack = try #require(owner.inventory.first)
        #expect(pack.quantityText == "2 kg" && pack.storeID == owner.stores.first?.id)
        var stock = InventoryDraft(pack); stock.isLowStock = true
        try owner.saveInventory(stock, editing: pack.id)
        await ravi.sync(owner, force: true); await kira.sync(participant, force: true)
        #expect(participant.inventory.first?.isLowStock == true)
        try owner.setInventoryUsedUp(pack, usedUp: true)
        await ravi.sync(owner, force: true); await kira.sync(participant, force: true)
        #expect(participant.inventory.first?.isUsedUp == true)
        try participant.deleteInventory(try #require(participant.inventory.first))
        await kira.sync(participant, force: true); await ravi.sync(owner, force: true)
        #expect(owner.inventory.isEmpty && participant.inventory.isEmpty)
        #expect(owner.groceries.first?.isCompleted == true)
    }

    @Test func twoDevicesShareShoppingAndPreserveExistingPersonalHome() async throws {
        let server = SharedHomeServer(), owner = try repo("Family"), participant = try repo("Personal")
        try participant.add(EntryDraft(kind: .task, title: "Private plan"))
        let personalID = try #require(participant.household?.id)
        let ravi = HouseholdSharingController(service: SharingFake(server: server, account: "ravi"))
        let kira = HouseholdSharingController(service: SharingFake(server: server, account: "kira", invitedHousehold: try #require(owner.household?.id)))
        await ravi.enable(owner)
        #expect(ravi.message == nil)
        kira.invitation = HouseholdInvitation(id: UUID(), title: "Family")
        await kira.acceptInvitation(participant)
        #expect(kira.invitation == nil)
        #expect(kira.message == nil)
        #expect(participant.households.count == 2)
        #expect(participant.tasks.isEmpty)
        try owner.addMember(name: "Ravi", role: .adult)
        let buyer = try #require(owner.members.first?.id)
        try owner.add(EntryDraft(kind: .grocery, title: "Milk", memberID: buyer, quantity: "2 cartons", storeName: "Fresh Market", neededLater: true))
        await ravi.sync(owner, force: true)
        await kira.sync(participant, force: true)
        let milk = try #require(participant.groceries.first)
        #expect(milk.name == "Milk")
        #expect(milk.quantityText == "2 cartons")
        #expect(milk.storeName == "Fresh Market")
        #expect(milk.storeID == participant.stores.first?.id)
        #expect(participant.stores.first?.name == "Fresh Market")
        #expect(milk.neededLater == true)
        var reschedule = EntryDraft.editing(milk)
        reschedule.neededLater = false
        try participant.add(reschedule)
        #expect(milk.assignedMemberID == buyer)
        try participant.toggle(milk)
        await kira.sync(participant, force: true)
        await ravi.sync(owner, force: true)
        #expect(owner.groceries.first?.isCompleted == true)
        #expect(owner.groceries.first?.neededLater == false)
        try participant.activateHousehold(personalID)
        #expect(participant.tasks.first?.title == "Private plan")
        #expect(participant.syncConfiguration == nil)
        #expect(try await server.fetch().records.allSatisfy { $0.entity.record.householdID != personalID })
    }

    @Test func privateStoreSyncsWithoutAnyShoppingItems() async throws {
        let server = SharedHomeServer(), owner = try repo("Family"), participant = try repo("Personal")
        let store = try owner.addStore(name: "Anand Stores", branch: "Adyar")
        let ravi = HouseholdSharingController(service: SharingFake(server: server, account: "ravi"))
        let kira = HouseholdSharingController(service: SharingFake(server: server, account: "kira"))
        await ravi.enable(owner)
        await kira.open(participantDestination(try #require(owner.household?.id)), repository: participant)
        #expect(ravi.message == nil && kira.message == nil)
        #expect(participant.groceries.isEmpty)
        #expect(participant.stores.first?.id == store.id)
        #expect(participant.stores.first?.displayName == "Anand Stores · Adyar")
        await server.setOffline(true)
        let second = try participant.addStore(name: "Corner Shop")
        await kira.sync(participant, force: true)
        #expect(participant.stores.contains { $0.id == second.id })
        await server.setOffline(false)
        await kira.sync(participant, force: true); await ravi.sync(owner, force: true)
        #expect(owner.stores.contains { $0.id == second.id })
    }

    @Test func offlineEditsAndTombstonesSurviveRepositoryReopen() async throws {
        let server = SharedHomeServer(), owner = try repo("Family"), participant = try repo("Personal")
        let ravi = HouseholdSharingController(service: SharingFake(server: server, account: "ravi"))
        let kira = HouseholdSharingController(service: SharingFake(server: server, account: "kira"))
        try owner.add(EntryDraft(kind: .grocery, title: "Milk"))
        await ravi.enable(owner)
        await kira.open(participantDestination(try #require(owner.household?.id)), repository: participant)
        await server.setOffline(true)
        let itemID = try #require(owner.groceries.first?.id)
        try owner.deletePlanningEntry(id: itemID, kind: .grocery)
        try owner.add(EntryDraft(kind: .task, title: "Buy filter"))
        await ravi.sync(owner, force: true)
        #expect(ravi.message != nil)
        let reopened = LocalHouseholdRepository(container: owner.context.container)
        try reopened.reload()
        #expect(reopened.tasks.first?.title == "Buy filter")
        #expect(reopened.groceries.isEmpty)
        await server.setOffline(false)
        await ravi.sync(reopened, force: true)
        await kira.sync(participant, force: true)
        #expect(participant.groceries.isEmpty)
        #expect(participant.tasks.first?.title == "Buy filter")
        #expect(try await server.fetch().records.contains { $0.entity.record.id == itemID && $0.entity.deleted })
    }

    @Test func sequentialPurchaseAndReceiptLinkSyncWithoutSecondStockAction() async throws {
        let server = SharedHomeServer(), owner = try repo("Family"), participant = try repo("Personal")
        let ravi = HouseholdSharingController(service: SharingFake(server: server, account: "ravi"))
        let kira = HouseholdSharingController(service: SharingFake(server: server, account: "kira"))
        try owner.add(EntryDraft(kind: .grocery, title: "Milk", quantity: "1 litre"))
        await ravi.enable(owner)
        let home = try #require(owner.household?.id)
        await kira.open(participantDestination(home), repository: participant)
        try owner.recordPurchase(try #require(owner.groceries.first), addToInventory: true)
        await ravi.sync(owner, force: true); await kira.sync(participant, force: true)
        #expect(participant.inventory.first?.quantityText == "1 litre")
        var lines = ReceiptRules.scan(text: "Milk 4.00").lines
        lines[0].existingPurchaseID = participant.purchases.first?.id
        var expense = ExpenseDraft(); expense.amount = "4"; expense.merchant = "Market"
        let key = ReceiptRules.hash("shared receipt")
        await server.setOffline(true)
        try participant.importReceipt(lines, householdID: home, storeName: "Market", expense: expense, receiptKey: key)
        await kira.sync(participant, force: true)
        #expect(participant.expenses.count == 1 && participant.inventory.first?.quantityText == "1 litre")
        await server.setOffline(false)
        await kira.sync(participant, force: true); await ravi.sync(owner, force: true)
        #expect(owner.expenses.count == 1 && owner.purchases.count == 1)
        #expect(owner.receiptLineImported(lines[0].id))
        #expect(try owner.importReceipt(lines, householdID: home, storeName: "Market", expense: expense, receiptKey: key) == 0)
        #expect(owner.inventory.first?.quantityText == "1 litre")
    }

    @Test func simultaneousOfflineRestocksPreserveBothVersionsForReview() async throws {
        let server = SharedHomeServer(), owner = try repo("Family"), participant = try repo("Personal")
        let ravi = HouseholdSharingController(service: SharingFake(server: server, account: "ravi"))
        let kira = HouseholdSharingController(service: SharingFake(server: server, account: "kira"))
        var draft = InventoryDraft(); draft.name = "Milk"; draft.quantity = "1 l"
        let stock = try owner.saveInventory(draft)
        await ravi.enable(owner)
        await kira.open(participantDestination(try #require(owner.household?.id)), repository: participant)
        await server.setOffline(true)
        try owner.add(EntryDraft(kind: .grocery, title: "Milk", quantity: "1 l"))
        try participant.add(EntryDraft(kind: .grocery, title: "Milk", quantity: "2 l"))
        try owner.recordPurchase(try #require(owner.groceries.first), addToInventory: true, keeping: stock)
        try participant.recordPurchase(try #require(participant.groceries.first), addToInventory: true, keeping: stock)
        await ravi.sync(owner, force: true); await kira.sync(participant, force: true)
        #expect(owner.inventory.first?.quantityText == "2 l" && participant.inventory.first?.quantityText == "3 l")
        await server.setOffline(false)
        await ravi.sync(owner, force: true); await kira.sync(participant, force: true)
        #expect(participant.inventory.first?.quantityText == "3 l")
        #expect(participant.syncBaselines.contains { $0.entityID == stock && $0.conflict })
        #expect(kira.message == HouseholdSharingError.conflicts.localizedDescription)
        // Conflict review survives a repository restart; neither balance is silently chosen.
        let reopened = LocalHouseholdRepository(container: participant.context.container); try reopened.reload()
        #expect(reopened.syncBaselines.contains { $0.entityID == stock && $0.conflict })
        #expect(reopened.purchases.count == 2)
        await kira.resolveConflicts(useCloud: false, repository: reopened)
        await ravi.sync(owner, force: true)
        #expect(owner.inventory.first?.quantityText == "3 l")
        #expect(owner.purchases.count == 2 && reopened.syncBaselines.allSatisfy { !$0.conflict })
    }

    @Test func simultaneousEditRequiresReviewAndKeepsBothVersionsUntilResolved() async throws {
        let server = SharedHomeServer(), owner = try repo("Family"), participant = try repo("Personal")
        let ravi = HouseholdSharingController(service: SharingFake(server: server, account: "ravi"))
        let kira = HouseholdSharingController(service: SharingFake(server: server, account: "kira"))
        try owner.add(EntryDraft(kind: .task, title: "Original"))
        await ravi.enable(owner)
        await kira.open(participantDestination(try #require(owner.household?.id)), repository: participant)
        var local = EntryDraft.editing(try #require(participant.tasks.first)); local.title = "Kira version"
        try participant.add(local)
        var remote = EntryDraft.editing(try #require(owner.tasks.first)); remote.title = "Ravi version"
        try owner.add(remote)
        await ravi.sync(owner, force: true)
        await kira.sync(participant, force: true)
        #expect(participant.tasks.first?.title == "Kira version")
        #expect(participant.syncBaselines.filter(\.conflict).count == 1)
        #expect(kira.message == HouseholdSharingError.conflicts.localizedDescription)
        await kira.resolveConflicts(useCloud: false, repository: participant)
        await ravi.sync(owner, force: true)
        #expect(owner.tasks.first?.title == "Kira version")
        #expect(participant.syncBaselines.allSatisfy { !$0.conflict })
        var nextLocal = EntryDraft.editing(try #require(participant.tasks.first)); nextLocal.title = "Another local version"
        var nextCloud = EntryDraft.editing(try #require(owner.tasks.first)); nextCloud.title = "Reviewed cloud version"
        try participant.add(nextLocal); try owner.add(nextCloud)
        await ravi.sync(owner, force: true)
        await kira.sync(participant, force: true)
        #expect(participant.syncBaselines.contains { $0.conflict })
        await kira.resolveConflicts(useCloud: true, repository: participant)
        #expect(participant.tasks.first?.title == "Reviewed cloud version")
        #expect(kira.message == nil)
    }

    @Test func revokedAccessNeverWipesLocalDataAndReadOnlyRejectsWrites() async throws {
        let server = SharedHomeServer(), owner = try repo("Home")
        let controller = HouseholdSharingController(service: SharingFake(server: server, account: "ravi"))
        try owner.add(EntryDraft(kind: .task, title: "Keep me"))
        await controller.enable(owner)
        await server.setRevoked(true)
        await controller.sync(owner, force: true)
        #expect(owner.syncConfiguration?.recovery == true)
        #expect(owner.tasks.first?.title == "Keep me")
        #expect(throws: HouseholdSharingError.self) { try owner.add(EntryDraft(kind: .grocery, title: "Cannot edit")) }
        await server.setRevoked(false)
        await server.setWritable(false)
        await controller.sync(owner, force: true)
        #expect(owner.syncConfiguration?.recovery == false)
        #expect(owner.syncConfiguration?.readOnly == true)
        #expect(owner.tasks.first?.title == "Keep me")
    }

    @Test func partialAcknowledgementsRetryWithoutDuplicateRecords() async throws {
        let server = SharedHomeServer(), owner = try repo("Home")
        let controller = HouseholdSharingController(service: SharingFake(server: server, account: "ravi"))
        await controller.enable(owner)
        try owner.add(EntryDraft(kind: .task, title: "One"))
        try owner.add(EntryDraft(kind: .grocery, title: "Two"))
        await server.setPartial(true)
        await controller.sync(owner, force: true)
        #expect(controller.pendingCount == 1)
        await server.setPartial(false)
        await controller.sync(owner, force: true)
        #expect(controller.pendingCount == 0)
        #expect(try await server.fetch().records.count == 3)
    }

    @Test func sharedBaselineAndPendingEditsSurviveDiskReopen() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let schema = LocalStoreConfiguration.schema
        let configuration = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("home.store"), cloudKitDatabase: .none)
        let server = SharedHomeServer()
        func writePending() async throws -> UUID {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let repo = LocalHouseholdRepository(container: container)
            try repo.createHousehold(name: "Family", owner: "", members: [])
            let sharing = HouseholdSharingController(service: SharingFake(server: server, account: "ravi"))
            await sharing.enable(repo)
            try repo.add(EntryDraft(kind: .grocery, title: "Offline milk"))
            return try #require(repo.household?.id)
        }
        let id = try await writePending()
        let reopened = LocalHouseholdRepository(container: try ModelContainer(for: schema, configurations: [configuration]))
        try reopened.reload()
        #expect(reopened.household?.id == id)
        #expect(reopened.syncConfiguration?.enabled == true)
        #expect(reopened.syncBaselines.count == 1)
        #expect(reopened.groceries.first?.name == "Offline milk")
        let sharing = HouseholdSharingController(service: SharingFake(server: server, account: "ravi"))
        await sharing.sync(reopened, force: true)
        #expect(sharing.pendingCount == 0)
        #expect(try await server.fetch().records.count == 2)
    }

    @Test func simultaneousRoomMovesCanBeReviewedAndReconciledWithoutOverwritingLayout() async throws {
        let server = SharedHomeServer(), owner = try repo("Family"), participant = try repo("Personal")
        let ravi = HouseholdSharingController(service: SharingFake(server: server, account: "ravi"))
        let kira = HouseholdSharingController(service: SharingFake(server: server, account: "kira"))
        try owner.saveRoomLayout(id: nil, name: "A", floorID: nil, preset: .living, footprint: RoomFootprint(x: 0, z: 0, width: 4, depth: 4, height: 3))
        try owner.saveRoomLayout(id: nil, name: "B", floorID: nil, preset: .bedroom, footprint: RoomFootprint(x: 5, z: 0, width: 4, depth: 4, height: 3))
        await ravi.enable(owner)
        await kira.open(participantDestination(try #require(owner.household?.id)), repository: participant)
        let a = try #require(owner.rooms.first { $0.name == "A" })
        let b = try #require(participant.rooms.first { $0.name == "B" })
        try owner.saveRoomLayout(id: a.id, name: "A", floorID: nil, preset: .living, footprint: RoomFootprint(x: 0, z: 0, width: 5, depth: 4, height: 3))
        try participant.saveRoomLayout(id: b.id, name: "B", floorID: nil, preset: .bedroom, footprint: RoomFootprint(x: 4, z: 0, width: 4, depth: 4, height: 3))
        await ravi.sync(owner, force: true)
        await kira.sync(participant, force: true)
        #expect(!kira.layoutProposals.isEmpty)
        #expect(participant.rooms.first { $0.name == "A" }?.layoutWidth == 4)
        try participant.saveRoomLayout(id: b.id, name: "B", floorID: nil, preset: .bedroom, footprint: RoomFootprint(x: 6, z: 0, width: 4, depth: 4, height: 3))
        await kira.sync(participant, force: true)
        #expect(kira.message == nil)
        #expect(participant.rooms.first { $0.name == "A" }?.layoutWidth == 5)
        await ravi.sync(owner, force: true)
        #expect(owner.rooms.first { $0.name == "B" }?.layoutX == 6)
    }

    @Test func cloudDeletionKeepsLocalDataAndPausesAcrossFailureAndRestart() async throws {
        let container = try LocalStoreConfiguration.makeContainer(inMemory: true)
        let owner = LocalHouseholdRepository(container: container)
        try owner.createHousehold(name: "Home", owner: "", members: [])
        try owner.add(EntryDraft(kind: .grocery, title: "Milk"))
        let server = SharedHomeServer()
        let controller = HouseholdSharingController(service: SharingFake(server: server, account: "ravi"))
        await controller.enable(owner)
        let destination = try #require(owner.syncConfiguration?.destination)
        await server.setOffline(true)
        await controller.deleteCloudHome(owner, destination: destination)
        #expect(owner.syncConfiguration?.enabled == false)
        let reopened = LocalHouseholdRepository(container: container)
        try reopened.reload()
        #expect(reopened.syncConfiguration?.enabled == false)
        #expect(throws: HouseholdSharingError.self) { try reopened.configureSharing(destination) }
        #expect(reopened.groceries.first?.name == "Milk")
        await server.setOffline(false)
        await controller.deleteCloudHome(reopened, destination: destination)
        #expect(reopened.syncConfiguration == nil)
        #expect(reopened.syncBaselines.isEmpty)
        #expect(reopened.groceries.first?.name == "Milk")
        try reopened.add(EntryDraft(kind: .grocery, title: "Bread"))
        await controller.sync(reopened, force: true)
        #expect(await server.values.isEmpty)
        #expect(reopened.groceries.count == 2)
    }

    @Test func participantCannotDeleteCloudHome() async throws {
        let repo = try repo("Home")
        let destination = participantDestination(try #require(repo.household?.id))
        try repo.configureSharing(destination)
        #expect(throws: HouseholdSharingError.self) { try repo.pauseForCloudDeletion(destination) }
        #expect(repo.syncConfiguration?.enabled == true)
    }

    @Test func cloudDatePrecisionDoesNotCausePerpetualUploads() throws {
        let repo = try repo("Home")
        let local = try #require(repo.makeBackup().records.first)
        func rounded(_ date: Date) -> Date { Date(timeIntervalSince1970: (date.timeIntervalSince1970 * 1000).rounded() / 1000) }
        let cloud = BackupRecord(id: local.id, householdID: local.householdID, kind: local.kind,
                                 createdAt: rounded(local.createdAt), modifiedAt: rounded(local.modifiedAt), payload: local.payload)
        let remote = RemoteHouseholdRecord(entity: SyncEntity(record: cloud, deleted: false), systemFields: Data())
        let plan = HouseholdSyncMerge.plan(local: [local], baseline: [remote], remote: [remote])
        #expect(plan.upload.isEmpty)
        #expect(plan.apply.isEmpty)
        #expect(plan.conflicts.isEmpty)
    }

    @Test func cloudMapperPreservesIDsTombstonesAndRejectsCrossHouseholdData() throws {
        let repo = try repo("Home")
        try repo.add(EntryDraft(kind: .grocery, title: "Milk"))
        let value = try #require(repo.makeBackup().records.first { $0.kind == "GroceryItem" })
        let zone = CKRecordZone.ID(zoneName: "LHHousehold-\(value.householdID.uuidString)")
        let cloud = try HouseholdCloudMapper.encode(HouseholdSyncWrite(entity: SyncEntity(record: value, deleted: false), systemFields: nil), zone: zone)
        let decoded = try HouseholdCloudMapper.decode(cloud, householdID: value.householdID)
        #expect(decoded.entity.record == value)
        #expect(throws: HouseholdSharingError.self) { try HouseholdCloudMapper.decode(cloud, householdID: UUID()) }
        let deleted = SyncEntity.tombstone(value, now: .now)
        let tombstone = try HouseholdCloudMapper.encode(HouseholdSyncWrite(entity: deleted, systemFields: decoded.systemFields), zone: zone)
        #expect(try HouseholdCloudMapper.decode(tombstone, householdID: value.householdID).entity.deleted)
        #expect(tombstone.recordID == cloud.recordID)
    }

    @Test func corruptIncomingGraphLeavesStoreAndTokenUnchanged() throws {
        let owner = try repo("Home")
        let id = try #require(owner.household?.id)
        try owner.configureSharing(participantDestination(id))
        let original = try owner.makeBackup()
        let corrupt = BackupRecord(id: UUID(), householdID: id, kind: "HomeAsset", createdAt: .now, modifiedAt: .now, payload: Data("{}".utf8))
        var plan = HouseholdSyncMerge.Plan(); plan.apply = [SyncEntity(record: corrupt, deleted: false)]
        #expect(throws: (any Error).self) {
            try owner.applyCloudChanges(plan, remote: [], token: Data("bad".utf8), writable: true)
        }
        #expect(owner.syncConfiguration?.changeToken == nil)
        #expect(try owner.makeBackup().records == original.records)
    }
}

@MainActor private final class SharingTestNotifications: ShoppingNotificationService {
    func requestPermission() async throws -> Bool { false }
    func post(identifier: String, newCount: Int) async throws {}
    func clear(identifier: String) {}
}
