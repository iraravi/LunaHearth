import Foundation

extension LocalHouseholdRepository {
    /// The owner supplies names. Repeated invitations keep stable assignment IDs.
    func prepareNamedMembers(ownerName: String, recipientName: String, accountID: String) throws {
        guard let configuration = syncConfiguration, configuration.isOwner,
              !configuration.recovery, !configuration.readOnly,
              !accountID.isEmpty, accountID != configuration.accountID else { throw HouseholdSharingError.readOnly }
        let ownerName = try HouseholdRules.requiredName(ownerName)
        let recipientName = try HouseholdRules.requiredName(recipientName)
        let home = configuration.householdID
        let recipientID = SharedMemberIdentity.memberID(householdID: home, accountID: accountID)
        let ownerID = SharedMemberIdentity.memberID(householdID: home, accountID: configuration.accountID)
        let owner = members.first { $0.id == ownerID } ?? members.first { $0.role == .owner }
        let recipient = members.first { $0.id == recipientID }
        try commit {
            if let owner {
                if owner.displayName != ownerName { owner.displayName = ownerName; owner.modifiedAt = .now }
            } else {
                context.insert(HouseholdMember(id: ownerID, householdID: home, displayName: ownerName, role: .owner))
            }
            if let recipient {
                if recipient.displayName != recipientName { recipient.displayName = recipientName; recipient.modifiedAt = .now }
            } else {
                context.insert(HouseholdMember(id: recipientID, householdID: home, displayName: recipientName))
            }
        }
    }

    /// Link only the verified account of this device; never infer identity from a display name.
    @discardableResult func ensureCurrentCloudMember() throws -> Bool {
        guard let configuration = syncConfiguration, configuration.enabled,
              !configuration.recovery, !configuration.readOnly, !configuration.accountID.isEmpty else { return false }
        if linkedCloudMemberID != nil { return false }
        let id = SharedMemberIdentity.memberID(householdID: configuration.householdID, accountID: configuration.accountID)
        // A deliberately removed profile is not silently recreated.
        if syncBaselines.contains(where: { $0.entityID == id }) { return false }
        try commit {
            context.insert(HouseholdMember(id: id, householdID: configuration.householdID,
                displayName: configuration.isOwner ? "Home owner" : "Family member",
                role: configuration.isOwner ? .owner : .adult))
        }
        return true
    }

    func renameFamilyMember(_ id: UUID, name: String) throws {
        guard syncConfiguration?.isOwner != false, syncConfiguration?.readOnly != true,
              syncConfiguration?.recovery != true,
              let member = members.first(where: { $0.id == id }) else { throw HouseholdSharingError.readOnly }
        let name = try HouseholdRules.requiredName(name)
        try commit { member.displayName = name; member.modifiedAt = .now }
    }

    var linkedCloudMemberID: UUID? {
        guard let configuration = syncConfiguration, !configuration.recovery else { return nil }
        let id = SharedMemberIdentity.memberID(householdID: configuration.householdID, accountID: configuration.accountID)
        if members.contains(where: { $0.id == id }) { return id }
        if configuration.isOwner { return members.first { $0.role == .owner }?.id }
        return nil
    }
}
