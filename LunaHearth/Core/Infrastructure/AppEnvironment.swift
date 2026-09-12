import Foundation

struct AppEnvironment: Sendable {
    let cloudSync: any CloudSyncService
    let intelligence: any HouseholdIntelligenceService

    static let localOnly = AppEnvironment(
        cloudSync: LocalOnlyCloudSyncService(),
        intelligence: RuleBasedHouseholdIntelligenceService()
    )
}
