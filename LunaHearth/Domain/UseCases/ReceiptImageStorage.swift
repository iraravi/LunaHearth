import Foundation

protocol ReceiptImageStorage: Sendable {
    func compress(_ data: Data) async throws -> Data
    func save(_ pages: [Data], home: UUID, purchase: UUID) async throws
    func load(home: UUID, purchase: UUID) async throws -> [Data]
    func removeAll() async throws
    func remove(home: UUID, purchase: UUID) async throws
}
