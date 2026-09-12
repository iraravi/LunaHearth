import Foundation

protocol CloudSyncService: Sendable {
    var isEnabled: Bool { get async }
    func requestEnablement() async throws
    func syncNow() async throws
}

actor LocalOnlyCloudSyncService: CloudSyncService {
    var isEnabled: Bool { false }
    func requestEnablement() async throws { }
    func syncNow() async throws { }
}
