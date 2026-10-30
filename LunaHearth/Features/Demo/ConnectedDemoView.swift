import SwiftUI

struct ConnectedDemoView: View {
    @State private var repository: LocalHouseholdRepository?
    @State private var error: String?
    var body: some View {
        Group {
            if let repository { ConnectedDemoContent().environment(repository) }
            else if let error { ContentUnavailableView("Demo could not start", systemImage: "exclamationmark.circle", description: Text(error)) }
            else { ProgressView("Preparing your sample home…") }
        }.navigationTitle("From receipt to tomorrow").navigationBarTitleDisplayMode(.inline)
            .task {
                guard repository == nil else { return }
                do {
                    let demo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
                    try demo.createHousehold(name: "Demo home", owner: "Demo cook", members: [])
                    var curd = InventoryDraft(); curd.name = "Curd"; curd.quantity = "1 tub"; curd.isLowStock = true
                    try demo.saveInventory(curd)
                    for name in ["Rice", "Curd", "Carrots", "Eggs", "Bananas"] {
                        var draft = EntryDraft(kind: .grocery, title: name); draft.storeName = "Luna Demo Market"
                        try demo.add(draft)
                    }
                    repository = demo
                } catch { self.error = userFacingError(error) }
            }
    }
}

private struct ConnectedDemoContent: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var receipt = false
    @State private var tomorrow = false
    @State private var error: String?
    private var saved: Bool { !repository.purchases.isEmpty }
    private var activeNames: [String] { repository.inventory.filter { !$0.isUsedUp }.map(\.name) }
    private var pending: Int { repository.groceries.filter { !$0.isCompleted }.count }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Label("A private preview · nothing saved to your home", systemImage: "lock.shield")
                    .font(.footnote).foregroundStyle(.secondary)
                DemoWorkflowAnimation()
                receiptCard
                if saved {
                    Text("Saved in this demo: \(repository.expenses.count) expense · \(repository.inventory.count) pantry items · \(pending) shopping to-dos remaining")
                        .font(.subheadline).foregroundStyle(.secondary)
                    NavigationLink { PurchaseHistoryView() } label: { Label("Explore demo expenses & purchases", systemImage: "receipt") }
                        .frame(minHeight: 44).accessibilityIdentifier("demo.purchases")
                    NavigationLink { InventoryView() } label: { Label("Inspect demo pantry & expiry dates", systemImage: "cabinet") }
                        .frame(minHeight: 44)
                    mealPreview
                }
            }.padding(20).frame(maxWidth: 900).frame(maxWidth: .infinity)
        }.background(AppTheme.canvas).tint(AppTheme.sage).featureCanvas(.expenses)
            .sheet(isPresented: $receipt) {
                if let home = repository.household?.id {
                    ReceiptImportView(householdID: home, sampleImage: DemoReceiptImage.make().pngData()).environment(repository)
                }
            }
            .saveError($error)
    }
    private var receiptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Now try it yourself.").font(AppTheme.sectionTitle).accessibilityAddTraits(.isHeader)
            Text("Rice · curd · carrots · eggs · bananas").font(.subheadline)
            Text("5 items · USD 16.00 · sample receipt").font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.sage)
            Text("Review the receipt and choose what reaches your sample pantry. Add pack dates from the label when known.").font(.subheadline).foregroundStyle(.secondary)
            Button(saved ? "Review sample receipt again" : "Load sample receipt", systemImage: "doc.viewfinder") { receipt = true }
                .frame(minHeight: 44).hearthGlassButton(prominent: true).accessibilityIdentifier("demo.loadReceipt")
            ShareLink(item: Image(uiImage: DemoReceiptImage.make()), preview: SharePreview("Sample receipt", image: Image(uiImage: DemoReceiptImage.make()))) {
                Label("Save sample image", systemImage: "square.and.arrow.up").font(.subheadline).frame(minHeight: 44)
            }
            Text("If you scan this image outside the demo, it can create real records after confirmation.").font(.caption).foregroundStyle(.secondary)
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(ExpenseTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }
    private var mealPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("5 PM · plan tomorrow", systemImage: "clock").font(.headline)
            Text("Try an evening check-in: review tomorrow’s meals using what is at home. This demo does not schedule a notification or run AI in the background.").font(.subheadline).foregroundStyle(.secondary)
            Button("Preview tomorrow’s meal ideas", systemImage: "fork.knife") { tomorrow = true }
                .frame(minHeight: 44).accessibilityIdentifier("demo.tomorrow")
            if tomorrow {
                Text("Sample ideas matched to your demo pantry").font(.subheadline.weight(.medium)).accessibilityIdentifier("demo.mealIdeas")
                Text("These are example meal ideas, not recipes. Check ingredients and dietary needs; the app does not verify food safety.").font(.caption).foregroundStyle(.secondary)
                ForEach(ConnectedDemo.ideas) { idea in
                    let missing = idea.missing(from: activeNames)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(idea.name).font(.headline)
                        Text("About \(idea.minutes) min · quantities need checking").font(.caption).foregroundStyle(.secondary)
                        Text(missing.isEmpty ? "Main ingredients are at home" : "Missing: \(missing.joined(separator: ", "))").font(.subheadline)
                        if !missing.isEmpty {
                            Button("Add missing items to demo shopping", systemImage: "basket.badge.plus") {
                                do { for name in missing where repository.duplicateShoppingItem(name) == nil { try repository.add(EntryDraft(kind: .grocery, title: name)) } }
                                catch { self.error = userFacingError(error) }
                            }.frame(minHeight: 44)
                        }
                    }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(ExpenseTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                }
            }
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(ExpenseTheme.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
    }
}
