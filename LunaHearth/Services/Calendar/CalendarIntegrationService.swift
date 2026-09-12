import EventKit
import Foundation

actor CalendarIntegrationService {
    private let store = EKEventStore()

    func requestFullAccessIfNeeded() async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await store.requestFullAccessToEvents()
        }
        return false
    }
}
