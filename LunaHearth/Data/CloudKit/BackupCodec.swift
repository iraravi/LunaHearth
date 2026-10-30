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
    @MainActor func insert(into context: ModelContext) throws {
        let targetID = id
        let model = try context.fetch(FetchDescriptor<Household>(predicate: #Predicate { $0.id == targetID })).first ?? Household(name: name)
        model.id = id
        model.name = name
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        if model.modelContext == nil { context.insert(model) }
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
    @MainActor func insert(into context: ModelContext) throws {
        let targetID = id
        let model = try context.fetch(FetchDescriptor<HouseholdMember>(predicate: #Predicate { $0.id == targetID })).first ?? HouseholdMember(householdID: householdID, displayName: displayName)
        model.id = id
        model.householdID = householdID
        model.displayName = displayName
        model.roleRawValue = roleRawValue
        model.colorToken = colorToken
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        if model.modelContext == nil { context.insert(model) }
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
    @MainActor func insert(into context: ModelContext) throws {
        let targetID = id
        let model = try context.fetch(FetchDescriptor<HomeFloor>(predicate: #Predicate { $0.id == targetID })).first ?? HomeFloor(householdID: householdID, name: name)
        model.id = id
        model.householdID = householdID
        model.name = name
        model.sortIndex = sortIndex
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        if model.modelContext == nil { context.insert(model) }
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
    @MainActor func insert(into context: ModelContext) throws {
        let targetID = id
        let model = try context.fetch(FetchDescriptor<Room>(predicate: #Predicate { $0.id == targetID })).first ?? Room(householdID: householdID, name: name)
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
        if model.modelContext == nil { context.insert(model) }
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
    @MainActor func insert(into context: ModelContext) throws {
        let targetID = id
        let model = try context.fetch(FetchDescriptor<HomeAsset>(predicate: #Predicate { $0.id == targetID })).first ?? HomeAsset(householdID: householdID, name: name)
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
        if model.modelContext == nil { context.insert(model) }
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
    @MainActor func insert(into context: ModelContext) throws {
        let targetID = id
        let model = try context.fetch(FetchDescriptor<Warranty>(predicate: #Predicate { $0.id == targetID })).first ?? Warranty(householdID: householdID, assetID: assetID)
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
        if model.modelContext == nil { context.insert(model) }
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
    @MainActor func insert(into context: ModelContext) throws {
        let targetID = id
        let model = try context.fetch(FetchDescriptor<MaintenancePlan>(predicate: #Predicate { $0.id == targetID })).first ?? MaintenancePlan(householdID: householdID, assetID: assetID, title: title)
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
        if model.modelContext == nil { context.insert(model) }
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
    @MainActor func insert(into context: ModelContext) throws {
        let targetID = id
        let model = try context.fetch(FetchDescriptor<MaintenanceHistory>(predicate: #Predicate { $0.id == targetID })).first ?? MaintenanceHistory(householdID: householdID, planID: planID, completedAt: completedAt)
        model.id = id
        model.householdID = householdID
        model.planID = planID
        model.completedAt = completedAt
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        if model.modelContext == nil { context.insert(model) }
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
    let appointmentKind: String?
    let reminderMinutes: Int?
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
        appointmentKind = model.appointmentKind
        reminderMinutes = model.reminderMinutes
        sourceRawValue = model.sourceRawValue
        createdAt = model.createdAt
        modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) throws {
        let targetID = id
        let model = try context.fetch(FetchDescriptor<FamilyEvent>(predicate: #Predicate { $0.id == targetID })).first ?? FamilyEvent(householdID: householdID, title: title, startAt: startAt, endAt: endAt)
        model.id = id
        model.householdID = householdID
        model.title = title
        model.startAt = startAt
        model.endAt = endAt
        model.assignedMemberID = assignedMemberID
        model.notes = notes
        model.appointmentKind = appointmentKind.flatMap { AppointmentKind(rawValue: $0)?.rawValue }
        model.reminderMinutes = reminderMinutes.flatMap { AppointmentRules.reminderChoices.contains($0) ? $0 : nil }
        model.sourceRawValue = sourceRawValue
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        if model.modelContext == nil { context.insert(model) }
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
    let mealID: UUID?
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
        mealID = model.mealID
        createdAt = model.createdAt
        modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) throws {
        let targetID = id
        let model = try context.fetch(FetchDescriptor<HouseholdTask>(predicate: #Predicate { $0.id == targetID })).first ?? HouseholdTask(householdID: householdID, title: title)
        model.id = id
        model.householdID = householdID
        model.title = title
        model.dueAt = dueAt
        model.assignedMemberID = assignedMemberID
        model.isCompleted = isCompleted
        model.recurrenceRule = recurrenceRule
        model.relatedAssetID = relatedAssetID
        model.mealID = mealID
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        if model.modelContext == nil { context.insert(model) }
    }
}
private struct ShoppingStoreBackupValue: Codable, Sendable {
    let id: UUID
    let householdID: UUID
    let name: String
    let branch: String?
    let createdAt: Date
    let modifiedAt: Date
    @MainActor init(_ model: ShoppingStore) {
        id = model.id; householdID = model.householdID; name = model.name; branch = model.branch
        createdAt = model.createdAt; modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) throws {
        let targetID = id
        let model = try context.fetch(FetchDescriptor<ShoppingStore>(predicate: #Predicate { $0.id == targetID })).first ?? ShoppingStore(id: id, householdID: householdID, name: name)
        model.name = name; model.branch = branch; model.createdAt = createdAt; model.modifiedAt = modifiedAt
        if model.modelContext == nil { context.insert(model) }
    }
}
private struct HouseholdExpenseBackupValue: Codable, Sendable {
    let id: UUID
    let householdID: UUID
    let merchant: String
    let day: String
    let amountMinorUnits: Int
    let currencyCode: String
    let categoryRawValue: String
    let isRefund: Bool
    let notes: String?
    let receiptKey: String?
    let createdAt: Date
    let modifiedAt: Date
    @MainActor init(_ model: HouseholdExpense) {
        id = model.id; householdID = model.householdID; merchant = model.merchant; day = model.day
        amountMinorUnits = model.amountMinorUnits; currencyCode = model.currencyCode
        categoryRawValue = model.categoryRawValue; isRefund = model.isRefund; notes = model.notes
        receiptKey = model.receiptKey; createdAt = model.createdAt; modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) throws {
        let targetID = id
        let model = try context.fetch(FetchDescriptor<HouseholdExpense>(predicate: #Predicate { $0.id == targetID })).first
            ?? HouseholdExpense(id: id, householdID: householdID, merchant: merchant, day: day,
                amountMinorUnits: amountMinorUnits, currencyCode: currencyCode, categoryRawValue: categoryRawValue)
        model.merchant = merchant; model.day = day; model.amountMinorUnits = amountMinorUnits
        model.currencyCode = currencyCode; model.categoryRawValue = categoryRawValue; model.isRefund = isRefund
        model.notes = notes; model.receiptKey = receiptKey; model.createdAt = createdAt; model.modifiedAt = modifiedAt
        if model.modelContext == nil { context.insert(model) }
    }
}

private struct GroceryItemBackupValue: Codable, Sendable {
    let id: UUID
    let householdID: UUID
    let name: String
    let quantityText: String?
    let quantityAmount: String?
    let quantityUnit: String?
    let plannedDay: String?
    let neededLater: Bool?
    let storeName: String?
    let storeID: UUID?
    let assignedMemberID: UUID?
    let category: String?
    let purchaseDisposition: String?
    let receiptImportKey: String?
    let isCompleted: Bool
    let relatedAssetID: UUID?
    let createdAt: Date
    let modifiedAt: Date
    @MainActor init(_ model: GroceryItem) {
        id = model.id
        householdID = model.householdID
        name = model.name
        quantityText = model.quantityText
        quantityAmount = model.quantityAmount; quantityUnit = model.quantityUnit; plannedDay = model.plannedDay
        storeName = model.storeName
        storeID = model.storeID
        neededLater = model.neededLater
        assignedMemberID = model.assignedMemberID
        category = model.category
        purchaseDisposition = model.purchaseDisposition
        receiptImportKey = model.receiptImportKey
        isCompleted = model.isCompleted
        relatedAssetID = model.relatedAssetID
        createdAt = model.createdAt
        modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) throws {
        let targetID = id
        let model = try context.fetch(FetchDescriptor<GroceryItem>(predicate: #Predicate { $0.id == targetID })).first ?? GroceryItem(householdID: householdID, name: name)
        model.id = id
        model.householdID = householdID
        model.name = name
        model.quantityText = quantityText
        model.quantityAmount = quantityAmount; model.quantityUnit = quantityUnit; model.plannedDay = plannedDay
        model.storeName = storeName
        model.storeID = storeID
        model.neededLater = neededLater
        model.assignedMemberID = assignedMemberID
        model.category = category
        model.purchaseDisposition = purchaseDisposition
        model.receiptImportKey = receiptImportKey
        model.isCompleted = isCompleted
        model.relatedAssetID = relatedAssetID
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        if model.modelContext == nil { context.insert(model) }
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
    let ingredientNames: [String]?
    let ingredientAmountsPerServing: [String: String]?
    let preparationSteps: [String]?
    let servings: Int?
    let cookedAt: Date?
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
        ingredientAmountsPerServing = model.ingredientAmountsPerServing; ingredientNames = model.ingredientNames; preparationSteps = model.preparationSteps; servings = model.servings; cookedAt = model.cookedAt
        createdAt = model.createdAt
        modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) throws {
        let targetID = id
        let model = try context.fetch(FetchDescriptor<MealPlanEntry>(predicate: #Predicate { $0.id == targetID })).first ?? MealPlanEntry(householdID: householdID, date: date, mealType: mealType, title: title)
        model.id = id
        model.householdID = householdID
        model.date = date
        model.dateKey = dateKey
        model.mealType = mealType
        model.title = title
        model.notes = notes
        model.ingredientAmountsPerServing = ingredientAmountsPerServing; model.ingredientNames = ingredientNames; model.preparationSteps = preparationSteps; model.servings = servings; model.cookedAt = cookedAt
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        if model.modelContext == nil { context.insert(model) }
    }
}

private struct InventoryItemBackupValue: Codable, Sendable {
    let id: UUID
    let householdID: UUID
    let name: String
    let quantityText: String?
    let packDetails: String?
    let storeName: String?
    let storeID: UUID?
    let location: String?
    let packedDay: String?
    let expiryDay: String?
    let purchasedDay: String?
    let sourceGroceryID: UUID?
    let isLowStock: Bool?
    let isUsedUp: Bool
    let createdAt: Date
    let modifiedAt: Date
    @MainActor init(_ model: InventoryItem) {
        id = model.id
        householdID = model.householdID
        name = model.name
        quantityText = model.quantityText
        packDetails = model.packDetails
        storeName = model.storeName
        storeID = model.storeID
        location = model.location
        packedDay = model.packedDay
        expiryDay = model.expiryDay
        purchasedDay = model.purchasedDay
        sourceGroceryID = model.sourceGroceryID
        isLowStock = model.isLowStock
        isUsedUp = model.isUsedUp
        createdAt = model.createdAt
        modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) throws {
        let targetID = id
        let model = try context.fetch(FetchDescriptor<InventoryItem>(predicate: #Predicate { $0.id == targetID })).first ?? InventoryItem(id: id, householdID: householdID, name: name)
        model.id = id
        model.householdID = householdID
        model.name = name
        model.quantityText = quantityText
        model.packDetails = packDetails
        model.storeName = storeName
        model.storeID = storeID
        model.location = location
        model.packedDay = packedDay
        model.expiryDay = expiryDay
        model.purchasedDay = purchasedDay
        model.sourceGroceryID = sourceGroceryID
        model.isLowStock = isLowStock
        model.isUsedUp = isUsedUp
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        if model.modelContext == nil { context.insert(model) }
    }
}

@MainActor enum BackupCodec {
    static func record(_ model: InventoryItem) throws -> BackupRecord {
        BackupRecord(id: model.id, householdID: model.householdID, kind: "InventoryItem", createdAt: model.createdAt, modifiedAt: model.modifiedAt, payload: try encode(InventoryItemBackupValue(model)))
    }
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
    static func record(_ model: ShoppingStore) throws -> BackupRecord {
        BackupRecord(id: model.id, householdID: model.householdID, kind: "ShoppingStore", createdAt: model.createdAt, modifiedAt: model.modifiedAt, payload: try encode(ShoppingStoreBackupValue(model)))
    }
    static func record(_ model: PurchaseEntry) throws -> BackupRecord {
        BackupRecord(id: model.id, householdID: model.householdID, kind: "PurchaseEntry", createdAt: model.createdAt, modifiedAt: model.modifiedAt, payload: try encode(PurchaseEntryBackupValue(model)))
    }
    static func record(_ model: HouseholdExpense) throws -> BackupRecord {
        BackupRecord(id: model.id, householdID: model.householdID, kind: "HouseholdExpense", createdAt: model.createdAt, modifiedAt: model.modifiedAt, payload: try encode(HouseholdExpenseBackupValue(model)))
    }
    static func record(_ model: GroceryItem) throws -> BackupRecord {
        BackupRecord(id: model.id, householdID: model.householdID, kind: "GroceryItem", createdAt: model.createdAt, modifiedAt: model.modifiedAt, payload: try encode(GroceryItemBackupValue(model)))
    }
    static func record(_ model: MealPlanEntry) throws -> BackupRecord {
        BackupRecord(id: model.id, householdID: model.householdID, kind: "MealPlanEntry", createdAt: model.createdAt, modifiedAt: model.modifiedAt, payload: try encode(MealPlanEntryBackupValue(model)))
    }
    static func snapshot(householdID: UUID, records: [BackupRecord]) throws -> HouseholdBackup {
        guard let home = records.first(where: { $0.id == householdID && $0.kind == "Household" }) else { throw BackupError.invalidBackup }
        let name = try JSONDecoder().decode(HouseholdBackupValue.self, from: home.payload).name
        let snapshot = HouseholdBackup(version: 1, householdID: householdID, name: name, savedAt: .now, records: records)
        try validate(snapshot)
        return snapshot
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
                    guard !placedRooms.contains(where: { $0.0 == value.floorID && $0.1.overlaps(footprint) }) else { throw LayoutError.overlap }
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
                // Imported/shared events must obey the same ordering rule as local entry.
                guard value.startAt.timeIntervalSince1970.isFinite,
                      value.endAt.timeIntervalSince1970.isFinite,
                      value.endAt > value.startAt else { throw BackupError.invalidBackup }
                _ = try HouseholdRules.requiredName(value.title)
                guard value.id == record.id, value.householdID == backup.householdID, abs(value.createdAt.timeIntervalSince(record.createdAt)) < 0.002, abs(value.modifiedAt.timeIntervalSince(record.modifiedAt)) < 0.002 else { throw BackupError.invalidBackup }
                try reference(value.assignedMemberID, "HouseholdMember")
            case "HouseholdTask":
                let value = try JSONDecoder().decode(HouseholdTaskBackupValue.self, from: record.payload)
                guard value.id == record.id, value.householdID == backup.householdID, abs(value.createdAt.timeIntervalSince(record.createdAt)) < 0.002, abs(value.modifiedAt.timeIntervalSince(record.modifiedAt)) < 0.002 else { throw BackupError.invalidBackup }
                try reference(value.assignedMemberID, "HouseholdMember")
                try reference(value.relatedAssetID, "HomeAsset")
                if let mealID = value.mealID, let kind = kinds[mealID], kind != "MealPlanEntry" { throw BackupError.invalidBackup }
            case "ShoppingStore":
                let value = try JSONDecoder().decode(ShoppingStoreBackupValue.self, from: record.payload)
                guard value.id == record.id, value.householdID == backup.householdID,
                      abs(value.createdAt.timeIntervalSince(record.createdAt)) < 0.002,
                      abs(value.modifiedAt.timeIntervalSince(record.modifiedAt)) < 0.002 else { throw BackupError.invalidBackup }
                _ = try HouseholdRules.requiredName(value.name)
                _ = try HouseholdRules.requiredName(ShoppingStore.label(name: value.name, branch: value.branch))
            case "InventoryItem":
                let value = try JSONDecoder().decode(InventoryItemBackupValue.self, from: record.payload)
                guard value.id == record.id, value.householdID == backup.householdID,
                      abs(value.createdAt.timeIntervalSince(record.createdAt)) < 0.002,
                      abs(value.modifiedAt.timeIntervalSince(record.modifiedAt)) < 0.002 else { throw BackupError.invalidBackup }
                _ = try HouseholdRules.requiredName(value.name)
                guard [value.quantityText, value.packDetails, value.storeName, value.location].allSatisfy({ ($0?.count ?? 0) <= 200 }) else { throw BackupError.invalidBackup }
                for day in [value.packedDay, value.expiryDay, value.purchasedDay].compactMap({ $0 }) {
                    guard ShoppingEntryRules.date(for: day) != nil else { throw BackupError.invalidBackup }
                }
                if let packed = value.packedDay, let expiry = value.expiryDay, expiry < packed { throw BackupError.invalidBackup }
                try reference(value.storeID, "ShoppingStore")
                if let source = value.sourceGroceryID {
                    guard value.id == InventoryRules.purchaseID(householdID: value.householdID, groceryID: source),
                          kinds[source] == nil || kinds[source] == "GroceryItem" else { throw BackupError.invalidBackup }
                }
            case "PurchaseEntry":
                let value = try JSONDecoder().decode(PurchaseEntryBackupValue.self, from: record.payload)
                guard value.id == record.id, value.householdID == backup.householdID,
                      abs(value.createdAt.timeIntervalSince(record.createdAt)) < 0.002,
                      abs(value.modifiedAt.timeIntervalSince(record.modifiedAt)) < 0.002,
                      !value.name.isEmpty, value.name.count <= 200, value.quantity.count <= 200, value.merchant.count <= 200,
                      ShoppingEntryRules.date(for: value.day) != nil,
                      ["added", "restocked", "elsewhere"].contains(value.stockAction) else { throw BackupError.invalidBackup }
                if let amount = value.amountMinorUnits {
                    guard amount > 0, amount <= 999_999_999_900, let currency = value.currencyCode,
                          ExpenseRules.currencies.contains(currency) else { throw BackupError.invalidBackup }
                }
                if let key = value.receiptLineKey {
                    guard key.count == 64, key.allSatisfy({ $0.isHexDigit }) else { throw BackupError.invalidBackup }
                }
                // Historical links survive deletion; any still-present target must have the correct kind.
                for (id, kind) in [(value.expenseID, "HouseholdExpense"), (value.groceryID, "GroceryItem"), (value.inventoryID, "InventoryItem")] {
                    if let id, let present = kinds[id], present != kind { throw BackupError.invalidBackup }
                }
            case "HouseholdExpense":
                let value = try JSONDecoder().decode(HouseholdExpenseBackupValue.self, from: record.payload)
                guard value.id == record.id, value.householdID == backup.householdID,
                      abs(value.createdAt.timeIntervalSince(record.createdAt)) < 0.002,
                      abs(value.modifiedAt.timeIntervalSince(record.modifiedAt)) < 0.002,
                      !value.merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, value.merchant.count <= 200,
                      value.amountMinorUnits > 0, value.amountMinorUnits <= 999_999_999_900,
                      ExpenseRules.currencies.contains(value.currencyCode), ExpenseCategory(rawValue: value.categoryRawValue) != nil,
                      ShoppingEntryRules.date(for: value.day) != nil, (value.notes?.count ?? 0) <= 1_000 else { throw BackupError.invalidBackup }
                if let key = value.receiptKey {
                    guard key.count == 64, key.allSatisfy({ $0.isHexDigit }) else { throw BackupError.invalidBackup }
                }
            case "GroceryItem":
                let value = try JSONDecoder().decode(GroceryItemBackupValue.self, from: record.payload)
                guard value.purchaseDisposition == nil || ["inventory", "elsewhere"].contains(value.purchaseDisposition ?? "") else { throw BackupError.invalidBackup }
                try reference(value.storeID, "ShoppingStore")
                if let day = value.plannedDay, ShoppingEntryRules.date(for: day) == nil { throw BackupError.invalidBackup }
                if let key = value.receiptImportKey {
                    guard key.count == 64, key.allSatisfy({ $0.isHexDigit }) else { throw BackupError.invalidBackup }
                }
                if let amount = value.quantityAmount {
                    guard let rawUnit = value.quantityUnit, let unit = ShoppingUnit(rawValue: rawUnit) else { throw BackupError.invalidBackup }
                    _ = try ShoppingEntryRules.amount(amount, unit: unit)
                } else if value.quantityUnit != nil { throw BackupError.invalidBackup }
                guard value.id == record.id, value.householdID == backup.householdID, abs(value.createdAt.timeIntervalSince(record.createdAt)) < 0.002, abs(value.modifiedAt.timeIntervalSince(record.modifiedAt)) < 0.002 else { throw BackupError.invalidBackup }
                try reference(value.assignedMemberID, "HouseholdMember")
                try reference(value.relatedAssetID, "HomeAsset")
            case "MealPlanEntry":
                let value = try JSONDecoder().decode(MealPlanEntryBackupValue.self, from: record.payload)
                if let day = value.dateKey, ShoppingEntryRules.date(for: day) == nil {
                    throw BackupError.invalidBackup
                }
                try WeeklyMealRules.validateAmounts(value.ingredientAmountsPerServing ?? [:], names: value.ingredientNames ?? [])
                try MealCookingRules.validate(servings: value.servings ?? 2, ingredients: value.ingredientNames ?? [], steps: value.preparationSteps ?? [])
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
        case "ShoppingStore": try JSONDecoder().decode(ShoppingStoreBackupValue.self, from: record.payload).insert(into: context)
        case "InventoryItem": try JSONDecoder().decode(InventoryItemBackupValue.self, from: record.payload).insert(into: context)
        case "PurchaseEntry": try JSONDecoder().decode(PurchaseEntryBackupValue.self, from: record.payload).insert(into: context)
        case "HouseholdExpense": try JSONDecoder().decode(HouseholdExpenseBackupValue.self, from: record.payload).insert(into: context)
        case "GroceryItem": try JSONDecoder().decode(GroceryItemBackupValue.self, from: record.payload).insert(into: context)
        case "MealPlanEntry": try JSONDecoder().decode(MealPlanEntryBackupValue.self, from: record.payload).insert(into: context)
        default: throw BackupError.invalidBackup
        }
    }
}

private struct PurchaseEntryBackupValue: Codable, Sendable {
    let id: UUID
    let householdID: UUID
    let purchaseID: UUID
    let expenseID: UUID?
    let groceryID: UUID?
    let inventoryID: UUID?
    let name: String
    let quantity: String
    let merchant: String
    let day: String
    let amountMinorUnits: Int?
    let currencyCode: String?
    let stockAction: String
    let receiptLineKey: String?
    let createdAt: Date
    let modifiedAt: Date
    @MainActor init(_ model: PurchaseEntry) {
        id = model.id
        householdID = model.householdID
        purchaseID = model.purchaseID
        expenseID = model.expenseID
        groceryID = model.groceryID
        inventoryID = model.inventoryID
        name = model.name
        quantity = model.quantity
        merchant = model.merchant
        day = model.day
        amountMinorUnits = model.amountMinorUnits
        currencyCode = model.currencyCode
        stockAction = model.stockAction
        receiptLineKey = model.receiptLineKey
        createdAt = model.createdAt
        modifiedAt = model.modifiedAt
    }
    @MainActor func insert(into context: ModelContext) throws {
        let targetID = id
        let model = try context.fetch(FetchDescriptor<PurchaseEntry>(predicate: #Predicate { $0.id == targetID })).first
            ?? PurchaseEntry(id: id, householdID: householdID, purchaseID: purchaseID, name: name, quantity: quantity, merchant: merchant, day: day, stockAction: stockAction)
        model.householdID = householdID
        model.purchaseID = purchaseID
        model.expenseID = expenseID
        model.groceryID = groceryID
        model.inventoryID = inventoryID
        model.name = name
        model.quantity = quantity
        model.merchant = merchant
        model.day = day
        model.amountMinorUnits = amountMinorUnits
        model.currencyCode = currencyCode
        model.stockAction = stockAction
        model.receiptLineKey = receiptLineKey
        model.createdAt = createdAt
        model.modifiedAt = modifiedAt
        if model.modelContext == nil { context.insert(model) }
    }
}
