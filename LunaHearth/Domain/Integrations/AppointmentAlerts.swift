import Foundation

struct AppointmentAlert: Equatable, Sendable {
    let id: UUID
    let householdID: UUID
    let date: Date
}
protocol AppointmentAlertService: Sendable {
    func requestPermission() async throws -> Bool
    func replace(_ alerts: [AppointmentAlert]) async throws
}
