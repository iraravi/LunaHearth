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
    @State private var deleting = false
    @State private var showExtras = false
    private let receiptStorage: any ReceiptImageStorage = LocalReceiptImages()
    private var unlinkedReceiptImageID: UUID? {
        guard let item, let receiptKey = item.receiptKey else { return nil }
        let group = ReceiptRules.groceryID(home: item.householdID, key: "purchase|" + receiptKey)
        return repository.purchases.contains(where: { $0.purchaseID == group }) ? nil : group
    }
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
                ExpenseFields(draft: $draft)
                Section {
                    DisclosureGroup("Notes & refund", isExpanded: $showExtras) {
                        Toggle("This is a refund", isOn: $draft.isRefund)
                        TextField("Notes (optional)", text: $draft.notes, axis: .vertical).lineLimit(2...5)
                    }
                } footer: { Text("The total includes tax and discounts. This record is shared with your household when iCloud sharing is enabled.") }
                if let item {
                    Section {
                        NavigationLink { PurchaseHistoryView(expenseID: item.id) } label: { Label("Purchased items", systemImage: "bag") }
                            .accessibilityIdentifier("expense.purchases")
                    }
                    if let receiptKey = item.receiptKey {
                        Section {
                            NavigationLink {
                                SavedReceiptImagesView(home: item.householdID,
                                    purchase: ReceiptRules.groceryID(home: item.householdID, key: "purchase|" + receiptKey))
                            } label: {
                                Label("Receipt image", systemImage: "receipt")
                            }.accessibilityIdentifier("expense.receiptImages")
                        } footer: {
                            Text("Saved images stay on this device. You can view or remove the copy without changing your expense.")
                        }
                    }
                    Section {
                        Button("Delete expense", role: .destructive) { removing = true }.accessibilityIdentifier("expense.delete")
                    } footer: { Text("Editing or deleting an expense does not change shopping or inventory.") }
                }
            }.disabled(deleting)
                .scrollContentBackground(.hidden).background(ExpenseTheme.canvas).tint(ExpenseTheme.accent)
                .navigationTitle(item == nil ? "Add expense" : "Edit expense").navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(deleting)
                .interactiveDismissDisabled(deleting)
                .overlay { if deleting { ProgressView("Deleting expense…") } }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(deleting) }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            do { try repository.saveExpense(draft, editing: item?.id, purchaseID: purchase?.purchaseID); onSave(ExpenseRules.month(draft.date), draft.currency); dismiss() }
                            catch { self.error = userFacingError(error) }
                        }.disabled(deleting).accessibilityIdentifier("expense.save")
                    }
                    ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { hideKeyboard() } }
                }
                .confirmationDialog("Delete this expense?", isPresented: $removing) {
                    Button("Delete expense", role: .destructive) {
                        guard item != nil, !deleting else { return }
                        deleting = true
                    }.disabled(deleting)
                } message: {
                    Text(unlinkedReceiptImageID == nil
                        ? "It will be removed from household reports and synced devices. Shopping and inventory stay unchanged."
                        : "The expense and its saved receipt image on this device will be deleted. The expense will also be removed from synced devices. Your original photo, shopping and inventory stay unchanged.")
                }
                .task(id: deleting) {
                    guard deleting, let item else { return }
                    defer { deleting = false }
                    var imageRemoved = false
                    do {
                        try Task.checkCancellation()
                        guard repository.household?.id == item.householdID else { throw HouseholdValidation.invalidReference }
                        if let imageID = unlinkedReceiptImageID {
                            try await receiptStorage.remove(home: item.householdID, purchase: imageID)
                            imageRemoved = true
                        }
                        try Task.checkCancellation()
                        guard repository.household?.id == item.householdID else { throw HouseholdValidation.invalidReference }
                        try repository.deleteExpense(item)
                        dismiss()
                    } catch is CancellationError {
                        // Dismissal or a household change leaves the expense intact for retry.
                    } catch {
                        self.error = imageRemoved
                            ? "The local receipt image was removed, but the expense could not be deleted. Please try again."
                            : "The expense could not be deleted. Its saved receipt image, if any, is unchanged. Please try again."
                    }
                }
                .onAppear { openedHome = repository.household?.id; showExtras = draft.isRefund || !draft.notes.isEmpty }
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
        VStack(alignment: .leading, spacing: 6) {
            Text("Total amount").font(.caption).foregroundStyle(.secondary)
            TextField("e.g. 12.50", text: $draft.amount).keyboardType(.decimalPad)
                .font(.title2.weight(.semibold)).accessibilityLabel("Total amount").accessibilityIdentifier("expense.amount")
        }.padding(.vertical, 4)
        Picker("Currency", selection: $draft.currency) {
            ForEach(ExpenseRules.currencies, id: \.self) { Text($0).tag($0) }
        }.accessibilityIdentifier("expense.currency")
        DatePicker("Purchase date", selection: $draft.date, displayedComponents: .date).accessibilityIdentifier("expense.date")
        Picker("Category", selection: $draft.category) {
            ForEach(ExpenseCategory.allCases) { Label($0.rawValue, systemImage: $0.symbol).tag($0) }
        }.accessibilityIdentifier("expense.category")
    }
}
