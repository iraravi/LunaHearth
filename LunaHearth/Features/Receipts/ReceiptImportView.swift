import SwiftUI
import PhotosUI

struct ReceiptImportView: View {
    let householdID: UUID
    let sampleImage: Data?
    let onExpenseSaved: ((String, String) -> Void)?
    @State private var expenseDetails = false
    @State private var recordingExpense: Bool
    @State private var expenseDraft = ExpenseDraft(category: .groceries)
    init(householdID: UUID, startsWithExpense: Bool = true, sampleImage: Data? = nil, onExpenseSaved: ((String, String) -> Void)? = nil) {
        self.onExpenseSaved = onExpenseSaved
        self.householdID = householdID; self.sampleImage = sampleImage
        _recordingExpense = State(initialValue: startsWithExpense)
    }
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @State private var photos: [PhotosPickerItem] = []
    @State private var camera = false
    @State private var busy = false
    @State private var lines: [ReceiptLine] = []
    @State private var sourceText = ""
    @State private var store = ""
    @State private var error: String?
    @State private var outcome: String?
    @State private var savedPurchaseID: UUID?
    @State private var scanTask: Task<Void, Never>?
    @State private var decoding = false
    @State private var decodeTask: Task<Void, Never>?
    @State private var decodeGeneration = UUID()
    @State private var proposals: [String: ReceiptNameProposal] = [:]
    @State private var decodeMessage: String?
    private let decoder: any ReceiptNameDecodingService = OnDeviceReceiptNameService()
    private let scanner: any ReceiptScanningService = VisionReceiptScanner()
    private var selected: Int { lines.filter(\.included).count }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "receipt").font(.title)
                            .foregroundStyle(ShoppingTheme.accent).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(lines.isEmpty ? "Scan your receipt" : "Review your purchase")
                                .font(.headline)
                            Text(sourceText.isEmpty ? "Read privately on this device. Nothing saves until you review." : "Confirm the total and items before saving.")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 8)
                }.listRowBackground(Color.clear)
                if let outcome {
                    Section {
                        Label(outcome, systemImage: "checkmark.circle.fill").accessibilityIdentifier("receipt.success")
                        if let savedPurchaseID {
                            NavigationLink { PurchaseDetailView(purchaseID: savedPurchaseID) } label: { Label("View purchase", systemImage: "bag") }
                                .accessibilityIdentifier("receipt.purchaseDetails")
                        }
                        Button("Done") { dismiss() }
                    }
                } else {
                    if sourceText.isEmpty {
                        Section { scanControls } footer: {
                            Text("Use up to four pages from one receipt. Photos are not retained or uploaded by LunaHearth.")
                        }
                    }
                    if busy { Section { ProgressView("Reading your receipt…").accessibilityIdentifier("receipt.reading") } }
                    if !sourceText.isEmpty {
                        Section { ReviewSafetyNotice(context: .receipt) }
                        Section {
                            Toggle("Record in Expenses", isOn: $recordingExpense).accessibilityIdentifier("receipt.recordExpense")
                            if recordingExpense {
                                DisclosureGroup(isExpanded: $expenseDetails) {
                                    ExpenseFieldRows(draft: $expenseDraft)
                                    Text("Confirm the full total after tax and discounts. Excluding an item below does not reduce this total.")
                                        .font(.caption).foregroundStyle(.secondary)
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(expenseDraft.merchant.isEmpty ? "Receipt expense" : expenseDraft.merchant).font(.headline)
                                        Text("\(expenseDraft.currency) \(expenseDraft.amount.isEmpty ? "Enter total" : expenseDraft.amount) · \(expenseDraft.date.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.subheadline).foregroundStyle(.secondary)
                                        Text("Check date, total & currency").font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        Section("Receipt details") {
                            DisclosureGroup("Already marked this purchase bought?") {
                                Text("Recent matching purchases appear beside each receipt item. Link an existing purchase to keep its pantry amount unchanged, or confirm a new purchase.").font(.caption).foregroundStyle(.secondary)
                                NavigationLink("Open purchase history") { PurchaseHistoryView() }
                            }
                            if !recordingExpense { ExpenseMerchantField(merchant: $store, placeholder: "Store (optional)", identifier: "receipt.store") }
                            DisclosureGroup("Receipt text & rescan") {
                                scanControls
                                Text(sourceText).font(.caption).textSelection(.enabled)
                            }
                        }
                        if lines.isEmpty {
                            Section { Text("Text was found, but no priced item lines were clear. Read the original text and add a line below, or try another photo.") }
                        }
                        if !lines.isEmpty {
                            Section {
                                if decoding {
                                    ProgressView("Decoding names on this device…")
                                    Button("Cancel decoding") { cancelDecoding(); decodeMessage = "Decoding cancelled. Names stay as you reviewed them." }
                                } else {
                                    Button("Decode names with AI", systemImage: "sparkles") { decodeNames() }
                                        .frame(minHeight: 44).accessibilityIdentifier("receipt.decodeNames")
                                        .disabled(busy || !lines.contains(where: \.included))
                                }
                                Text(decodeMessage ?? "AI guesses what abbreviated labels mean and may choose the wrong product. Compare each suggestion with the receipt and packaging before using it.")
                                    .font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("receipt.decodeStatus")
                            }
                        }
                        ForEach($lines) { $line in
                            ReceiptReviewRow(line: $line, purchaseDay: HouseholdDay(recordingExpense ? expenseDraft.date : .now).key, currency: recordingExpense ? expenseDraft.currency : nil, proposal: proposals[line.id], alreadyImported: repository.receiptLineImported(line.id))
                        }
                        Section {
                            Button("Add a missed item", systemImage: "plus") {
                                lines.append(ReceiptLine(id: ReceiptRules.hash(sourceText + "|manual|\(lines.count)"), name: ""))
                            }.disabled(lines.count >= 150).accessibilityIdentifier("receipt.addLine")
                        }
                    }
                }
            }
            .contentMargins(.top, 8, for: .scrollContent).listSectionSpacing(12)
            .scrollContentBackground(.hidden).background(ShoppingTheme.canvas).tint(ShoppingTheme.accent)
            .navigationTitle("Receipt").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if outcome == nil {
                        Button(recordingExpense ? "Save receipt" : "Add \(selected)") { save() }
                            .disabled(busy || decoding || (selected == 0 && !recordingExpense)).accessibilityIdentifier("receipt.confirm")
                    }
                }
            }
            .sheet(isPresented: $camera) {
                ReceiptCamera(completed: { data in camera = false; startScan(data) },
                    failed: { message in camera = false; error = message }, cancelled: { camera = false })
            }
            .onChange(of: recordingExpense) { _, enabled in if !enabled { for index in lines.indices { lines[index].amount = "" } } }
            .onChange(of: photos) { _, value in
                guard !value.isEmpty else { return }
                cancelDecoding(); scanTask?.cancel(); busy = true
                scanTask = Task {
                    do {
                        var images: [Data] = []
                        for photo in value {
                            guard let data = try await photo.loadTransferable(type: Data.self) else { throw ReceiptImportError.unreadable }
                            guard data.count <= 20_000_000 else { throw ReceiptImportError.tooLarge }
                            images.append(data)
                        }
                        try await read(images)
                    } catch is CancellationError {} catch { self.error = userFacingError(error) }
                    busy = false
                }
            }
            .onDisappear { scanTask?.cancel(); cancelDecoding() }
            .onChange(of: repository.household?.id) { _, id in if id != householdID { dismiss() } }
            .task {
                if let sampleImage { expenseDraft.currency = "USD"; startScan([sampleImage]) }
                else if ProcessInfo.processInfo.arguments.contains("--ui-testing-receipt") {
                    apply(ReceiptRules.scan(text: "FRESH MARKET\nCurd 3.99\n2 x Bananas 2.49\nTOTAL 6.48"))
                }
            }
            .saveError($error)
            #if DEBUG
            .modifier(UITestAppearance())
            #endif
        }
    }
    @ViewBuilder private var scanControls: some View {
        PhotosPicker(selection: $photos, maxSelectionCount: 4, matching: .images) {
            Label("Choose receipt photos", systemImage: "photo.on.rectangle").frame(minHeight: 44, alignment: .leading)
        }.disabled(busy).accessibilityIdentifier("receipt.photos")
        if ReceiptCamera.isSupported {
            Button { camera = true } label: {
                Label("Scan with camera", systemImage: "doc.viewfinder").frame(minHeight: 44, alignment: .leading)
            }.disabled(busy).accessibilityIdentifier("receipt.camera")
        }
    }
    private func startScan(_ images: [Data]) {
        cancelDecoding(); scanTask?.cancel(); busy = true
        scanTask = Task {
            do { try await read(images) }
            catch is CancellationError {} catch { self.error = userFacingError(error) }
            busy = false
        }
    }
    private func read(_ images: [Data]) async throws {
        var pages: [String] = []
        for data in images { pages.append(try await scanner.scan(imageData: data).text) }
        try Task.checkCancellation()
        apply(ReceiptRules.scan(text: pages.joined(separator: "\n")))
    }
    private func apply(_ scan: ReceiptScan) {
        cancelDecoding(); proposals = [:]; decodeMessage = nil
        sourceText = scan.text; lines = scan.lines
        expenseDraft.amount = ExpenseRules.receiptTotal(scan.text) ?? ""
        expenseDraft.merchant = String(scan.text.components(separatedBy: .newlines).first?.prefix(200) ?? "")
        expenseDetails = expenseDraft.amount.isEmpty || expenseDraft.merchant.isEmpty
        for index in lines.indices {
            let name = lines[index].name
            let shopping = repository.groceries.filter { !$0.isCompleted && $0.purchaseDisposition != "inventory" && $0.receiptImportKey == nil && IngredientMatching.same($0.name, name) }
            if shopping.count == 1 { lines[index].groceryID = shopping.first?.id }
            let inventory = repository.inventory.filter { InventoryRules.canRestock(isUsedUp: $0.isUsedUp, expiryDay: $0.expiryDay) && IngredientMatching.same($0.name, name) }
            if inventory.count == 1 { lines[index].inventoryID = inventory.first?.id }
            if repository.receiptLineImported(lines[index].id) { lines[index].included = false }
        }
    }
    private func cancelDecoding() {
        decodeTask?.cancel(); decodeGeneration = UUID(); decoding = false
    }
    private func decodeNames() {
        cancelDecoding()
        let generation = decodeGeneration
        let inputs = lines.filter { line in line.included && !repository.receiptLineImported(line.id) }
            .map { ReceiptNameInput(id: $0.id, name: $0.name) }
        decoding = true; proposals = [:]; decodeMessage = nil
        decodeTask = Task {
            do {
                let result = try await decoder.decode(inputs)
                try Task.checkCancellation()
                guard decodeGeneration == generation, repository.household?.id == householdID else { return }
                proposals = Dictionary(uniqueKeysWithValues: result.proposals.map { ($0.id, $0) })
                decodeMessage = result.message
            } catch is CancellationError {} catch { decodeMessage = "AI could not decode names. You can edit them yourself." }
            if decodeGeneration == generation { decoding = false }
        }
    }
    private func save() {
        do {
            let key = ExpenseRules.receiptKey(sourceText)
            let alreadyRecorded = repository.expenses.contains { $0.receiptKey == key }
            let count = try repository.importReceipt(lines, householdID: householdID,
                storeName: recordingExpense ? expenseDraft.merchant : store,
                expense: recordingExpense ? expenseDraft : nil, receiptKey: key)
            let purchaseID = ReceiptRules.groceryID(home: householdID, key: "purchase|" + key)
            if repository.purchases.contains(where: { $0.purchaseID == purchaseID }) { savedPurchaseID = purchaseID }
            if recordingExpense {
                if let saved = repository.expenses.first(where: { $0.receiptKey == key }) {
                    onExpenseSaved?(String(saved.day.prefix(7)), saved.currencyCode)
                }
                outcome = alreadyRecorded ? "Expense already recorded. \(count) additional items updated." : "Expense saved. \(count) shopping and inventory items updated."
            } else {
                outcome = count == 0 ? "These items were already imported. Nothing added again." : "\(count) purchases saved. Shopping and inventory are updated."
            }
        } catch { self.error = userFacingError(error) }
    }
}

