import Foundation
import SwiftData

extension LocalHouseholdRepository {
    /// Validate the complete review before a single local transaction; failed reviews save nothing.
    @discardableResult func importReceipt(_ lines: [ReceiptLine], householdID: UUID, storeName: String, expense: ExpenseDraft? = nil, receiptKey: String? = nil) throws -> Int {
        try FeatureAccess.require(.receiptImport)
        if expense != nil { try FeatureAccess.require(.receiptExpenses) }
        if lines.contains(where: { $0.included && $0.addToInventory && $0.existingPurchaseID == nil }) { try FeatureAccess.require(.receiptPantry) }
        guard household?.id == householdID else { throw HouseholdValidation.invalidReference }
        let selected = lines.filter(\.included)
        guard (!selected.isEmpty || expense != nil), selected.count <= 150 else { throw ReceiptImportError.noSelection }
        guard storeName.count <= 200 else { throw InventoryError.longDetail }
        guard Set(selected.map(\.id)).count == selected.count else { throw ReceiptImportError.changedMatch }
        let pending = groceries.filter { !$0.isCompleted && $0.purchaseDisposition != "inventory" && $0.receiptImportKey == nil }
        let active = inventory.filter { InventoryRules.canRestock(isUsedUp: $0.isUsedUp, expiryDay: $0.expiryDay) }
        let fresh = selected.filter { line in
            !receiptLineImported(line.id)
        }
        for (index, line) in fresh.enumerated() {
            guard !fresh.prefix(index).contains(where: { IngredientMatching.same($0.name, line.name) }) else { throw ReceiptImportError.duplicateLine }
        }
        var claimed = Set<UUID>()
        var claimedPurchases = Set<UUID>()
        for line in fresh {
            _ = try HouseholdRules.requiredName(line.name)
            if !line.amount.isEmpty {
                guard expense != nil else { throw ReceiptImportError.changedMatch }
                _ = try ExpenseRules.minorUnits(line.amount)
            }
            guard line.quantity.count <= 200, line.id.count == 64,
                  line.id.allSatisfy({ $0.isHexDigit }) else { throw InventoryError.longDetail }
            let candidates = receiptPurchaseCandidates(name: line.name, day: HouseholdDay(expense?.date ?? .now).key)
            if let id = line.existingPurchaseID {
                guard let candidate = candidates.first(where: { $0.id == id }), claimedPurchases.insert(id).inserted else { throw ReceiptImportError.changedMatch }
                guard !candidate.alreadyLinked else { throw ReceiptImportError.alreadyExpensed }
                // An existing purchase's count, disposition and expiry are historical decisions.
                // Linking a receipt must not repeat or alter them, even if its pack was consumed/deleted.
                continue
            }
            guard candidates.isEmpty || line.confirmedNewPurchase else { throw ReceiptImportError.reviewPurchase }
            if let id = line.groceryID {
                guard pending.contains(where: { $0.id == id && IngredientMatching.same($0.name, line.name) }), claimed.insert(id).inserted else { throw ReceiptImportError.changedMatch }
            }
            if let day = line.expiryDay {
                guard ShoppingEntryRules.date(for: day) != nil else { throw InventoryError.invalidDateOrder }
                if let id = line.inventoryID, let packed = active.first(where: { $0.id == id })?.packedDay, day < packed { throw InventoryError.invalidDateOrder }
            }
            if line.addToInventory {
                let matches = active.filter { IngredientMatching.same($0.name, line.name) }
                if let id = line.inventoryID {
                    guard matches.contains(where: { $0.id == id }) else { throw ReceiptImportError.changedMatch }
                } else if !matches.isEmpty { throw InventoryError.duplicateIngredient }
            }
        }
        let groupID = ReceiptRules.groceryID(home: householdID, key: "purchase|" + (receiptKey ?? selected.first?.id ?? ""))
        let historicalExpense = expenses.first { expense in purchases.contains { $0.purchaseID == groupID && $0.expenseID == expense.id } }
        var newExpense: HouseholdExpense?
        if let expense {
            try ExpenseRules.validate(expense)
            guard let receiptKey, receiptKey.count == 64, receiptKey.allSatisfy({ $0.isHexDigit }) else { throw ReceiptImportError.changedMatch }
            if historicalExpense == nil && !expenses.contains(where: { $0.receiptKey == receiptKey }) {
                let record = HouseholdExpense(id: ReceiptRules.groceryID(home: householdID, key: "purchase-expense|" + groupID.uuidString),
                    householdID: householdID, merchant: expense.merchant, day: HouseholdDay(expense.date).key,
                    amountMinorUnits: try ExpenseRules.minorUnits(expense.amount), currencyCode: expense.currency, categoryRawValue: expense.category.rawValue)
                record.receiptKey = receiptKey
                newExpense = record
            }
        }
        guard !fresh.isEmpty || newExpense != nil else { return 0 }
        let linkedExpenseID = newExpense?.id ?? historicalExpense?.id ?? expenses.first(where: { $0.receiptKey == receiptKey && receiptKey != nil })?.id
        try commit {
            if let newExpense, let expense { try applyExpense(expense, to: newExpense); context.insert(newExpense) }
            if let linkedExpenseID {
                for entry in purchases where entry.purchaseID == groupID && entry.expenseID != linkedExpenseID {
                    entry.expenseID = linkedExpenseID; entry.modifiedAt = .now
                }
            }
            let store = try resolveStore(storeName, householdID: householdID)
            var availableInventory = active
            for line in fresh {
                if let id = line.existingPurchaseID, let entry = purchases.first(where: { $0.id == id }) {
                    entry.receiptLineKey = line.id
                    entry.purchaseID = groupID
                    entry.expenseID = linkedExpenseID
                    if !line.amount.isEmpty {
                        entry.amountMinorUnits = try ExpenseRules.minorUnits(line.amount)
                        entry.currencyCode = expense?.currency
                    }
                    entry.modifiedAt = .now
                    if let grocery = groceries.first(where: { $0.id == entry.groceryID }) {
                        grocery.receiptImportKey = line.id; grocery.modifiedAt = .now
                    }
                    continue
                }
                let grocery = line.groceryID.flatMap { id in pending.first { $0.id == id } }
                    ?? GroceryItem(id: ReceiptRules.groceryID(home: householdID, key: line.id), householdID: householdID, name: line.name)
                // Keep assignments and the original shopping name for explicitly linked items.
                if grocery.modelContext == nil { context.insert(grocery) }
                if !line.quantity.isEmpty {
                    grocery.quantityText = line.quantity; grocery.quantityAmount = nil; grocery.quantityUnit = nil
                }
                if let store { grocery.storeID = store.id; grocery.storeName = store.displayName }
                grocery.receiptImportKey = line.id
                grocery.isCompleted = true
                grocery.purchaseDisposition = line.addToInventory ? "inventory" : "elsewhere"
                grocery.modifiedAt = .now
                var stockedID: UUID?
                var stockAction = "elsewhere"
                if line.addToInventory {
                    let match = line.inventoryID.flatMap { id in availableInventory.first { $0.id == id } }
                        ?? availableInventory.first { IngredientMatching.same($0.name, line.name) }
                    if let match {
                        stockedID = match.id; stockAction = "restocked"
                        if let quantity = RestockQuantity.combined(existing: match.quantityText, purchased: line.quantity) { match.quantityText = quantity }
                        if let day = line.expiryDay { match.expiryDay = day }
                        match.isLowStock = false; match.modifiedAt = .now
                    } else {
                        let item = InventoryItem(id: InventoryRules.purchaseID(householdID: householdID, groceryID: grocery.id), householdID: householdID, name: line.name)
                        item.expiryDay = line.expiryDay
                        item.quantityText = InventoryRules.optional(line.quantity)
                        item.storeID = store?.id; item.storeName = store?.displayName
                        item.sourceGroceryID = grocery.id; item.purchasedDay = HouseholdDay(expense?.date ?? .now).key
                        context.insert(item); availableInventory.append(item)
                        stockedID = item.id; stockAction = "added"
                    }
                }
                appendPurchase(id: ReceiptRules.groceryID(home: householdID, key: "purchase-line|" + line.id),
                    purchaseID: groupID, grocery: grocery, inventoryID: stockedID, expenseID: linkedExpenseID,
                    day: HouseholdDay(expense?.date ?? .now).key, action: stockAction,
                    amount: line.amount.isEmpty ? nil : try ExpenseRules.minorUnits(line.amount), currency: expense?.currency)
            }
        }
        return fresh.count
    }
}
