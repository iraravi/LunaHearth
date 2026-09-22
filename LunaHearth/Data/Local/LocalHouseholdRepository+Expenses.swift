import Foundation
import SwiftData

extension LocalHouseholdRepository {
    var expenseReportItems: [ExpenseReportItem] {
        expenses.map { ExpenseReportItem(id: $0.id, merchant: $0.merchant, day: $0.day, amount: $0.amountMinorUnits,
            currency: $0.currencyCode, category: ExpenseCategory(rawValue: $0.categoryRawValue) ?? .other, isRefund: $0.isRefund, notes: $0.notes ?? "") }
    }
    @discardableResult func saveExpense(_ draft: ExpenseDraft, editing id: UUID? = nil, purchaseID: UUID? = nil) throws -> UUID {
        guard let home = household?.id else { throw HouseholdValidation.invalidReference }
        try ExpenseRules.validate(draft)
        let linked = purchases.filter { $0.purchaseID == purchaseID }
        if purchaseID != nil {
            guard !linked.isEmpty, !linked.contains(where: { entry in expenses.contains { $0.id == entry.expenseID && $0.id != id } }) else { throw HouseholdValidation.invalidReference }
        }
        let existing = id.flatMap { id in expenses.first { $0.id == id } }
        guard id == nil || existing != nil else { throw HouseholdValidation.invalidReference }
        let amount = try ExpenseRules.minorUnits(draft.amount)
        let item = existing ?? HouseholdExpense(id: purchaseID.map { ReceiptRules.groceryID(home: home, key: "purchase-expense|" + $0.uuidString) } ?? UUID(), householdID: home, merchant: draft.merchant, day: HouseholdDay(draft.date).key,
            amountMinorUnits: amount, currencyCode: draft.currency, categoryRawValue: draft.category.rawValue)
        try commit { try applyExpense(draft, to: item); if existing == nil { context.insert(item) }
            for entry in linked { entry.expenseID = item.id; entry.modifiedAt = .now }
        }
        return item.id
    }
    func applyExpense(_ draft: ExpenseDraft, to item: HouseholdExpense) throws {
        try ExpenseRules.validate(draft)
        item.merchant = ShoppingStoreCatalog.canonicalName(draft.merchant, saved: shoppingStoreNames)
        item.day = HouseholdDay(draft.date).key; item.amountMinorUnits = try ExpenseRules.minorUnits(draft.amount)
        item.currencyCode = draft.currency; item.categoryRawValue = draft.category.rawValue
        item.isRefund = draft.isRefund; item.notes = InventoryRules.optional(draft.notes); item.modifiedAt = .now
    }
    func deleteExpense(_ item: HouseholdExpense) throws {
        guard expenses.contains(where: { $0.id == item.id }) else { throw HouseholdValidation.invalidReference }
        try commit { context.delete(item) }
    }
}

extension ExpenseDraft {
    @MainActor init(_ item: HouseholdExpense) {
        merchant = item.merchant; date = ShoppingEntryRules.date(for: item.day) ?? .now
        amount = ExpenseRules.amountText(item.amountMinorUnits); currency = item.currencyCode
        category = ExpenseCategory(rawValue: item.categoryRawValue) ?? .other
        isRefund = item.isRefund; notes = item.notes ?? ""
    }
}
