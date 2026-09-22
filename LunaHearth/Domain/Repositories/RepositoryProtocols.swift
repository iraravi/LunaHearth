import Foundation

/// Local model instances remain on the main actor with their SwiftData context.
@MainActor
protocol HouseholdRepository: AnyObject {
    func reload() throws
    func createHousehold(name: String, owner: String, members: [(String, MemberRole)]) throws
    @discardableResult func addStore(name: String, branch: String) throws -> ShoppingStore
    func add(_ draft: EntryDraft) throws
    func completeMaintenance(_ plan: MaintenancePlan, at date: Date, calendar: Calendar) throws
}
