import SwiftUI

struct ExpenseEditor: View {
    var item: HouseholdExpense?
    var purchase: PurchaseEntry?
    let onSave: (String, String) -> Void
    @State private var openedHome: UUID?
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ExpenseDraft
    @State private var error: String?
    @State private var removing = false
    init(item: HouseholdExpense? = nil, currency: String? = nil, purchase: PurchaseEntry? = nil, onSave: @escaping (String, String) -> Void = { _, _ in }) {
        self.item = item; self.purchase = purchase; self.onSave = onSave
        var initial = item.map(ExpenseDraft.init) ?? ExpenseDraft()
        if item == nil, let currency { initial.currency = currency }
        if let purchase {
            initial.merchant = purchase.merchant
            initial.date = ShoppingEntryRules.date(for: purchase.day) ?? .now
            initial.category = .groceries
        }
        _draft = State(initialValue: initial)
    }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label(item == nil ? "A little detail. A clearer month." : "Purchase details", systemImage: "creditcard")
                        .font(.headline).foregroundStyle(ExpenseTheme.accent)
                }.listRowBackground(Color.clear)
                ExpenseFields(draft: $draft)
                Section {
                    Toggle("This is a refund", isOn: $draft.isRefund)
                    TextField("Notes (optional)", text: $draft.notes, axis: .vertical).lineLimit(2...5)
                } footer: { Text("The total includes tax and discounts. This record is shared with your household when iCloud sharing is enabled.") }
                if let item {
                    Section {
                        NavigationLink { PurchaseHistoryView(expenseID: item.id) } label: { Label("Purchased items", systemImage: "bag") }
                            .accessibilityIdentifier("expense.purchases")
                    }
                    if item.receiptKey != nil {
                        Section { Label("Added from a receipt", systemImage: "receipt") }
                    }
                    Section {
                        Button("Delete expense", role: .destructive) { removing = true }.accessibilityIdentifier("expense.delete")
                    } footer: { Text("Editing or deleting an expense does not change shopping or inventory.") }
                }
            }.scrollContentBackground(.hidden).background(ExpenseTheme.canvas).tint(ExpenseTheme.accent)
                .navigationTitle(item == nil ? "Add expense" : "Edit expense").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            do { try repository.saveExpense(draft, editing: item?.id, purchaseID: purchase?.purchaseID); onSave(ExpenseRules.month(draft.date), draft.currency); dismiss() }
                            catch { self.error = userFacingError(error) }
                        }.accessibilityIdentifier("expense.save")
                    }
                    ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { hideKeyboard() } }
                }
                .confirmationDialog("Delete this expense?", isPresented: $removing) {
                    Button("Delete expense", role: .destructive) {
                        guard let item else { return }
                        do { try repository.deleteExpense(item); dismiss() } catch { self.error = userFacingError(error) }
                    }
                } message: { Text("It will be removed from household reports and synced devices. Shopping and inventory stay unchanged.") }
                .onAppear { openedHome = repository.household?.id }
                .onChange(of: repository.household?.id) { _, id in if id != openedHome { dismiss() } }
                .saveError($error)
                #if DEBUG
                .modifier(UITestAppearance())
                #endif
        }
    }
    private func hideKeyboard() { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
}

struct ExpenseFields: View {
    @Binding var draft: ExpenseDraft
    var body: some View { Section("Purchase") { ExpenseFieldRows(draft: $draft) } }
}
struct ExpenseFieldRows: View {
    @Binding var draft: ExpenseDraft
    var body: some View {
        ExpenseMerchantField(merchant: $draft.merchant)
        TextField("Total amount, e.g. 12.50", text: $draft.amount).keyboardType(.decimalPad).accessibilityIdentifier("expense.amount")
        Picker("Currency", selection: $draft.currency) {
            ForEach(ExpenseRules.currencies, id: \.self) { Text($0).tag($0) }
        }.accessibilityIdentifier("expense.currency")
        DatePicker("Purchase date", selection: $draft.date, displayedComponents: .date).accessibilityIdentifier("expense.date")
        Picker("Category", selection: $draft.category) {
            ForEach(ExpenseCategory.allCases) { Label($0.rawValue, systemImage: $0.symbol).tag($0) }
        }.accessibilityIdentifier("expense.category")
    }
}
