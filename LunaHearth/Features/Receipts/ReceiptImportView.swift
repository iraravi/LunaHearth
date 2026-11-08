import SwiftUI
import PhotosUI

struct ReceiptImportView: View {
    let householdID: UUID
    let sampleImage: Data?
    let onExpenseSaved: ((String, String) -> Void)?
    @State private var expenseDetails = true
    @State private var confirmingSave = false
    @State private var recordingExpense: Bool
    @State private var expenseDraft = ExpenseDraft(category: .groceries)
    init(householdID: UUID, startsWithExpense: Bool = true, sampleImage: Data? = nil, onExpenseSaved: ((String, String) -> Void)? = nil) {
        self.onExpenseSaved = onExpenseSaved
        self.householdID = householdID; self.sampleImage = sampleImage
        _recordingExpense = State(initialValue: startsWithExpense)
    }
    @Environment(PublicConfigurationStore.self) private var publicStatus
    @Environment(\.aiAvailability) private var aiAvailability
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var receiptImages: [Data] = []
    @State private var keepImages = false
    @State private var previewIncomplete = false
    @State private var savingImages = false
    @State private var imageSaveID: UUID?
    @State private var showingImages = false
    private let imageStorage: any ReceiptImageStorage = LocalReceiptImages()
    @State private var photos: [PhotosPickerItem] = []
    @State private var camera = false
    @State private var scanSession = ReceiptScanSession()
    private var busy: Bool { scanSession.isReading || savingImages }
    @State private var lines: [ReceiptLine] = []
    @State private var sourceText = ""
    @State private var store = ""
    @State private var error: String?
    @State private var outcome: String?
    @State private var savedPurchaseID: UUID?
    @State private var decoding = false
    @State private var decodeTask: Task<Void, Never>?
    @State private var decodeGeneration = UUID()
    @State private var proposals: [String: ReceiptNameProposal] = [:]
    @State private var decodeMessage: String?
    private let decoder: any ReceiptNameDecodingService = OnDeviceReceiptNameService()
    private var selected: Int { lines.filter(\.included).count }
    private var inventoryCount: Int {
        lines.filter { $0.included && $0.addToInventory && $0.existingPurchaseID == nil && !repository.receiptLineImported($0.id) }.count
    }
    private var saveSummary: String {
        let amount = (try? ExpenseRules.minorUnits(expenseDraft.amount)).map { ExpenseRules.money($0, currency: expenseDraft.currency) } ?? expenseDraft.amount
        return (recordingExpense ? "Expense total: \(amount). " : "") + "Inventory items selected: \(inventoryCount). Food kept at home can go in pantry inventory. Leave meals eaten out, services and gifts out. Purchased items stay in purchase history."
    }

