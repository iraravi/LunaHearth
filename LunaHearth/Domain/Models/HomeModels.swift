import Foundation
import SwiftData

@Model
final class HomeFloor {
    @Attribute(.unique) var id: UUID
    var householdID: UUID
    var name: String
    var sortIndex: Int
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(), householdID: UUID, name: String, sortIndex: Int = 0,
         createdAt: Date = .now, modifiedAt: Date = .now) {
        self.id = id
        self.householdID = householdID
        self.name = name
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

@Model
final class Room {
    @Attribute(.unique) var id: UUID
    var householdID: UUID
    var floorID: UUID?
    var name: String
    var sortIndex: Int
    var roomPlanAssetPath: String?
    // Optional fields preserve existing rooms during additive store migration.
    var layoutX: Double?
    var layoutZ: Double?
    var layoutWidth: Double?
    var layoutDepth: Double?
    var layoutHeight: Double?
    var layoutPreset: String?
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(), householdID: UUID, floorID: UUID? = nil, name: String,
         sortIndex: Int = 0, roomPlanAssetPath: String? = nil,
         createdAt: Date = .now, modifiedAt: Date = .now) {
        self.id = id
        self.householdID = householdID
        self.floorID = floorID
        self.name = name
        self.sortIndex = sortIndex
        self.roomPlanAssetPath = roomPlanAssetPath
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

@Model
final class HomeAsset {
    @Attribute(.unique) var id: UUID
    var householdID: UUID
    var roomID: UUID?
    var name: String
    var categoryRawValue: String
    var manufacturer: String?
    var modelNumber: String?
    var serialNumber: String?
    var purchaseDate: Date?
    var purchasePriceMinorUnits: Int?
    var currencyCode: String
    var notes: String?
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(), householdID: UUID, roomID: UUID? = nil, name: String,
         category: AssetCategory = .other, manufacturer: String? = nil,
         modelNumber: String? = nil, serialNumber: String? = nil, purchaseDate: Date? = nil,
         purchasePriceMinorUnits: Int? = nil, currencyCode: String = "USD", notes: String? = nil,
         createdAt: Date = .now, modifiedAt: Date = .now) {
        self.id = id
        self.householdID = householdID
        self.roomID = roomID
        self.name = name
        self.categoryRawValue = category.rawValue
        self.manufacturer = manufacturer
        self.modelNumber = modelNumber
        self.serialNumber = serialNumber
        self.purchaseDate = purchaseDate
        self.purchasePriceMinorUnits = purchasePriceMinorUnits
        self.currencyCode = currencyCode
        self.notes = notes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

enum AssetCategory: String, Codable, Sendable, CaseIterable {
    case appliance, electronics, furniture, hvac, plumbing, vehicle, tool, safety, other
}

@Model
final class Warranty {
    @Attribute(.unique) var id: UUID
    var householdID: UUID
    var assetID: UUID
    var provider: String?
    var startDate: Date?
    var endDate: Date?
    var policyNumber: String?
    var notes: String?
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(), householdID: UUID, assetID: UUID, provider: String? = nil,
         startDate: Date? = nil, endDate: Date? = nil, policyNumber: String? = nil,
         notes: String? = nil, createdAt: Date = .now, modifiedAt: Date = .now) {
        self.id = id
        self.householdID = householdID
        self.assetID = assetID
        self.provider = provider
        self.startDate = startDate
        self.endDate = endDate
        self.policyNumber = policyNumber
        self.notes = notes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

@Model
final class MaintenancePlan {
    @Attribute(.unique) var id: UUID
    var householdID: UUID
    var assetID: UUID
    var title: String
    var intervalDays: Int?
    var lastCompletedAt: Date?
    var nextDueAt: Date?
    var shoppingItemTemplate: String?
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(), householdID: UUID, assetID: UUID, title: String,
         intervalDays: Int? = nil, lastCompletedAt: Date? = nil, nextDueAt: Date? = nil,
         shoppingItemTemplate: String? = nil, createdAt: Date = .now, modifiedAt: Date = .now) {
        self.id = id
        self.householdID = householdID
        self.assetID = assetID
        self.title = title
        self.intervalDays = intervalDays
        self.lastCompletedAt = lastCompletedAt
        self.nextDueAt = nextDueAt
        self.shoppingItemTemplate = shoppingItemTemplate
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

@Model
final class DocumentRecord {
    @Attribute(.unique) var id: UUID
    var householdID: UUID
    var assetID: UUID?
    var title: String
    var kindRawValue: String
    var localRelativePath: String
    var sha256: String?
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(), householdID: UUID, assetID: UUID? = nil, title: String,
         kind: DocumentKind, localRelativePath: String, sha256: String? = nil,
         createdAt: Date = .now, modifiedAt: Date = .now) {
        self.id = id
        self.householdID = householdID
        self.assetID = assetID
        self.title = title
        self.kindRawValue = kind.rawValue
        self.localRelativePath = localRelativePath
        self.sha256 = sha256
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

enum DocumentKind: String, Codable, Sendable, CaseIterable {
    case receipt, warranty, manual, insurance, registration, school, other
}

@Model
final class MaintenanceHistory {
    @Attribute(.unique) var id: UUID
    var householdID: UUID
    var planID: UUID
    var completedAt: Date
    var createdAt: Date
    var modifiedAt: Date

    init(householdID: UUID, planID: UUID, completedAt: Date) {
        self.id = UUID()
        self.householdID = householdID
        self.planID = planID
        self.completedAt = completedAt
        self.createdAt = completedAt
        self.modifiedAt = completedAt
    }
}
