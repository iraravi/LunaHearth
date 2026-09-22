import Foundation
import SwiftData

extension LocalHouseholdRepository {
    /// Persist the pause before any destructive network request, including failed retries.
    func pauseForCloudDeletion(_ destination: SyncDestination) throws {
        guard let configuration = syncConfiguration, configuration.destination == destination,
              destination.isOwner else { throw HouseholdSharingError.readOnly }
        try commit(notifyDelivery: false, allowReadOnly: true) {
            configuration.enabled = false
            configuration.recovery = true
        }
    }

    func finishCloudDeletion(_ destination: SyncDestination) throws {
        guard let configuration = syncConfiguration, configuration.destination == destination,
              !configuration.enabled, destination.isOwner else { throw HouseholdSharingError.notReady }
        try commit(notifyDelivery: false, allowReadOnly: true) {
            for baseline in syncBaselines { context.delete(baseline) }
            context.delete(configuration)
        }
    }

    func cloudBaselines() throws -> [RemoteHouseholdRecord] {
        try syncBaselines.map { try JSONDecoder().decode(RemoteHouseholdRecord.self, from: $0.remoteData) }
    }

    func activateHousehold(_ id: UUID) throws {
        guard households.contains(where: { $0.id == id }) else { throw HouseholdSharingError.invalidData }
        try commit(allowReadOnly: true) { try selectHousehold(id) }
    }

    private func selectHousehold(_ id: UUID) throws {
        if let selection = try context.fetch(FetchDescriptor<ActiveHouseholdSelection>()).first { selection.householdID = id }
        else { context.insert(ActiveHouseholdSelection(householdID: id)) }
    }

    func configureSharing(_ destination: SyncDestination) throws {
        guard household?.id == destination.householdID else { throw HouseholdSharingError.invalidData }
        try commit(notifyDelivery: false, allowReadOnly: true) {
            if let existing = syncConfiguration {
                guard existing.destination == destination else { throw HouseholdSharingError.accountChanged }
                guard existing.enabled else { throw HouseholdSharingError.notReady }
                existing.enabled = true
            } else { context.insert(HouseholdSyncConfiguration(destination)) }
        }
    }

    func importSharedHome(_ destination: SyncDestination, changes: HouseholdChanges) throws {
        guard !households.contains(where: { $0.id == destination.householdID }) else { throw HouseholdSharingError.invalidData }
        let active = changes.records.filter { !$0.entity.deleted }.map(\.entity.record)
        _ = try BackupCodec.snapshot(householdID: destination.householdID, records: active)
        try verifyGlobalIDs(active, householdID: destination.householdID)
        try commit(allowReadOnly: true) {
            for record in active { try BackupCodec.insert(record, into: context) }
            let configuration = HouseholdSyncConfiguration(destination)
            configuration.changeToken = changes.token; configuration.readOnly = !changes.writable
            configuration.lastSyncedAt = .now
            context.insert(configuration)
            try storeBaselines(changes.records, conflicts: [])
            try selectHousehold(destination.householdID)
        }
    }

    /// Apply a verified merge and its token in the same local transaction. A failed
    /// graph validation leaves both local values and the previous token unchanged.
    func applyCloudChanges(_ plan: HouseholdSyncMerge.Plan, remote: [RemoteHouseholdRecord], token: Data, writable: Bool) throws {
        guard let configuration = syncConfiguration, let household else { throw HouseholdSharingError.invalidData }
        var records = Dictionary(uniqueKeysWithValues: try makeBackup().records.map { ($0.id, $0) })
        for entity in plan.apply {
            if entity.deleted { records.removeValue(forKey: entity.record.id) }
            else { records[entity.record.id] = entity.record }
        }
        _ = try BackupCodec.snapshot(householdID: household.id, records: Array(records.values))
        try verifyGlobalIDs(Array(records.values), householdID: household.id)
        try commit(notifyDelivery: !plan.apply.isEmpty, allowReadOnly: true) {
            for entity in plan.apply { try applyEntity(entity) }
            try storeBaselines(remote, conflicts: plan.conflicts)
            configuration.changeToken = token
            configuration.readOnly = !writable; configuration.recovery = false
        }
    }

    func acknowledgeCloudWrites(_ saved: [RemoteHouseholdRecord], completed: Bool) throws {
        try commit(notifyDelivery: false, allowReadOnly: true) {
            try storeBaselines(saved, conflicts: [])
            if completed { syncConfiguration?.lastSyncedAt = .now }
        }
    }

    func markCloudRecovery() throws {
        guard syncConfiguration?.recovery != true else { return }
        try commit(notifyDelivery: false, allowReadOnly: true) { syncConfiguration?.recovery = true }
    }

