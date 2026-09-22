import Foundation

extension LocalHouseholdRepository {
    func receiptPurchaseCandidates(name: String, day: String) -> [ReceiptPurchaseCandidate] {
        ReceiptPurchaseMatching.candidates(name: name, day: day, purchases: purchases.map { entry in
            ReceiptPurchaseCandidate(id: entry.id, name: entry.name, quantity: entry.quantity,
                merchant: entry.merchant, day: entry.day,
                alreadyLinked: entry.receiptLineKey != nil || entry.expenseID != nil || groceries.contains { grocery in
                    grocery.id == entry.groceryID && grocery.receiptImportKey != nil
                })
        })
    }
    func receiptLineImported(_ key: String) -> Bool {
        groceries.contains { $0.receiptImportKey == key } || purchases.contains {
            $0.receiptLineKey == key || $0.id == ReceiptRules.groceryID(home: $0.householdID, key: "purchase-line|" + key)
        }
    }
}
