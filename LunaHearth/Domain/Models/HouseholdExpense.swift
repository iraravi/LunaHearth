import Foundation
import SwiftData

@Model final class HouseholdExpense {
    @Attribute(.unique) var id: UUID
    var householdID: UUID
    var merchant: String
    var day: String
    var amountMinorUnits: Int
    var currencyCode: String
    var categoryRawValue: String
    var isRefund: Bool
    var notes: String?
    var receiptKey: String?
    var createdAt: Date
    var modifiedAt: Date
    init(id: UUID = UUID(), householdID: UUID, merchant: String, day: String, amountMinorUnits: Int,
         currencyCode: String, categoryRawValue: String, isRefund: Bool = false, createdAt: Date = .now) {
        self.id = id; self.householdID = householdID; self.merchant = merchant; self.day = day
        self.amountMinorUnits = amountMinorUnits; self.currencyCode = currencyCode
        self.categoryRawValue = categoryRawValue; self.isRefund = isRefund
        self.createdAt = createdAt; self.modifiedAt = createdAt
    }
}
