import Foundation
import SwiftData

// Versioned, per-entity backup values. Device-local file paths are never transported.
private struct HouseholdBackupValue: Codable, Sendable {
    let id: UUID
    let name: String
    let createdAt: Date
    let modifiedAt: Date
    @MainActor init(_ model: Household) {
        id = model.id
        name = model.name
        createdAt = model.createdAt
        modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) {
        let model = Household(name: name)
        model.id = id
        model.name = name
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        context.insert(model)
    }
}
private struct HouseholdMemberBackupValue: Codable, Sendable {
    let id: UUID
    let householdID: UUID
    let displayName: String
    let roleRawValue: String
    let colorToken: String
    let createdAt: Date
    let modifiedAt: Date
    @MainActor init(_ model: HouseholdMember) {
        id = model.id
        householdID = model.householdID
        displayName = model.displayName
        roleRawValue = model.roleRawValue
        colorToken = model.colorToken
        createdAt = model.createdAt
        modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) {
        let model = HouseholdMember(householdID: householdID, displayName: displayName)
        model.id = id
        model.householdID = householdID
        model.displayName = displayName
        model.roleRawValue = roleRawValue
        model.colorToken = colorToken
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        context.insert(model)
    }
}
private struct HomeFloorBackupValue: Codable, Sendable {
    let id: UUID
    let householdID: UUID
    let name: String
    let sortIndex: Int
    let createdAt: Date
    let modifiedAt: Date
    @MainActor init(_ model: HomeFloor) {
        id = model.id
        householdID = model.householdID
        name = model.name
        sortIndex = model.sortIndex
        createdAt = model.createdAt
        modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) {
        let model = HomeFloor(householdID: householdID, name: name)
        model.id = id
        model.householdID = householdID
        model.name = name
        model.sortIndex = sortIndex
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        context.insert(model)
    }
}
private struct RoomBackupValue: Codable, Sendable {
    let id: UUID
    let householdID: UUID
    let floorID: UUID?
    let name: String
    let sortIndex: Int
    let layoutX: Double?
    let layoutZ: Double?
    let layoutWidth: Double?
    let layoutDepth: Double?
    let layoutHeight: Double?
    let layoutPreset: String?
    let createdAt: Date
    let modifiedAt: Date
    @MainActor init(_ model: Room) {
        id = model.id
        householdID = model.householdID
        floorID = model.floorID
        name = model.name
        sortIndex = model.sortIndex
        layoutX = model.layoutX
        layoutZ = model.layoutZ
        layoutWidth = model.layoutWidth
        layoutDepth = model.layoutDepth
        layoutHeight = model.layoutHeight
        layoutPreset = model.layoutPreset
        createdAt = model.createdAt
        modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) {
        let model = Room(householdID: householdID, name: name)
        model.id = id
        model.householdID = householdID
        model.floorID = floorID
        model.name = name
        model.sortIndex = sortIndex
        model.layoutX = layoutX
        model.layoutZ = layoutZ
        model.layoutWidth = layoutWidth
        model.layoutDepth = layoutDepth
        model.layoutHeight = layoutHeight
        model.layoutPreset = layoutPreset
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        context.insert(model)
    }
}
private struct HomeAssetBackupValue: Codable, Sendable {
    let id: UUID
    let householdID: UUID
    let roomID: UUID?
    let name: String
    let categoryRawValue: String
    let manufacturer: String?
    let modelNumber: String?
    let serialNumber: String?
    let purchaseDate: Date?
    let purchasePriceMinorUnits: Int?
    let currencyCode: String
    let notes: String?
    let createdAt: Date
    let modifiedAt: Date
    @MainActor init(_ model: HomeAsset) {
        id = model.id
        householdID = model.householdID
        roomID = model.roomID
        name = model.name
        categoryRawValue = model.categoryRawValue
        manufacturer = model.manufacturer
        modelNumber = model.modelNumber
        serialNumber = model.serialNumber
        purchaseDate = model.purchaseDate
        purchasePriceMinorUnits = model.purchasePriceMinorUnits
        currencyCode = model.currencyCode
        notes = model.notes
        createdAt = model.createdAt
        modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) {
        let model = HomeAsset(householdID: householdID, name: name)
        model.id = id
        model.householdID = householdID
        model.roomID = roomID
        model.name = name
        model.categoryRawValue = categoryRawValue
        model.manufacturer = manufacturer
        model.modelNumber = modelNumber
        model.serialNumber = serialNumber
        model.purchaseDate = purchaseDate
        model.purchasePriceMinorUnits = purchasePriceMinorUnits
        model.currencyCode = currencyCode
        model.notes = notes
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        context.insert(model)
    }
}
private struct WarrantyBackupValue: Codable, Sendable {
    let id: UUID
    let householdID: UUID
    let assetID: UUID
    let provider: String?
    let startDate: Date?
    let endDate: Date?
    let policyNumber: String?
    let notes: String?
    let createdAt: Date
    let modifiedAt: Date
    @MainActor init(_ model: Warranty) {
        id = model.id
        householdID = model.householdID
        assetID = model.assetID
        provider = model.provider
        startDate = model.startDate
        endDate = model.endDate
        policyNumber = model.policyNumber
        notes = model.notes
        createdAt = model.createdAt
        modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) {
        let model = Warranty(householdID: householdID, assetID: assetID)
        model.id = id
        model.householdID = householdID
        model.assetID = assetID
        model.provider = provider
        model.startDate = startDate
        model.endDate = endDate
        model.policyNumber = policyNumber
        model.notes = notes
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        context.insert(model)
    }
}
private struct MaintenancePlanBackupValue: Codable, Sendable {
    let id: UUID
    let householdID: UUID
    let assetID: UUID
    let title: String
    let intervalDays: Int?
    let lastCompletedAt: Date?
    let nextDueAt: Date?
    let shoppingItemTemplate: String?
    let createdAt: Date
    let modifiedAt: Date
    @MainActor init(_ model: MaintenancePlan) {
        id = model.id
        householdID = model.householdID
        assetID = model.assetID
        title = model.title
        intervalDays = model.intervalDays
        lastCompletedAt = model.lastCompletedAt
        nextDueAt = model.nextDueAt
        shoppingItemTemplate = model.shoppingItemTemplate
        createdAt = model.createdAt
        modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) {
        let model = MaintenancePlan(householdID: householdID, assetID: assetID, title: title)
        model.id = id
        model.householdID = householdID
        model.assetID = assetID
        model.title = title
        model.intervalDays = intervalDays
        model.lastCompletedAt = lastCompletedAt
        model.nextDueAt = nextDueAt
        model.shoppingItemTemplate = shoppingItemTemplate
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        context.insert(model)
    }
}
private struct MaintenanceHistoryBackupValue: Codable, Sendable {
    let id: UUID
    let householdID: UUID
    let planID: UUID
    let completedAt: Date
    let createdAt: Date
    let modifiedAt: Date
    @MainActor init(_ model: MaintenanceHistory) {
        id = model.id
        householdID = model.householdID
        planID = model.planID
        completedAt = model.completedAt
        createdAt = model.createdAt
        modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) {
        let model = MaintenanceHistory(householdID: householdID, planID: planID, completedAt: completedAt)
        model.id = id
        model.householdID = householdID
        model.planID = planID
        model.completedAt = completedAt
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        context.insert(model)
    }
}
private struct FamilyEventBackupValue: Codable, Sendable {
    let id: UUID
    let householdID: UUID
    let title: String
    let startAt: Date
    let endAt: Date
    let assignedMemberID: UUID?
    let notes: String?
    let sourceRawValue: String
    let createdAt: Date
    let modifiedAt: Date
    @MainActor init(_ model: FamilyEvent) {
        id = model.id
        householdID = model.householdID
        title = model.title
        startAt = model.startAt
        endAt = model.endAt
        assignedMemberID = model.assignedMemberID
        notes = model.notes
        sourceRawValue = model.sourceRawValue
        createdAt = model.createdAt
        modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) {
        let model = FamilyEvent(householdID: householdID, title: title, startAt: startAt, endAt: endAt)
        model.id = id
        model.householdID = householdID
        model.title = title
        model.startAt = startAt
        model.endAt = endAt
        model.assignedMemberID = assignedMemberID
        model.notes = notes
        model.sourceRawValue = sourceRawValue
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        context.insert(model)
    }
}
private struct HouseholdTaskBackupValue: Codable, Sendable {
    let id: UUID
    let householdID: UUID
    let title: String
    let dueAt: Date?
    let assignedMemberID: UUID?
    let isCompleted: Bool
    let recurrenceRule: String?
    let relatedAssetID: UUID?
    let createdAt: Date
    let modifiedAt: Date
    @MainActor init(_ model: HouseholdTask) {
        id = model.id
        householdID = model.householdID
        title = model.title
        dueAt = model.dueAt
        assignedMemberID = model.assignedMemberID
        isCompleted = model.isCompleted
        recurrenceRule = model.recurrenceRule
        relatedAssetID = model.relatedAssetID
        createdAt = model.createdAt
        modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) {
        let model = HouseholdTask(householdID: householdID, title: title)
        model.id = id
        model.householdID = householdID
        model.title = title
        model.dueAt = dueAt
        model.assignedMemberID = assignedMemberID
        model.isCompleted = isCompleted
        model.recurrenceRule = recurrenceRule
        model.relatedAssetID = relatedAssetID
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        context.insert(model)
    }
}
private struct GroceryItemBackupValue: Codable, Sendable {
    let id: UUID
    let householdID: UUID
    let name: String
    let quantityText: String?
    let category: String?
    let isCompleted: Bool
    let relatedAssetID: UUID?
    let createdAt: Date
    let modifiedAt: Date
    @MainActor init(_ model: GroceryItem) {
        id = model.id
        householdID = model.householdID
        name = model.name
        quantityText = model.quantityText
        category = model.category
        isCompleted = model.isCompleted
        relatedAssetID = model.relatedAssetID
        createdAt = model.createdAt
        modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) {
        let model = GroceryItem(householdID: householdID, name: name)
        model.id = id
        model.householdID = householdID
        model.name = name
        model.quantityText = quantityText
        model.category = category
        model.isCompleted = isCompleted
        model.relatedAssetID = relatedAssetID
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        context.insert(model)
    }
}
private struct MealPlanEntryBackupValue: Codable, Sendable {
    let id: UUID
    let householdID: UUID
    let date: Date
    let dateKey: String?
    let mealType: String
    let title: String
    let notes: String?
    let createdAt: Date
    let modifiedAt: Date
    @MainActor init(_ model: MealPlanEntry) {
        id = model.id
        householdID = model.householdID
        date = model.date
        dateKey = model.dateKey
        mealType = model.mealType
        title = model.title
        notes = model.notes
        createdAt = model.createdAt
        modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) {
        let model = MealPlanEntry(householdID: householdID, date: date, mealType: mealType, title: title)
        model.id = id
        model.householdID = householdID
        model.date = date
        model.dateKey = dateKey
        model.mealType = mealType
        model.title = title
        model.notes = notes
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        context.insert(model)
    }
}