    var body: some View {
        NavigationStack {
            styledReceiptList
            .sheet(isPresented: $camera) {
                ReceiptCamera(completed: { data in camera = false; startCameraScan(data) },
                    failed: { message in camera = false; error = message }, cancelled: { camera = false })
            }
            .onChange(of: recordingExpense) { _, enabled in if !enabled { for index in lines.indices { lines[index].amount = "" } } }
            .onChange(of: photos) { _, value in startPhotoScan(value) }
            .sheet(isPresented: $showingImages) { ReceiptImageViewer(pages: receiptImages) }
            .interactiveDismissDisabled(savingImages)
            .task(id: imageSaveID) {
                guard let id = imageSaveID else { return }
                defer { savingImages = false; imageSaveID = nil }
                do { try await imageStorage.save(receiptImages, home: householdID, purchase: id) }
                catch { self.error = "Purchase saved, but its image could not be stored. Your original photo is unchanged. Free some storage and scan it again if you want to keep a copy." }
            }
            .onDisappear { scanSession.cancel(); cancelDecoding() }
            .onChange(of: repository.household?.id) { _, id in if id != householdID { dismiss() } }
            .task {
                if let sampleImage { expenseDraft.currency = "USD"; startScan([sampleImage]) }
                else if ProcessInfo.processInfo.arguments.contains("--ui-testing-receipt") {
                    #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("--ui-testing-receipt-images") {
                        let format = UIGraphicsImageRendererFormat(); format.scale = 1
                        let data = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 600), format: format).jpegData(withCompressionQuality: 0.65) { context in
                            UIColor.white.setFill(); context.fill(CGRect(x: 0, y: 0, width: 400, height: 600))
                            ("TEST MARKET\nMilk 4.00\nTOTAL 4.00" as NSString).draw(at: CGPoint(x: 30, y: 40), withAttributes: [.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 24)])
                        }
                        var scan = ReceiptRules.scan(text: "TEST MARKET\nMilk 4.00\nTOTAL 4.00")
                        scan.previewImages = [data]; apply(scan); return
                    }
                    if ProcessInfo.processInfo.arguments.contains("--ui-testing-receipt-mutton") {
                        apply(ReceiptRules.scan(text: "TEST MARKET\nPREMIUM MUTTON LEG 12.00\nTOTAL 12.00"))
                        return
                    }
                    #endif
                    apply(ReceiptRules.scan(text: "FRESH MARKET\nCurd 3.99\n2 x Bananas 2.49\nTOTAL 6.48"))
                }
            }
            .sheet(isPresented: $confirmingSave) { saveReview }
            .alert("Receipt needs attention", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK", role: .cancel) { error = nil }
            } message: { Text(error ?? "Please try again.") }
            #if DEBUG
            .modifier(UITestAppearance())
            #endif
        }
    }
    private var styledReceiptList: some View {
            receiptList
            .contentMargins(.top, 8, for: .scrollContent).listSectionSpacing(12)
            .scrollContentBackground(.hidden).background(ShoppingTheme.canvas).tint(ShoppingTheme.accent)
            .householdHelp(.receipts)
        .featureAvailability(.receipts).navigationTitle("Receipt").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() }.disabled(savingImages) }
                ToolbarItem(placement: .confirmationAction) {
                    if outcome == nil && (publicStatus.configuration?.allows(.receipts) ?? true) {
                        Button(recordingExpense ? "Save receipt" : "Add \(selected)") { reviewSave() }
                            .disabled(sourceText.isEmpty || busy || decoding || (selected == 0 && !recordingExpense)).accessibilityIdentifier("receipt.confirm")
                    }
                }
            }
    }
    private func startPhotoScan(_ value: [PhotosPickerItem]) {
                guard !value.isEmpty else { return }
                cancelDecoding()
                scanSession.start(operation: {
                    let scanner = VisionReceiptScanner()
                    var pages: [String] = []
                    var previews: [Data] = []
                    for photo in value {
                        try Task.checkCancellation()
                        guard let data = try await photo.loadTransferable(type: Data.self) else { throw ReceiptImportError.unreadable }
                        guard data.count <= 20_000_000 else { throw ReceiptImportError.tooLarge }
                        pages.append(try await scanner.scan(imageData: data).text)
                        if let preview = try? await imageStorage.compress(data) { previews.append(preview) }
                    }
                    try Task.checkCancellation()
                    var result = ReceiptRules.scan(text: pages.joined(separator: "\n"))
                    result.previewImages = previews
                    result.previewIncomplete = previews.count != pages.count
                    return result
                }, completed: { scan in apply(scan); photos = [] },
                   failed: { message in error = message; photos = [] })
    }
    private var receiptList: some View {
            List {
                if sourceText.isEmpty {
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
                }
                if let outcome {
                    Section {
                        Label(outcome, systemImage: "checkmark.circle.fill").accessibilityIdentifier("receipt.success")
                        if let savedPurchaseID {
                            NavigationLink { PurchaseDetailView(purchaseID: savedPurchaseID) } label: { Label("View purchase", systemImage: "bag") }
                                .accessibilityIdentifier("receipt.purchaseDetails")
                        }
                        Button("Done") { dismiss() }.disabled(savingImages)
                    }
                } else {
                    if sourceText.isEmpty {
                        Section { scanControls } footer: {
                            Text("Use up to four pages from one receipt. Photos are kept only if you choose Keep receipt image. Saved copies stay on this device.")
                        }
                    }
                    if busy {
                        Section {
                            ProgressView("Loading and reading your receipt…").accessibilityIdentifier("receipt.reading")
                            Text("Photos stored in iCloud may need to download first.").font(.caption).foregroundStyle(.secondary)
                            Button("Cancel scan") { scanSession.cancel(); photos = [] }
                                .frame(minHeight: 44).accessibilityIdentifier("receipt.cancelScan")
                        }
                    }
                    if !sourceText.isEmpty {
                        Section {
                            ReceiptScanSummary(lines: $lines, merchant: expenseDraft.merchant, amount: expenseDraft.amount,
                                               currency: expenseDraft.currency,
                                               unavailableIDs: Set(lines.filter { repository.receiptLineImported($0.id) }.map(\.id)))
                        }.listRowBackground(Color.clear)
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
                                        Text("Receipt date: \(expenseDraft.date.formatted(date: .abbreviated, time: .omitted)). Check it against the receipt.").font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        if lines.isEmpty {
                            Section { Text("Text was found, but no priced item lines were clear. Read the original text and add a line below, or try another photo.") }
                        }
                        if !lines.isEmpty && (aiAvailability.showsAIActions && (publicStatus.configuration?.allows(.aiReceiptNames) ?? true)) {
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
                        Section {
                            Button("Add a missed item", systemImage: "plus") {
                                lines.append(ReceiptLine(id: ReceiptRules.hash(sourceText + "|manual|\(lines.count)"), name: "", addToInventory: false))
                            }.disabled(lines.count >= 150).accessibilityIdentifier("receipt.addLine")
                        }
                        ForEach($lines) { $line in
                            ReceiptReviewRow(line: $line, purchaseDay: HouseholdDay(recordingExpense ? expenseDraft.date : .now).key, currency: recordingExpense ? expenseDraft.currency : nil, proposal: proposals[line.id], alreadyImported: repository.receiptLineImported(line.id))
                        }
                        imageOptions
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

                    }
                }
            }
    }
    private var imageSizeLabel: String {
        let count = receiptImages.reduce(0) { total, data in total + data.count }
        return ByteCountFormatter.string(fromByteCount: Int64(count), countStyle: .file)
    }
    @ViewBuilder private var imageOptions: some View {
                        if !receiptImages.isEmpty || previewIncomplete {
                            Section("Receipt image") {
                                Button("View scanned receipt", systemImage: "photo") { showingImages = true }.disabled(receiptImages.isEmpty)
                                Toggle("Keep receipt image", isOn: $keepImages).disabled(selected == 0 || previewIncomplete).accessibilityIdentifier("receipt.keepImages")
                                if previewIncomplete { Text("Some pages could not be prepared within the image limit. Scan again to save a complete copy; your extracted items are still available.").font(.caption) }
                                if selected == 0 { Text("Select at least one purchased item to keep the image in Purchase history.").font(.caption) }
                                Text("Compressed copy: \(imageSizeLabel). Local to this device; not shared through iCloud or included in encrypted exports. You can remove it from Purchase details.")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
    }
    private var saveReview: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Label("Ready to save?", systemImage: "receipt").font(.title2.bold())
                    Text(saveSummary).font(.body).foregroundStyle(InventoryTheme.ink)
                    if inventoryCount > 0 {
                        Button {
                            confirmingSave = false
                            save()
                        } label: {
                            Label("Save & update pantry", systemImage: "checkmark")
                                .frame(maxWidth: .infinity, minHeight: 44).padding(12)
                                .background(InventoryTheme.ink, in: RoundedRectangle(cornerRadius: 18))
                                .foregroundStyle(InventoryTheme.canvas)
                        }.buttonStyle(.plain).accessibilityIdentifier("receipt.saveWithInventory")
                    }
                    Button {
                        for index in lines.indices { lines[index].addToInventory = false }
                        confirmingSave = false
                        save()
                    } label: {
                        Text("Save without inventory")
                            .frame(maxWidth: .infinity, minHeight: 44).padding(12)
                            .background(InventoryTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                            .foregroundStyle(InventoryTheme.ink)
                    }.buttonStyle(.plain).accessibilityIdentifier("receipt.saveWithoutInventory")
                }.padding(24)
            }.background(InventoryTheme.canvas)
                .navigationTitle("Review receipt").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { confirmingSave = false }.accessibilityLabel("Keep reviewing receipt")
                } }
        }.presentationDetents(textSize.isAccessibilitySize ? [.large] : [.medium, .large])
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
    private func startCameraScan(_ images: [UIImage]) {
        cancelDecoding()
        scanSession.start(operation: {
            let encoder = ReceiptCameraEncoder()
            let scanner = VisionReceiptScanner()
            var pages: [String] = []
                    var previews: [Data] = []
            for image in images {
                try Task.checkCancellation()
                let data = try await encoder.encode(image)
                pages.append(try await scanner.scan(imageData: data).text)
                        if let preview = try? await imageStorage.compress(data) { previews.append(preview) }
            }
            try Task.checkCancellation()
            var result = ReceiptRules.scan(text: pages.joined(separator: "\n"))
                    result.previewImages = previews
                    result.previewIncomplete = previews.count != pages.count
                    return result
        }, completed: { apply($0) }, failed: { error = $0 })
    }
    private func startScan(_ images: [Data]) {
        cancelDecoding()
        scanSession.start(operation: { try await read(images) },
                          completed: { apply($0) }, failed: { error = $0 })
    }
    private func read(_ images: [Data]) async throws -> ReceiptScan {
        // Each attempt owns its scanner so cancelled Vision work cannot queue a retry behind it.
        let scanner = VisionReceiptScanner()
        var pages: [String] = []
                    var previews: [Data] = []
        for data in images {
            try Task.checkCancellation()
            pages.append(try await scanner.scan(imageData: data).text)
                        if let preview = try? await imageStorage.compress(data) { previews.append(preview) }
        }
        try Task.checkCancellation()
        var result = ReceiptRules.scan(text: pages.joined(separator: "\n"))
                    result.previewImages = previews
                    result.previewIncomplete = previews.count != pages.count
                    return result
    }
    private func apply(_ scan: ReceiptScan) {
        cancelDecoding(); proposals = [:]; decodeMessage = nil
        sourceText = scan.text; lines = scan.lines
        receiptImages = scan.previewImages; keepImages = false; previewIncomplete = scan.previewIncomplete
        expenseDraft.amount = ExpenseRules.receiptTotal(scan.text) ?? ""
        expenseDraft.merchant = String(scan.text.components(separatedBy: .newlines).first?.prefix(200) ?? "")
        expenseDetails = true
        if let currency = ExpenseRules.receiptCurrency(scan.text) { expenseDraft.currency = currency }
        for index in lines.indices {
            lines[index].addToInventory = false
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
            } catch is CancellationError {} catch {
                if decodeGeneration == generation, repository.household?.id == householdID {
                    decodeMessage = "AI could not decode names. You can edit them yourself."
                }
            }
            if decodeGeneration == generation { decoding = false }
        }
    }
    private func reviewSave() {
        do {
            if recordingExpense { try ExpenseRules.validate(expenseDraft) }
            confirmingSave = true
        } catch { self.error = userFacingError(error) }
    }
    private func save() {
        do {
            let additions = inventoryCount
            let key = ExpenseRules.receiptKey(sourceText)
            let alreadyRecorded = repository.expenses.contains { $0.receiptKey == key }
            let count = try repository.importReceipt(lines, householdID: householdID,
                storeName: recordingExpense ? expenseDraft.merchant : store,
                expense: recordingExpense ? expenseDraft : nil, receiptKey: key)
            let purchaseID = ReceiptRules.groceryID(home: householdID, key: "purchase|" + key)
            if repository.purchases.contains(where: { $0.purchaseID == purchaseID }) { savedPurchaseID = purchaseID }
            if keepImages && selected > 0 && !receiptImages.isEmpty {
                savingImages = true; imageSaveID = purchaseID
            }
            if recordingExpense {
                if let saved = repository.expenses.first(where: { $0.receiptKey == key }) {
                    onExpenseSaved?(String(saved.day.prefix(7)), saved.currencyCode)
                }
                outcome = alreadyRecorded ? "Expense already recorded. \(count) additional items updated." : "Expense saved. \(count) purchased items recorded. Inventory additions: \(additions)."
            } else {
                outcome = count == 0 ? "These items were already imported. Nothing added again." : "\(count) purchases saved. Shopping and inventory are updated."
            }
        } catch { self.error = (error as? ReceiptImportError)?.errorDescription ?? userFacingError(error) }
    }
}

