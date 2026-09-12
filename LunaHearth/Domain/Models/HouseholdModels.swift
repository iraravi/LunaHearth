import Foundation
import SwiftData

@Model
final class Household {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(), name: String, createdAt: Date = .now, modifiedAt: Date = .now) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

@Model
final class HouseholdMember {
    @Attribute(.unique) var id: UUID
    var householdID: UUID
    var displayName: String
    var roleRawValue: String
    var colorToken: String
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(), householdID: UUID, displayName: String, role: MemberRole = .adult,
         colorToken: String = "blue", createdAt: Date = .now, modifiedAt: Date = .now) {
        self.id = id
        self.householdID = householdID
        self.displayName = displayName
        self.roleRawValue = role.rawValue
        self.colorToken = colorToken
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    var role: MemberRole {
        get { MemberRole(rawValue: roleRawValue) ?? .adult }
        set { roleRawValue = newValue.rawValue }
    }
}

enum MemberRole: String, Codable, Sendable, CaseIterable {
    case owner, adult, child, guest
}
