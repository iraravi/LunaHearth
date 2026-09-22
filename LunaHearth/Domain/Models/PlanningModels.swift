import Foundation
import SwiftData

@Model
final class FamilyEvent {
    @Attribute(.unique) var id: UUID
    var householdID: UUID
    var title: String
    var startAt: Date
    var endAt: Date
    var assignedMemberID: UUID?
    var notes: String?
    var appointmentKind: String? = nil
    var reminderMinutes: Int? = nil
    var sourceRawValue: String
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(), householdID: UUID, title: String, startAt: Date, endAt: Date,
         assignedMemberID: UUID? = nil, notes: String? = nil, source: EventSource = .lunaHearth,
         createdAt: Date = .now, modifiedAt: Date = .now) {
        self.id = id
        self.householdID = householdID
        self.title = title
        self.startAt = startAt
        self.endAt = endAt
        self.assignedMemberID = assignedMemberID
        self.notes = notes
        self.sourceRawValue = source.rawValue
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

enum EventSource: String, Codable, Sendable { case lunaHearth, appleCalendar }

@Model
final class HouseholdTask {
    @Attribute(.unique) var id: UUID
    var householdID: UUID
    var title: String
    var dueAt: Date?
    var assignedMemberID: UUID?
    var isCompleted: Bool
    var recurrenceRule: String?
    var relatedAssetID: UUID?
    var mealID: UUID? = nil
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(), householdID: UUID, title: String, dueAt: Date? = nil,
         assignedMemberID: UUID? = nil, isCompleted: Bool = false, recurrenceRule: String? = nil,
         relatedAssetID: UUID? = nil, createdAt: Date = .now, modifiedAt: Date = .now) {
        self.id = id
        self.householdID = householdID
        self.title = title
        self.dueAt = dueAt
        self.assignedMemberID = assignedMemberID
        self.isCompleted = isCompleted
        self.recurrenceRule = recurrenceRule
        self.relatedAssetID = relatedAssetID
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

@Model
final class GroceryItem {
    @Attribute(.unique) var id: UUID
    var householdID: UUID
    var name: String
    var quantityText: String?
    var quantityAmount: String? = nil
    var quantityUnit: String? = nil
    var plannedDay: String? = nil
    var neededLater: Bool?
    var storeName: String?
    var storeID: UUID? = nil
    var assignedMemberID: UUID?
    var category: String?
    var purchaseDisposition: String? = nil
    var receiptImportKey: String? = nil
    var isCompleted: Bool
    var relatedAssetID: UUID?
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(), householdID: UUID, name: String, quantityText: String? = nil,
         storeName: String? = nil, storeID: UUID? = nil, neededLater: Bool? = nil, assignedMemberID: UUID? = nil, category: String? = nil, isCompleted: Bool = false, relatedAssetID: UUID? = nil,
         createdAt: Date = .now, modifiedAt: Date = .now) {
        self.id = id
        self.householdID = householdID
        self.name = name
        self.quantityText = quantityText
        self.storeName = storeName
        self.storeID = storeID
        self.neededLater = neededLater
        self.assignedMemberID = assignedMemberID
        self.category = category
        self.isCompleted = isCompleted
        self.relatedAssetID = relatedAssetID
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

@Model
final class MealPlanEntry {
    @Attribute(.unique) var id: UUID
    var householdID: UUID
    var date: Date
    var dateKey: String? = nil
    var mealType: String
    var title: String
    var notes: String?
    var ingredientNames: [String]? = nil
    var ingredientAmountsPerServing: [String: String]? = nil
    var preparationSteps: [String]? = nil
    var servings: Int? = nil
    var cookedAt: Date? = nil
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(), householdID: UUID, date: Date, mealType: String, title: String,
         notes: String? = nil, createdAt: Date = .now, modifiedAt: Date = .now) {
        self.id = id
        self.householdID = householdID
        self.date = date
        self.dateKey = HouseholdDay(date).key
        self.mealType = mealType
        self.title = title
        self.notes = notes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