@MainActor enum BackupCodec {
    private static func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try encoder.encode(value)
    }
    static func record(_ model: Household) throws -> BackupRecord {
        BackupRecord(id: model.id, householdID: model.id, kind: "Household", createdAt: model.createdAt, modifiedAt: model.modifiedAt, payload: try encode(HouseholdBackupValue(model)))
    }
    static func record(_ model: HouseholdMember) throws -> BackupRecord {
        BackupRecord(id: model.id, householdID: model.householdID, kind: "HouseholdMember", createdAt: model.createdAt, modifiedAt: model.modifiedAt, payload: try encode(HouseholdMemberBackupValue(model)))
    }
    static func record(_ model: HomeFloor) throws -> BackupRecord {
        BackupRecord(id: model.id, householdID: model.householdID, kind: "HomeFloor", createdAt: model.createdAt, modifiedAt: model.modifiedAt, payload: try encode(HomeFloorBackupValue(model)))
    }
    static func record(_ model: Room) throws -> BackupRecord {
        BackupRecord(id: model.id, householdID: model.householdID, kind: "Room", createdAt: model.createdAt, modifiedAt: model.modifiedAt, payload: try encode(RoomBackupValue(model)))
    }
    static func record(_ model: HomeAsset) throws -> BackupRecord {
        BackupRecord(id: model.id, householdID: model.householdID, kind: "HomeAsset", createdAt: model.createdAt, modifiedAt: model.modifiedAt, payload: try encode(HomeAssetBackupValue(model)))
    }
    static func record(_ model: Warranty) throws -> BackupRecord {
        BackupRecord(id: model.id, householdID: model.householdID, kind: "Warranty", createdAt: model.createdAt, modifiedAt: model.modifiedAt, payload: try encode(WarrantyBackupValue(model)))
    }
    static func record(_ model: MaintenancePlan) throws -> BackupRecord {
        BackupRecord(id: model.id, householdID: model.householdID, kind: "MaintenancePlan", createdAt: model.createdAt, modifiedAt: model.modifiedAt, payload: try encode(MaintenancePlanBackupValue(model)))
    }
    static func record(_ model: MaintenanceHistory) throws -> BackupRecord {
        BackupRecord(id: model.id, householdID: model.householdID, kind: "MaintenanceHistory", createdAt: model.createdAt, modifiedAt: model.modifiedAt, payload: try encode(MaintenanceHistoryBackupValue(model)))
    }
    static func record(_ model: FamilyEvent) throws -> BackupRecord {
        BackupRecord(id: model.id, householdID: model.householdID, kind: "FamilyEvent", createdAt: model.createdAt, modifiedAt: model.modifiedAt, payload: try encode(FamilyEventBackupValue(model)))
    }
    static func record(_ model: HouseholdTask) throws -> BackupRecord {
        BackupRecord(id: model.id, householdID: model.householdID, kind: "HouseholdTask", createdAt: model.createdAt, modifiedAt: model.modifiedAt, payload: try encode(HouseholdTaskBackupValue(model)))
    }
    static func record(_ model: GroceryItem) throws -> BackupRecord {
        BackupRecord(id: model.id, householdID: model.householdID, kind: "GroceryItem", createdAt: model.createdAt, modifiedAt: model.modifiedAt, payload: try encode(GroceryItemBackupValue(model)))
    }
    static func record(_ model: MealPlanEntry) throws -> BackupRecord {
        BackupRecord(id: model.id, householdID: model.householdID, kind: "MealPlanEntry", createdAt: model.createdAt, modifiedAt: model.modifiedAt, payload: try encode(MealPlanEntryBackupValue(model)))
    }
    static func validate(_ backup: HouseholdBackup) throws {
        try backup.validateEnvelope()
        let kinds = Dictionary(uniqueKeysWithValues: backup.records.map { ($0.id, $0.kind) })
        func reference(_ id: UUID?, _ kind: String) throws {
            if let id, kinds[id] != kind { throw BackupError.invalidBackup }
        }
        var placedRooms: [(UUID?, RoomFootprint)] = []
        for record in backup.records {
            switch record.kind {
            case "Household":
                let value = try JSONDecoder().decode(HouseholdBackupValue.self, from: record.payload)
                guard value.name == backup.name else { throw BackupError.invalidBackup }
                guard value.id == record.id, value.id == backup.householdID, abs(value.createdAt.timeIntervalSince(record.createdAt)) < 0.002, abs(value.modifiedAt.timeIntervalSince(record.modifiedAt)) < 0.002 else { throw BackupError.invalidBackup }
            case "HouseholdMember":
                let value = try JSONDecoder().decode(HouseholdMemberBackupValue.self, from: record.payload)
                guard value.id == record.id, value.householdID == backup.householdID, abs(value.createdAt.timeIntervalSince(record.createdAt)) < 0.002, abs(value.modifiedAt.timeIntervalSince(record.modifiedAt)) < 0.002 else { throw BackupError.invalidBackup }
            case "HomeFloor":
                let value = try JSONDecoder().decode(HomeFloorBackupValue.self, from: record.payload)
                guard value.id == record.id, value.householdID == backup.householdID, abs(value.createdAt.timeIntervalSince(record.createdAt)) < 0.002, abs(value.modifiedAt.timeIntervalSince(record.modifiedAt)) < 0.002 else { throw BackupError.invalidBackup }
            case "Room":
                let value = try JSONDecoder().decode(RoomBackupValue.self, from: record.payload)
                guard value.id == record.id, value.householdID == backup.householdID, abs(value.createdAt.timeIntervalSince(record.createdAt)) < 0.002, abs(value.modifiedAt.timeIntervalSince(record.modifiedAt)) < 0.002 else { throw BackupError.invalidBackup }
                try reference(value.floorID, "HomeFloor")
                let geometry = [value.layoutX, value.layoutZ, value.layoutWidth, value.layoutDepth, value.layoutHeight]
                guard geometry.allSatisfy({ $0 == nil }) || (geometry.allSatisfy({ $0?.isFinite == true }) && (value.layoutWidth ?? 0) > 0 && (value.layoutDepth ?? 0) > 0 && (value.layoutHeight ?? 0) > 0) else { throw BackupError.invalidBackup }
                if let x = value.layoutX, let z = value.layoutZ, let width = value.layoutWidth,
                   let depth = value.layoutDepth, let height = value.layoutHeight {
                    let footprint = RoomFootprint(x: x, z: z, width: width, depth: depth, height: height)
                    try footprint.validate()
                    guard !placedRooms.contains(where: { $0.0 == value.floorID && $0.1.overlaps(footprint) }) else { throw BackupError.invalidBackup }
                    placedRooms.append((value.floorID, footprint))
                }
            case "HomeAsset":
                let value = try JSONDecoder().decode(HomeAssetBackupValue.self, from: record.payload)
                guard value.id == record.id, value.householdID == backup.householdID, abs(value.createdAt.timeIntervalSince(record.createdAt)) < 0.002, abs(value.modifiedAt.timeIntervalSince(record.modifiedAt)) < 0.002 else { throw BackupError.invalidBackup }
                try reference(value.roomID, "Room")
            case "Warranty":
                let value = try JSONDecoder().decode(WarrantyBackupValue.self, from: record.payload)
                guard value.id == record.id, value.householdID == backup.householdID, abs(value.createdAt.timeIntervalSince(record.createdAt)) < 0.002, abs(value.modifiedAt.timeIntervalSince(record.modifiedAt)) < 0.002 else { throw BackupError.invalidBackup }
                try reference(value.assetID, "HomeAsset")
            case "MaintenancePlan":
                let value = try JSONDecoder().decode(MaintenancePlanBackupValue.self, from: record.payload)
                guard value.id == record.id, value.householdID == backup.householdID, abs(value.createdAt.timeIntervalSince(record.createdAt)) < 0.002, abs(value.modifiedAt.timeIntervalSince(record.modifiedAt)) < 0.002 else { throw BackupError.invalidBackup }
                try reference(value.assetID, "HomeAsset")
            case "MaintenanceHistory":
                let value = try JSONDecoder().decode(MaintenanceHistoryBackupValue.self, from: record.payload)
                guard value.id == record.id, value.householdID == backup.householdID, abs(value.createdAt.timeIntervalSince(record.createdAt)) < 0.002, abs(value.modifiedAt.timeIntervalSince(record.modifiedAt)) < 0.002 else { throw BackupError.invalidBackup }
                try reference(value.planID, "MaintenancePlan")
            case "FamilyEvent":
                let value = try JSONDecoder().decode(FamilyEventBackupValue.self, from: record.payload)
                guard value.id == record.id, value.householdID == backup.householdID, abs(value.createdAt.timeIntervalSince(record.createdAt)) < 0.002, abs(value.modifiedAt.timeIntervalSince(record.modifiedAt)) < 0.002 else { throw BackupError.invalidBackup }
                try reference(value.assignedMemberID, "HouseholdMember")
            case "HouseholdTask":
                let value = try JSONDecoder().decode(HouseholdTaskBackupValue.self, from: record.payload)
                guard value.id == record.id, value.householdID == backup.householdID, abs(value.createdAt.timeIntervalSince(record.createdAt)) < 0.002, abs(value.modifiedAt.timeIntervalSince(record.modifiedAt)) < 0.002 else { throw BackupError.invalidBackup }
                try reference(value.assignedMemberID, "HouseholdMember")
                try reference(value.relatedAssetID, "HomeAsset")
            case "GroceryItem":
                let value = try JSONDecoder().decode(GroceryItemBackupValue.self, from: record.payload)
                guard value.id == record.id, value.householdID == backup.householdID, abs(value.createdAt.timeIntervalSince(record.createdAt)) < 0.002, abs(value.modifiedAt.timeIntervalSince(record.modifiedAt)) < 0.002 else { throw BackupError.invalidBackup }
                try reference(value.relatedAssetID, "HomeAsset")
            case "MealPlanEntry":
                let value = try JSONDecoder().decode(MealPlanEntryBackupValue.self, from: record.payload)
                guard value.id == record.id, value.householdID == backup.householdID, abs(value.createdAt.timeIntervalSince(record.createdAt)) < 0.002, abs(value.modifiedAt.timeIntervalSince(record.modifiedAt)) < 0.002 else { throw BackupError.invalidBackup }
            default: throw BackupError.invalidBackup
            }
        }
    }
    static func insert(_ record: BackupRecord, into context: ModelContext) throws {
        switch record.kind {
        case "Household": try JSONDecoder().decode(HouseholdBackupValue.self, from: record.payload).insert(into: context)
        case "HouseholdMember": try JSONDecoder().decode(HouseholdMemberBackupValue.self, from: record.payload).insert(into: context)
        case "HomeFloor": try JSONDecoder().decode(HomeFloorBackupValue.self, from: record.payload).insert(into: context)
        case "Room": try JSONDecoder().decode(RoomBackupValue.self, from: record.payload).insert(into: context)
        case "HomeAsset": try JSONDecoder().decode(HomeAssetBackupValue.self, from: record.payload).insert(into: context)
        case "Warranty": try JSONDecoder().decode(WarrantyBackupValue.self, from: record.payload).insert(into: context)
        case "MaintenancePlan": try JSONDecoder().decode(MaintenancePlanBackupValue.self, from: record.payload).insert(into: context)
        case "MaintenanceHistory": try JSONDecoder().decode(MaintenanceHistoryBackupValue.self, from: record.payload).insert(into: context)
        case "FamilyEvent": try JSONDecoder().decode(FamilyEventBackupValue.self, from: record.payload).insert(into: context)
        case "HouseholdTask": try JSONDecoder().decode(HouseholdTaskBackupValue.self, from: record.payload).insert(into: context)
        case "GroceryItem": try JSONDecoder().decode(GroceryItemBackupValue.self, from: record.payload).insert(into: context)
        case "MealPlanEntry": try JSONDecoder().decode(MealPlanEntryBackupValue.self, from: record.payload).insert(into: context)
        default: throw BackupError.invalidBackup
        }
    }
}