private struct ReceiptReviewRow: View {
    @Binding var line: ReceiptLine
    let purchaseDay: String
    let currency: String?
    let proposal: ReceiptNameProposal?
    let alreadyImported: Bool
    @Environment(LocalHouseholdRepository.self) private var repository
    private var pending: [GroceryItem] { repository.groceries.filter { !$0.isCompleted && $0.purchaseDisposition != "inventory" && $0.receiptImportKey == nil } }
    private var matches: [InventoryItem] { repository.inventory.filter { InventoryRules.canRestock(isUsedUp: $0.isUsedUp, expiryDay: $0.expiryDay) && IngredientMatching.same($0.name, line.name) } }
    private var candidates: [ReceiptPurchaseCandidate] { repository.receiptPurchaseCandidates(name: line.name, day: purchaseDay) }
    var body: some View {
        Section {
            HStack(spacing: 8) {
                Button { line.included.toggle() } label: {
                    Image(systemName: line.included ? "checkmark.circle.fill" : "circle")
                        .font(.title2).frame(minWidth: 44, minHeight: 44)
                }.buttonStyle(.borderless).disabled(alreadyImported)
                    .accessibilityLabel(alreadyImported ? "Already imported" : "Include \(line.name)")
                    .accessibilityValue(line.included ? "Selected" : "Not selected")
                    .accessibilityIdentifier("receipt.include.\(line.name)")
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Item name", text: $line.name).font(.headline).accessibilityIdentifier("receipt.name.\(line.id)")
                    Text(alreadyImported ? "Already imported" : line.quantity.isEmpty ? "Amount not set" : line.quantity)
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            if let proposal, !alreadyImported, ReceiptNameRules.canApply(proposal, to: line) {
                VStack(alignment: .leading, spacing: 6) {
                    Label(proposal.name, systemImage: "sparkles").font(.headline)
                    Text("Suggested from “\(proposal.original)”").font(.caption).foregroundStyle(.secondary)
                    Button("Use suggested name") { line.name = proposal.name }
                        .frame(minHeight: 44).buttonStyle(.borderless)
                        .accessibilityIdentifier("receipt.acceptName.\(line.id)")
                }
            }
            if line.included {
                if !candidates.isEmpty { purchaseReview }
                if line.existingPurchaseID == nil {
                Text(line.addToInventory ? (matches.isEmpty ? "New inventory item" : "Restock existing · clear Low stock") : "Bought only · kept elsewhere")
                    .font(.caption).foregroundStyle(.secondary)
                DisclosureGroup("Quantity & matches") {
                if let currency {
                    TextField("Line total in \(currency) (optional)", text: $line.amount).keyboardType(.decimalPad)
                        .accessibilityIdentifier("receipt.lineAmount.\(line.id)")
                    Text("Enter this item's total, not its unit price. Receipt tax and discounts stay in the expense total.").font(.caption).foregroundStyle(.secondary)
                }
                TextField("Quantity (optional), e.g. 2 tubs", text: $line.quantity)
                    .accessibilityIdentifier("receipt.quantity.\(line.id)")
                Picker("Shopping item", selection: $line.groceryID) {
                    Text("Save as a new bought item").tag(nil as UUID?)
                    ForEach(pending) { item in
                        Text("\(item.name)\(item.quantityText.map { " · \($0)" } ?? "")").tag(Optional(item.id))
                    }
                }.accessibilityIdentifier("receipt.shopping.\(line.id)")
                Toggle("Add to home inventory", isOn: $line.addToInventory)
                if line.addToInventory {
                    Toggle("Set pack expiry date", isOn: Binding(get: { line.expiryDay != nil }, set: { enabled in line.expiryDay = enabled ? HouseholdDay(.now).key : nil }))
                        .accessibilityIdentifier("receipt.setExpiry.\(line.id)")
                    if line.expiryDay != nil {
                        DatePicker("Expires on", selection: Binding(get: { line.expiryDay.flatMap { ShoppingEntryRules.date(for: $0) } ?? .now }, set: { line.expiryDay = HouseholdDay($0).key }), displayedComponents: .date)
                        Text("Use the date printed on the pack. For a restock, this updates the selected existing pack's expiry.").font(.caption).foregroundStyle(.secondary)
                    }
                }
                if line.addToInventory {
                    if matches.isEmpty {
                        Label("Add a new inventory item", systemImage: "plus.circle").font(.caption)
                    } else {
                        Picker("Restock existing", selection: $line.inventoryID) {
                            Text("Choose a saved pack").tag(nil as UUID?)
                            ForEach(matches) { item in
                                Text("\(item.name) · \(item.quantityText ?? "Amount not set") · \(InventoryRules.expiryLabel(item.expiryDay, today: HouseholdDay(.now).key))").tag(Optional(item.id))
                            }
                        }
                    }
                } else { Text("Mark bought only, for gifts or items kept elsewhere.").font(.caption).foregroundStyle(.secondary) }
                if line.addToInventory && !matches.isEmpty {
                    Text(RestockQuantity.detail(existing: matches.first(where: { $0.id == line.inventoryID })?.quantityText, purchased: line.quantity) + " Expiry changes only when you set it above.").font(.caption).foregroundStyle(.secondary)
                }
                }
                } else {
                    Label("Already recorded · pantry unchanged", systemImage: "checkmark.shield")
                        .font(.subheadline).accessibilityIdentifier("receipt.linked.\(line.name)")
                    if let currency {
                        TextField("Line total in \(currency) (optional)", text: $line.amount).keyboardType(.decimalPad)
                    }
                }
            }
        }
        .listRowBackground(ShoppingTheme.surface)
        .onChange(of: line.groceryID) { _, id in
            if let item = pending.first(where: { $0.id == id }), !IngredientMatching.same(item.name, line.name) {
                line.name = item.name
            }
        }
        .onChange(of: purchaseDay) { _, _ in line.existingPurchaseID = nil; line.confirmedNewPurchase = false }
        .onChange(of: line.name) { _, name in
            line.existingPurchaseID = nil; line.confirmedNewPurchase = false
            let shopping = pending.filter { IngredientMatching.same($0.name, name) }
            if let id = line.groceryID, !shopping.contains(where: { $0.id == id }) { line.groceryID = nil }
            if line.groceryID == nil, shopping.count == 1 { line.groceryID = shopping.first?.id }
            line.inventoryID = matches.count == 1 ? matches.first?.id : nil
        }
    }
    private var purchaseReview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Already bought?", systemImage: "bag.badge.questionmark")
                .font(.headline)
            Text("A recent purchase matches. Link it to avoid adding stock twice.")
                .font(.caption).foregroundStyle(.secondary)
            ForEach(candidates) { candidate in
                if candidate.alreadyLinked {
                    Label("\(candidate.name) · \(candidate.day) · Receipt or expense already recorded", systemImage: "checkmark.circle")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Button {
                        line.existingPurchaseID = candidate.id; line.confirmedNewPurchase = false
                    } label: {
                        HStack {
                            Image(systemName: line.existingPurchaseID == candidate.id ? "checkmark.circle.fill" : "circle")
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Use recorded purchase").font(.subheadline.weight(.semibold))
                                Text([candidate.quantity, candidate.merchant, candidate.day].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }.frame(minHeight: 44).contentShape(Rectangle())
                    }.buttonStyle(.borderless).accessibilityIdentifier("receipt.usePurchase.\(line.name)")
                        .accessibilityValue(line.existingPurchaseID == candidate.id ? "Selected" : "Not selected")
                }
            }
            Button {
                line.existingPurchaseID = nil; line.confirmedNewPurchase = true
            } label: {
                Label("This is a new purchase", systemImage: line.confirmedNewPurchase ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline).frame(minHeight: 44)
            }.buttonStyle(.borderless).accessibilityIdentifier("receipt.newPurchase.\(line.name)")
            if line.existingPurchaseID == nil && !line.confirmedNewPurchase {
                Text("Choose one before saving.").font(.caption.weight(.medium))
            }
        }.padding(.vertical, 4)
    }

}