    func resolveCloudConflicts(useCloud: Bool) throws {
        let conflicted = syncBaselines.filter(\.conflict)
        let values = try conflicted.map { try JSONDecoder().decode(RemoteHouseholdRecord.self, from: $0.remoteData).entity }
        guard let household else { throw HouseholdSharingError.invalidData }
        if useCloud {
            var records = Dictionary(uniqueKeysWithValues: try makeBackup().records.map { ($0.id, $0) })
            for value in values {
                if value.deleted { records.removeValue(forKey: value.record.id) }
                else { records[value.record.id] = value.record }
            }
            _ = try BackupCodec.snapshot(householdID: household.id, records: Array(records.values))
        }
        try commit(allowReadOnly: true) {
            if useCloud { for value in values { try applyEntity(value) } }
            for baseline in conflicted { baseline.conflict = false }
        }
    }

    private func storeBaselines(_ records: [RemoteHouseholdRecord], conflicts: Set<UUID>) throws {
        let existing = try context.fetch(FetchDescriptor<HouseholdSyncBaseline>())
        for remote in records {
            let value = remote.entity.record
            let data = try JSONEncoder().encode(remote)
            if let baseline = existing.first(where: { $0.entityID == value.id }) {
                guard baseline.householdID == value.householdID else { throw HouseholdSharingError.invalidData }
                baseline.remoteData = data; baseline.conflict = conflicts.contains(value.id)
            } else {
                context.insert(HouseholdSyncBaseline(entityID: value.id, householdID: value.householdID, remoteData: data, conflict: conflicts.contains(value.id)))
            }
        }
    }

    private func applyEntity(_ entity: SyncEntity) throws {
        guard entity.deleted else { try BackupCodec.insert(entity.record, into: context); return }
        let id = entity.record.id
        // Parent entities are not deletable in the current app. Reject unsafe tombstones.
        switch entity.record.kind {
        case "HouseholdTask":
            if let model = tasks.first(where: { $0.id == id }) { context.delete(model) }
            for link in reminderDeliveryLinks where link.taskID == id { context.delete(link) }
        case "PurchaseEntry": if let model = purchases.first(where: { $0.id == id }) { context.delete(model) }
        case "HouseholdExpense": if let model = expenses.first(where: { $0.id == id }) { context.delete(model) }
        case "InventoryItem": if let model = inventory.first(where: { $0.id == id }) { context.delete(model) }
        case "GroceryItem": if let model = groceries.first(where: { $0.id == id }) { context.delete(model) }
        case "FamilyEvent": if let model = events.first(where: { $0.id == id }) { context.delete(model) }
        case "MealPlanEntry": if let model = meals.first(where: { $0.id == id }) { context.delete(model) }
        default: throw HouseholdSharingError.invalidData
        }
    }

    private func verifyGlobalIDs(_ incoming: [BackupRecord], householdID: UUID) throws {
        // A shared record can never overwrite a UUID belonging to another local home.
        var existing: [BackupRecord] = []
        existing += try context.fetch(FetchDescriptor<Household>()).map { try BackupCodec.record($0) }
        existing += try context.fetch(FetchDescriptor<HouseholdMember>()).map { try BackupCodec.record($0) }
        existing += try context.fetch(FetchDescriptor<FamilyEvent>()).map { try BackupCodec.record($0) }
        existing += try context.fetch(FetchDescriptor<HouseholdTask>()).map { try BackupCodec.record($0) }
        existing += try context.fetch(FetchDescriptor<ShoppingStore>()).map { try BackupCodec.record($0) }
        existing += try context.fetch(FetchDescriptor<PurchaseEntry>()).map { try BackupCodec.record($0) }
        existing += try context.fetch(FetchDescriptor<HouseholdExpense>()).map { try BackupCodec.record($0) }
        existing += try context.fetch(FetchDescriptor<InventoryItem>()).map { try BackupCodec.record($0) }
        existing += try context.fetch(FetchDescriptor<GroceryItem>()).map { try BackupCodec.record($0) }
        existing += try context.fetch(FetchDescriptor<MealPlanEntry>()).map { try BackupCodec.record($0) }
        existing += try context.fetch(FetchDescriptor<HomeFloor>()).map { try BackupCodec.record($0) }
        existing += try context.fetch(FetchDescriptor<Room>()).map { try BackupCodec.record($0) }
        existing += try context.fetch(FetchDescriptor<HomeAsset>()).map { try BackupCodec.record($0) }
        existing += try context.fetch(FetchDescriptor<Warranty>()).map { try BackupCodec.record($0) }
        existing += try context.fetch(FetchDescriptor<MaintenancePlan>()).map { try BackupCodec.record($0) }
        existing += try context.fetch(FetchDescriptor<MaintenanceHistory>()).map { try BackupCodec.record($0) }
        let byID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        guard incoming.allSatisfy({ record in
            guard let old = byID[record.id] else { return true }
            return old.householdID == householdID && old.kind == record.kind
        }) else { throw HouseholdSharingError.invalidData }
    }
}