private struct ReceiptReviewRow: View {
    @Binding var line: ReceiptLine
    let purchaseDay: String
    let currency: String?
    let proposal: ReceiptNameProposal?
    let alreadyImported: Bool
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.aiAvailability) private var aiAvailability
    @Environment(PublicConfigurationStore.self) private var publicStatus
    @State private var aiRequested = false
    @State private var aiSuggestions: [ReceiptShoppingApproval] = []
    @State private var aiMessage: String?
    private let comparer: any ReceiptShoppingComparisonService = OnDeviceIngredientComparisonService()
    private var aiContext: [String] {
        [repository.household?.id.uuidString ?? "", line.name, String(line.included), String(alreadyImported)]
            + pending.sorted { $0.id.uuidString < $1.id.uuidString }.map { "\($0.id)|\($0.name)" }
    }
    private var currentAISuggestions: [ReceiptShoppingApproval] {
        aiSuggestions.filter { suggestion in pending.contains {
            suggestion.validates(id: $0.id, receipt: line.name, shopping: $0.name)
        } }
    }
    private var pending: [GroceryItem] { repository.groceries.filter { !$0.isCompleted && $0.purchaseDisposition != "inventory" && $0.receiptImportKey == nil } }
    private var shoppingMatches: [GroceryItem] { pending.filter { ReceiptPurchaseMatching.possibleMatch(receipt: line.name, requested: $0.name) } }
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
                if line.existingPurchaseID == nil && (candidates.isEmpty || line.confirmedNewPurchase) {
                if !shoppingMatches.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Match your shopping", systemImage: "cart").font(.headline)
                        Text("Confirm which request this receipt fulfils. The family assignment and shopping name are kept.").font(.caption).foregroundStyle(.secondary)
                        ForEach(shoppingMatches) { item in
                            Button { line.groceryID = line.groceryID == item.id ? nil : item.id } label: {
                                Label("\(item.name) · \(repository.memberName(item.assignedMemberID))", systemImage: line.groceryID == item.id ? "checkmark.circle.fill" : "circle")
                                    .frame(minHeight: 44)
                            }.buttonStyle(.borderless).accessibilityIdentifier("receipt.match.\(item.id)")
                        }
                    }
                }
                if !alreadyImported && !pending.isEmpty && aiAvailability.showsAIActions && (publicStatus.configuration?.allows(.aiDuplicates) ?? true) {
                    Button(aiRequested ? "Finding matches…" : "Find matches with AI", systemImage: "sparkles") {
                        aiRequested = true
                    }.disabled(aiRequested).frame(minHeight: 44)
                        .accessibilityIdentifier("receipt.aiMatch.\(line.id)")
                    if let aiMessage { Text(aiMessage).font(.caption).foregroundStyle(.secondary) }
                }
                if aiRequested { Button("Cancel AI matching") { aiRequested = false }.frame(minHeight: 44) }
                ForEach(currentAISuggestions, id: \.groceryID) { suggestion in
                    if let item = pending.first(where: { $0.id == suggestion.groceryID }) {
                        Button {
                            line.reviewedShoppingMatch = suggestion
                            line.groceryID = suggestion.groceryID
                        } label: {
                            Label("\(line.groceryID == item.id ? "Confirmed" : "Confirm AI match"): \(item.name) · \(repository.memberName(item.assignedMemberID))", systemImage: "sparkles")
                        }.buttonStyle(.borderless).frame(minHeight: 44)
                            .accessibilityIdentifier("receipt.acceptAIMatch.\(item.id)")
                    }
                }
                Toggle("Add to pantry", isOn: $line.addToInventory)
                    .accessibilityIdentifier("receipt.inventory.\(line.name)")
                if line.addToInventory {
                    if matches.isEmpty {
                        Text("A new pantry pack will be created.").font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("Already in your pantry").font(.subheadline.weight(.semibold))
                        Toggle("Keep as a separate pack", isOn: Binding(get: { line.keepSeparatePack }, set: { separate in
                            line.keepSeparatePack = separate
                            line.inventoryID = separate ? nil : (matches.count == 1 ? matches.first?.id : nil)
                        })).accessibilityIdentifier("receipt.separatePack.\(line.name)")
                        if line.keepSeparatePack {
                            Text("Your existing pack, amount and expiry stay unchanged.").font(.caption).foregroundStyle(.secondary)
                        } else {
                            Picker("Add to pack", selection: $line.inventoryID) {
                                Text("Choose a pack").tag(nil as UUID?)
                                ForEach(matches) { item in
                                    Text("\(item.name) · \(item.quantityText ?? "Amount not set") · \(InventoryRules.expiryLabel(item.expiryDay, today: HouseholdDay(.now).key))").tag(Optional(item.id))
                                }
                            }.accessibilityIdentifier("receipt.restockPack.\(line.name)")
                            Text(RestockQuantity.detail(existing: matches.first(where: { $0.id == line.inventoryID })?.quantityText, purchased: line.quantity))
                                .font(.caption).foregroundStyle(.secondary)
                            Text("The existing pack’s purchase date stays unchanged. This purchase is recorded separately in history.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("Save the purchase without changing pantry stock.").font(.caption).foregroundStyle(.secondary)
                }
                DisclosureGroup("Quantity, price & expiry") {
                if let currency {
                    TextField("Line total in \(currency) (optional)", text: $line.amount).keyboardType(.decimalPad)
                        .accessibilityIdentifier("receipt.lineAmount.\(line.id)")
                    Text("Enter this item's total, not its unit price. Receipt tax and discounts stay in the expense total.").font(.caption).foregroundStyle(.secondary)
                }
                TextField("Quantity (optional), e.g. 2 tubs", text: $line.quantity)
                    .accessibilityIdentifier("receipt.quantity.\(line.id)")
                Picker("Shopping item", selection: $line.groceryID) {
                    Text("Not linked to a shopping request").tag(nil as UUID?)
                    if let approval = line.reviewedShoppingMatch, line.groceryID == approval.groceryID,
                       !shoppingMatches.contains(where: { $0.id == approval.groceryID }) {
                        Text("Reviewed: \(approval.shoppingName)").tag(Optional(approval.groceryID))
                    }
                    ForEach(shoppingMatches) { item in
                        Text("\(item.name)\(item.quantityText.map { " · \($0)" } ?? "")").tag(Optional(item.id))
                    }
                }.accessibilityIdentifier("receipt.shopping.\(line.id)")
                if line.addToInventory {
                    Toggle("Set pack expiry date", isOn: Binding(get: { line.expiryDay != nil }, set: { enabled in line.expiryDay = enabled ? HouseholdDay(.now).key : nil }))
                        .accessibilityIdentifier("receipt.setExpiry.\(line.id)")
                    if line.expiryDay != nil {
                        DatePicker("Expires on", selection: Binding(get: { line.expiryDay.flatMap { ShoppingEntryRules.date(for: $0) } ?? .now }, set: { line.expiryDay = HouseholdDay($0).key }), displayedComponents: .date)
                        Text("Use the date printed on the pack. For a restock, this updates the selected existing pack's expiry.").font(.caption).foregroundStyle(.secondary)
                    }
                }

                }
                } else if line.existingPurchaseID != nil {
                    Label("Receipt attached · pantry unchanged", systemImage: "checkmark.shield")
                        .font(.subheadline).accessibilityIdentifier("receipt.linked.\(line.name)")
                    if let currency {
                        TextField("Line total in \(currency) (optional)", text: $line.amount).keyboardType(.decimalPad)
                    }
                }
            }
        }
        .listRowBackground(ShoppingTheme.surface)
        .task(id: aiRequested ? aiContext : []) {
            guard aiRequested else { return }
            let context = aiContext
            let name = line.name
            let snapshot = Array(pending.prefix(60)).map { ReceiptShoppingApproval(groceryID: $0.id, receiptName: name, shoppingName: $0.name) }
            // A cancelled request must not clear a replacement request's loading state.
            defer { if !Task.isCancelled && context == aiContext { aiRequested = false } }
            do {
                let result = try await comparer.compareReceipt(name: name, candidates: snapshot.map(\.shoppingName))
                try Task.checkCancellation()
                guard context == aiContext else { return }
                aiSuggestions = IngredientComparison.validated(result.matchingIndices, count: snapshot.count).map { snapshot[$0] }
                aiMessage = result.usedModel ? "Review each suggestion against the receipt. AI can be wrong. Up to 60 shopping items checked; quantities are not verified." : "AI is unavailable right now. Existing offline matches still work."
                if result.usedModel && aiSuggestions.isEmpty { aiMessage = "No additional matches found. You can edit the item name or keep it as a new purchase." }
            } catch { if !Task.isCancelled { aiMessage = "Couldn’t compare items. Try again or use the offline matches." } }
        }
        .onChange(of: line.groceryID) { _, id in
            if line.reviewedShoppingMatch?.groceryID != id { line.reviewedShoppingMatch = nil }
        }
        .onChange(of: purchaseDay) { _, _ in line.existingPurchaseID = nil; line.confirmedNewPurchase = false }
        .onChange(of: line.name) { _, name in
            aiSuggestions = []; aiMessage = nil; line.reviewedShoppingMatch = nil
            line.existingPurchaseID = nil; line.confirmedNewPurchase = false
            let shopping = pending.filter { ReceiptPurchaseMatching.possibleMatch(receipt: name, requested: $0.name) }
            if let id = line.groceryID, !shopping.contains(where: { $0.id == id }) { line.groceryID = nil }
            if line.groceryID == nil, shopping.count == 1, let item = shopping.first, IngredientMatching.same(item.name, name) { line.groceryID = item.id }
            line.keepSeparatePack = false
            line.inventoryID = matches.count == 1 ? matches.first?.id : nil
        }
    }
    private func purchaseDateLabel(_ day: String) -> String {
        ShoppingEntryRules.date(for: day)?.formatted(date: .abbreviated, time: .omitted) ?? day
    }
    private var purchaseReview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Have you recorded this purchase already?").font(.headline)
            Text("Similar purchases exist in your history. Their dates below are previous purchases, not the date of this receipt.")
                .font(.caption).foregroundStyle(.secondary)
            Button {
                line.existingPurchaseID = nil; line.confirmedNewPurchase = true
            } label: {
                Label("Record this purchase", systemImage: line.confirmedNewPurchase ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
            }.buttonStyle(.borderless).accessibilityIdentifier("receipt.newPurchase.\(line.name)")
            Text("Choose this if you bought more. You can use your existing pantry pack on the next step.")
                .font(.caption).foregroundStyle(.secondary)
            DisclosureGroup("Already recorded? Attach receipt") {
                Text("Only choose the same purchase you previously marked bought. This will not add pantry stock again.")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(candidates) { candidate in
                    if candidate.alreadyLinked {
                        Label("\(candidate.name) · Previous purchase: \(purchaseDateLabel(candidate.day)) · Receipt already recorded", systemImage: "checkmark.circle")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Button {
                            line.existingPurchaseID = candidate.id; line.confirmedNewPurchase = false
                        } label: {
                            HStack {
                                Image(systemName: line.existingPurchaseID == candidate.id ? "checkmark.circle.fill" : "circle")
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Attach to \(candidate.name)").font(.subheadline.weight(.semibold))
                                    Text("Previous purchase: \(purchaseDateLabel(candidate.day))").font(.caption)
                                    Text([candidate.quantity, candidate.merchant].filter { !$0.isEmpty }.joined(separator: " · "))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                            }.frame(minHeight: 44).contentShape(Rectangle())
                        }.buttonStyle(.borderless).accessibilityIdentifier("receipt.usePurchase.\(line.name)")
                            .accessibilityValue(line.existingPurchaseID == candidate.id ? "Selected" : "Not selected")
                    }
                }
            }
            if line.existingPurchaseID == nil && !line.confirmedNewPurchase {
                Text("Choose Record this purchase or attach to a previous purchase to continue.").font(.caption.weight(.medium))
            }
        }.padding(.vertical, 4)
    }

}
