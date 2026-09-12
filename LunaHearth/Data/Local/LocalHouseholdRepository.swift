import Foundation
import Observation
import SwiftData

@MainActor @Observable
final class LocalHouseholdRepository: HouseholdRepository {
    private let context: ModelContext
    private(set) var household: Household?
    private(set) var members: [HouseholdMember] = []
    private(set) var events: [FamilyEvent] = []
    private(set) var tasks: [HouseholdTask] = []
    private(set) var groceries: [GroceryItem] = []
    private(set) var meals: [MealPlanEntry] = []
    private(set) var floors: [HomeFloor] = []
    private(set) var rooms: [Room] = []
    private(set) var assets: [HomeAsset] = []
    private(set) var warranties: [Warranty] = []
    private(set) var maintenance: [MaintenancePlan] = []
    private(set) var history: [MaintenanceHistory] = []
    private(set) var documents: [DocumentRecord] = []

    init(container: ModelContainer) {
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    func reload() throws {
        let home = try context.fetch(FetchDescriptor<Household>(sortBy: [SortDescriptor(\.createdAt)])).first
        let id = home?.id
        // Fetch before publishing so a failed read does not leave a partially refreshed dashboard.
        let people = try context.fetch(FetchDescriptor<HouseholdMember>()).filter { $0.householdID == id }
        let schedule = try context.fetch(FetchDescriptor<FamilyEvent>()).filter { $0.householdID == id }
        let chores = try context.fetch(FetchDescriptor<HouseholdTask>()).filter { $0.householdID == id }
        let shopping = try context.fetch(FetchDescriptor<GroceryItem>()).filter { $0.householdID == id }
        let food = try context.fetch(FetchDescriptor<MealPlanEntry>()).filter { $0.householdID == id }
        let levels = try context.fetch(FetchDescriptor<HomeFloor>()).filter { $0.householdID == id }
        let spaces = try context.fetch(FetchDescriptor<Room>()).filter { $0.householdID == id }
        let items = try context.fetch(FetchDescriptor<HomeAsset>()).filter { $0.householdID == id }
        let coverage = try context.fetch(FetchDescriptor<Warranty>()).filter { $0.householdID == id }
        let plans = try context.fetch(FetchDescriptor<MaintenancePlan>()).filter { $0.householdID == id }
        let completions = try context.fetch(FetchDescriptor<MaintenanceHistory>()).filter { $0.householdID == id }
        let files = try context.fetch(FetchDescriptor<DocumentRecord>()).filter { $0.householdID == id }
        // Existing scaffold meals have only an instant. Preserve the calendar day visible on
        // this device at first upgrade, then keep the key stable across subsequent travel.
        if food.contains(where: { $0.dateKey == nil }) {
            do {
                for meal in food where meal.dateKey == nil { meal.dateKey = HouseholdDay(meal.date).key }
                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
        household = home
        members = people.sorted { $0.createdAt < $1.createdAt }
        events = schedule.sorted { $0.startAt < $1.startAt }
        tasks = chores.sorted { ($0.dueAt ?? .distantFuture) < ($1.dueAt ?? .distantFuture) }
        groceries = shopping.sorted { $0.createdAt < $1.createdAt }
        meals = food.sorted { ($0.dateKey ?? "") < ($1.dateKey ?? "") }
        floors = levels.sorted { $0.sortIndex < $1.sortIndex }
        rooms = spaces.sorted { $0.sortIndex < $1.sortIndex }
        assets = items.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        warranties = coverage.sorted { ($0.endDate ?? .distantFuture) < ($1.endDate ?? .distantFuture) }
        maintenance = plans.sorted { ($0.nextDueAt ?? .distantFuture) < ($1.nextDueAt ?? .distantFuture) }
        history = completions.sorted { $0.completedAt > $1.completedAt }
        documents = files
    }

    func makeBackup() throws -> HouseholdBackup {
        try reload()
        guard let household else { throw BackupError.invalidBackup }
        guard documents.isEmpty, rooms.allSatisfy({ $0.roomPlanAssetPath == nil }) else {
            throw BackupError.attachmentsUnsupported
        }
        var records = [try BackupCodec.record(household)]
        records += try members.map { try BackupCodec.record($0) }
        records += try events.map { try BackupCodec.record($0) }
        records += try tasks.map { try BackupCodec.record($0) }
        records += try groceries.map { try BackupCodec.record($0) }
        records += try meals.map { try BackupCodec.record($0) }
        records += try floors.map { try BackupCodec.record($0) }
        records += try rooms.map { try BackupCodec.record($0) }
        records += try assets.map { try BackupCodec.record($0) }
        records += try warranties.map { try BackupCodec.record($0) }
        records += try maintenance.map { try BackupCodec.record($0) }
        records += try history.map { try BackupCodec.record($0) }
        let backup = HouseholdBackup(version: 1, householdID: household.id, name: household.name, savedAt: .now, records: records)
        try BackupCodec.validate(backup)
        return backup
    }

    func validateBackup(_ backup: HouseholdBackup) throws { try BackupCodec.validate(backup) }

    func restoreBackup(_ backup: HouseholdBackup) throws {
        guard try context.fetchCount(FetchDescriptor<Household>()) == 0 else { throw BackupError.existingHome }
        try BackupCodec.validate(backup)
        try commit {
            for record in backup.records { try BackupCodec.insert(record, into: context) }
        }
    }

    private func commit(_ change: () throws -> Void) throws {
        do {
            try change()
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        try reload()
    }

    func createHousehold(name: String, owner: String, members: [(String, MemberRole)]) throws {
        try createHousehold(name: name, owner: owner, members: members, firstRoom: nil)
    }

    func createHousehold(name: String, owner: String, members: [(String, MemberRole)], firstRoom: String?) throws {
        let roomName = try firstRoom.map { try HouseholdRules.requiredName($0) }
        guard try context.fetchCount(FetchDescriptor<Household>()) == 0 else {
            throw HouseholdValidation.householdExists
        }
        let homeName = try HouseholdRules.requiredName(name)
        let ownerName = owner.trimmingCharacters(in: .whitespacesAndNewlines)
        if !ownerName.isEmpty { _ = try HouseholdRules.requiredName(ownerName) }
        let people = try members.map { (try HouseholdRules.requiredName($0.0), $0.1) }
        try commit {
            let home = Household(name: homeName)
            context.insert(home)
            if let roomName { context.insert(Room(householdID: home.id, name: roomName)) }
            if !ownerName.isEmpty {
                context.insert(HouseholdMember(householdID: home.id, displayName: ownerName, role: .owner))
            }
            for (name, role) in people {
                guard role == .adult || role == .child else { throw HouseholdValidation.invalidReference }
                context.insert(HouseholdMember(householdID: home.id, displayName: name, role: role))
            }
        }
    }

    func saveRoomLayout(id: UUID?, name: String, floorID: UUID?, preset: RoomPreset,
                        footprint: RoomFootprint) throws {
        let name = try HouseholdRules.requiredName(name)
        try footprint.validate()
        guard let household, floorID == nil || floors.contains(where: { $0.id == floorID }) else {
            throw LayoutError.missingRoom
        }
        if let id, !rooms.contains(where: { $0.id == id }) { throw LayoutError.missingRoom }
        let neighbors = rooms.filter { $0.id != id && $0.floorID == floorID }.compactMap(\.footprint)
        guard !neighbors.contains(where: { footprint.overlaps($0) }) else { throw LayoutError.overlap }
        try commit {
            let room: Room
            if let existing = rooms.first(where: { $0.id == id }) {
                room = existing
            } else {
                room = Room(householdID: household.id, floorID: floorID, name: name, sortIndex: rooms.count)
                context.insert(room)
            }
            room.name = name
            room.floorID = floorID
            room.layoutX = footprint.x
            room.layoutZ = footprint.z
            room.layoutWidth = footprint.width
            room.layoutDepth = footprint.depth
            room.layoutHeight = footprint.height
            room.layoutPreset = preset.rawValue
            room.modifiedAt = .now
        }
    }

    func addMember(name: String, role: MemberRole) throws {
        guard let household, role == .adult || role == .child else { throw HouseholdValidation.invalidReference }
        let name = try HouseholdRules.requiredName(name)
        try commit { context.insert(HouseholdMember(householdID: household.id, displayName: name, role: role)) }
    }

    func add(_ draft: EntryDraft) throws {
        try draft.validate()
        guard let household else { throw HouseholdValidation.invalidReference }
        if let member = draft.memberID, !members.contains(where: { $0.id == member }) {
            throw HouseholdValidation.invalidReference
        }
        if let parent = draft.parentID {
            let valid: Bool
            switch draft.kind {
            case .room: valid = floors.contains { $0.id == parent }
            case .asset: valid = rooms.contains { $0.id == parent }
            case .maintenance, .warranty: valid = assets.contains { $0.id == parent }
            default: valid = false
            }
            guard valid else { throw HouseholdValidation.invalidReference }
        }
        let id = household.id
        let title = try HouseholdRules.requiredName(draft.title)
        try commit {
            if let recordID = draft.recordID {
                try update(draft, recordID: recordID, title: title)
                return
            }
            switch draft.kind {
            case .event:
                context.insert(FamilyEvent(householdID: id, title: title, startAt: draft.date,
                                           endAt: draft.endDate, assignedMemberID: draft.memberID, notes: draft.notes))
            case .task:
                context.insert(HouseholdTask(householdID: id, title: title, dueAt: draft.hasDate ? draft.date : nil,
                                             assignedMemberID: draft.memberID))
            case .grocery:
                context.insert(GroceryItem(householdID: id, name: title, quantityText: draft.quantity))
            case .meal:
                context.insert(MealPlanEntry(householdID: id, date: draft.date, mealType: draft.mealType,
                                             title: title, notes: draft.notes))
            case .floor:
                context.insert(HomeFloor(householdID: id, name: title, sortIndex: floors.count))
            case .room:
                context.insert(Room(householdID: id, floorID: draft.parentID, name: title, sortIndex: rooms.count))
            case .asset:
                context.insert(HomeAsset(householdID: id, roomID: draft.parentID, name: title,
                                         category: draft.category, manufacturer: draft.manufacturer,
                                         modelNumber: draft.modelNumber, serialNumber: draft.serialNumber, notes: draft.notes))
            case .warranty:
                guard let assetID = draft.parentID else { throw HouseholdValidation.assetRequired }
                context.insert(Warranty(householdID: id, assetID: assetID, provider: title,
                                        endDate: draft.hasDate ? draft.date : nil, notes: draft.notes))
            case .maintenance:
                guard let assetID = draft.parentID else { throw HouseholdValidation.assetRequired }
                context.insert(MaintenancePlan(householdID: id, assetID: assetID, title: title,
                                               intervalDays: draft.repeats ? draft.intervalDays : nil,
                                               nextDueAt: draft.hasDate ? draft.date : nil,
                                               shoppingItemTemplate: draft.shoppingItem))
            }
        }
    }

    private func update(_ draft: EntryDraft, recordID: UUID, title: String) throws {
        switch draft.kind {
        case .event:
            guard let item = events.first(where: { $0.id == recordID }) else { throw HouseholdValidation.invalidReference }
            item.title = title; item.startAt = draft.date; item.endAt = draft.endDate
            item.assignedMemberID = draft.memberID; item.notes = draft.notes; item.modifiedAt = .now
        case .task:
            guard let item = tasks.first(where: { $0.id == recordID }) else { throw HouseholdValidation.invalidReference }
            item.title = title; item.dueAt = draft.hasDate ? draft.date : nil
            item.assignedMemberID = draft.memberID; item.modifiedAt = .now
        case .grocery:
            guard let item = groceries.first(where: { $0.id == recordID }) else { throw HouseholdValidation.invalidReference }
            item.name = title; item.quantityText = draft.quantity; item.modifiedAt = .now
        case .meal:
            guard let item = meals.first(where: { $0.id == recordID }) else { throw HouseholdValidation.invalidReference }
            item.title = title; item.date = draft.date; item.dateKey = HouseholdDay(draft.date).key
            item.mealType = draft.mealType; item.notes = draft.notes; item.modifiedAt = .now
        case .floor:
            guard let item = floors.first(where: { $0.id == recordID }) else { throw HouseholdValidation.invalidReference }
            item.name = title; item.modifiedAt = .now
        case .room:
            guard let item = rooms.first(where: { $0.id == recordID }) else { throw HouseholdValidation.invalidReference }
            if let footprint = item.footprint,
               rooms.contains(where: { $0.id != item.id && $0.floorID == draft.parentID && ($0.footprint.map { footprint.overlaps($0) } ?? false) }) {
                throw LayoutError.overlap
            }
            item.name = title; item.floorID = draft.parentID; item.modifiedAt = .now
        case .asset:
            guard let item = assets.first(where: { $0.id == recordID }) else { throw HouseholdValidation.invalidReference }
            item.name = title; item.roomID = draft.parentID; item.categoryRawValue = draft.category.rawValue
            item.manufacturer = draft.manufacturer; item.modelNumber = draft.modelNumber
            item.serialNumber = draft.serialNumber; item.notes = draft.notes; item.modifiedAt = .now
        case .warranty:
            guard let item = warranties.first(where: { $0.id == recordID }), let assetID = draft.parentID else { throw HouseholdValidation.invalidReference }
            item.provider = title; item.assetID = assetID; item.endDate = draft.hasDate ? draft.date : nil
            item.notes = draft.notes; item.modifiedAt = .now
        case .maintenance:
            guard let item = maintenance.first(where: { $0.id == recordID }), let assetID = draft.parentID else { throw HouseholdValidation.invalidReference }
            item.title = title; item.assetID = assetID; item.nextDueAt = draft.hasDate ? draft.date : nil
            item.intervalDays = draft.repeats ? draft.intervalDays : nil
            item.shoppingItemTemplate = draft.shoppingItem; item.modifiedAt = .now
        }
    }

    /// Hard deletion is restricted to local planning records. Shared transport is disabled.
    func deletePlanningEntry(id: UUID, kind: EntryKind) throws {
        try commit {
            switch kind {
            case .event:
                guard let item = events.first(where: { $0.id == id }) else { throw HouseholdValidation.invalidReference }
                context.delete(item)
            case .task:
                guard let item = tasks.first(where: { $0.id == id }) else { throw HouseholdValidation.invalidReference }
                context.delete(item)
            case .grocery:
                guard let item = groceries.first(where: { $0.id == id }) else { throw HouseholdValidation.invalidReference }
                context.delete(item)
            case .meal:
                guard let item = meals.first(where: { $0.id == id }) else { throw HouseholdValidation.invalidReference }
                context.delete(item)
            default: throw HouseholdValidation.invalidReference
            }
        }
    }

    func toggle(_ task: HouseholdTask) throws {
        guard tasks.contains(where: { $0.id == task.id }) else { throw HouseholdValidation.invalidReference }
        try commit { task.isCompleted.toggle(); task.modifiedAt = .now }
    }

    func toggle(_ grocery: GroceryItem) throws {
        guard groceries.contains(where: { $0.id == grocery.id }) else { throw HouseholdValidation.invalidReference }
        try commit { grocery.isCompleted.toggle(); grocery.modifiedAt = .now }
    }

    func completeMaintenance(_ plan: MaintenancePlan, at date: Date = .now, calendar: Calendar = .current) throws {
        guard maintenance.contains(where: { $0.id == plan.id }), plan.lastCompletedAt == nil || plan.nextDueAt != nil else {
            throw HouseholdValidation.invalidReference
        }
        try commit {
            plan.lastCompletedAt = date
            plan.nextDueAt = HouseholdRules.nextMaintenanceDate(after: date, intervalDays: plan.intervalDays, calendar: calendar)
            plan.modifiedAt = date
            context.insert(MaintenanceHistory(householdID: plan.householdID, planID: plan.id, completedAt: date))
        }
    }

    func addReplacementToShopping(_ plan: MaintenancePlan) throws {
        guard maintenance.contains(where: { $0.id == plan.id }) else { throw HouseholdValidation.invalidReference }
        let name = try HouseholdRules.requiredName(plan.shoppingItemTemplate ?? "")
        guard !groceries.contains(where: { !$0.isCompleted && $0.relatedAssetID == plan.assetID && $0.name == name }) else { return }
        try commit { context.insert(GroceryItem(householdID: plan.householdID, name: name, relatedAssetID: plan.assetID)) }
    }

    func move(_ asset: HomeAsset, to roomID: UUID?) throws {
        guard assets.contains(where: { $0.id == asset.id }), roomID == nil || rooms.contains(where: { $0.id == roomID }) else {
            throw HouseholdValidation.invalidReference
        }
        try commit { asset.roomID = roomID; asset.modifiedAt = .now }
    }

    func events(on day: Date, calendar: Calendar = .current) -> [FamilyEvent] {
        events.filter { HouseholdRules.eventsOverlap(start: $0.startAt, end: $0.endAt, day: day, calendar: calendar) }
    }

    func dueTasks(on day: Date, calendar: Calendar = .current) -> [HouseholdTask] {
        tasks.filter { !$0.isCompleted && HouseholdRules.isDue($0.dueAt, on: day, calendar: calendar) }
    }

    func meals(on day: Date, timeZone: TimeZone = .current) -> [MealPlanEntry] {
        meals.filter { ($0.dateKey ?? HouseholdDay($0.date, timeZone: timeZone).key) == HouseholdDay(day, timeZone: timeZone).key }
    }

    func memberName(_ id: UUID?) -> String { members.first { $0.id == id }?.displayName ?? "Family" }
    func assetName(_ id: UUID) -> String { assets.first { $0.id == id }?.name ?? "Home item" }

    #if DEBUG
    func resetLocalData() throws {
        try commit {
            try context.delete(model: MaintenanceHistory.self)
            try context.delete(model: DocumentRecord.self)
            try context.delete(model: MaintenancePlan.self)
            try context.delete(model: Warranty.self)
            try context.delete(model: HomeAsset.self)
            try context.delete(model: Room.self)
            try context.delete(model: HomeFloor.self)
            try context.delete(model: MealPlanEntry.self)
            try context.delete(model: GroceryItem.self)
            try context.delete(model: HouseholdTask.self)
            try context.delete(model: FamilyEvent.self)
            try context.delete(model: HouseholdMember.self)
            try context.delete(model: Household.self)
        }
    }
    #endif
}
