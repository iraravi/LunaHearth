import CloudKit
import Foundation

actor CloudKitPublicConfigurationService: PublicConfigurationFetching {
    func fetch() async throws -> PublicAppConfiguration {
        let database = CKContainer(identifier: "iCloud.com.neuralluna.lunahearth").publicCloudDatabase
        // Fixed ID: no queries, user identifiers, subscriptions, or public writes.
        let record = try await database.record(for: CKRecord.ID(recordName: "ios-current"))
        guard record.recordType == "LHAppConfiguration",
              let payload = record["payload"] as? String,
              let data = payload.data(using: .utf8), data.count <= 32_768 else {
            throw ConfigurationError.invalid
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(PublicAppConfiguration.self, from: data)
    }
}
