import SwiftUI

/// Transient, editable OCR review. Artwork is decorative, never a recognition claim.
struct ReceiptScanSummary: View {
    @Binding var lines: [ReceiptLine]
    let merchant: String
    let amount: String
    let currency: String
    let unavailableIDs: Set<String>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var appeared = false
    @State private var showAll = false
    private var selected: Int { lines.filter { eligible($0) && $0.addToInventory }.count }
    private var visibleLines: [ReceiptLine] { showAll ? lines : Array(lines.prefix(6)) }
    private func eligible(_ line: ReceiptLine) -> Bool {
        line.included && line.existingPurchaseID == nil && !unavailableIDs.contains(line.id)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 12) {
                Image(systemName: "text.viewfinder").font(.title)
                    .symbolEffect(.bounce, value: appeared).symbolEffectsRemoved(reduceMotion)
                    .padding(14).background(ShoppingTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Here’s what we read").font(.title2.bold())
                    Text("Scanned on your device · Not saved yet").font(.caption).foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text(merchant.isEmpty ? "Your receipt" : merchant).font(.headline)
                Text((try? ExpenseRules.minorUnits(amount)).map { ExpenseRules.money($0, currency: currency) } ?? "Check receipt total")
                    .font(.largeTitle.bold()).contentTransition(.numericText()).minimumScaleFactor(0.7)
                    .accessibilityIdentifier("receipt.scannedTotal")
                HStack {
                    Label("\(lines.count) items found", systemImage: "list.bullet.rectangle")
                    Spacer()
                    Text(currency).fontWeight(.semibold)
                }.font(.subheadline)
                Divider()
                Text("Check the total, names and quantities against your receipt. Edit the details below if anything is missing or wrong.")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                .background(ShoppingTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 12) {
                Text("What goes into your pantry?").font(.headline)
                Text("Add all eligible items, or tap individual cards. Leave meals eaten out, services and gifts unselected.")
                    .font(.subheadline).foregroundStyle(.secondary)
                ViewThatFits(in: .horizontal) {
                    HStack { selectionButtons }
                    VStack(alignment: .leading) { selectionButtons }
                }
                Text("Inventory items selected: \(selected)").font(.subheadline.weight(.semibold))
                    .contentTransition(.numericText()).accessibilityIdentifier("receipt.inventorySummary")
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 260 : 135), spacing: 12)], spacing: 12) {
                ForEach(visibleLines) { line in
                    Button {
                        guard let index = lines.firstIndex(where: { $0.id == line.id }), eligible(line) else { return }
                        withAnimation(reduceMotion ? nil : .snappy(duration: 0.22)) { lines[index].addToInventory.toggle() }
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(PantryVisualRules.icon(line.name, category: PantryVisualRules.category(line.name)))
                                    .font(.system(size: 32)).accessibilityHidden(true)
                                Spacer(minLength: 4)
                                Image(systemName: eligible(line) && line.addToInventory ? "checkmark.circle.fill" : "circle")
                                    .font(.title3).contentTransition(.symbolEffect(.replace)).symbolEffectsRemoved(reduceMotion).accessibilityHidden(true)
                            }
                            Text(line.name.isEmpty ? "Unnamed item" : line.name).font(.headline)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(line.quantity.isEmpty ? "Check quantity below" : line.quantity).font(.caption).foregroundStyle(.secondary)
                            Text(!eligible(line) ? "Already linked or excluded" : line.addToInventory ? "Add to pantry" : "Purchase only")
                                .font(.caption.weight(.semibold))
                        }.padding(14).frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
                            .foregroundStyle(ShoppingTheme.ink)
                            .background(eligible(line) && line.addToInventory ? ShoppingTheme.accent.opacity(0.16) : ShoppingTheme.surface,
                                        in: RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(ShoppingTheme.accent.opacity(line.addToInventory && eligible(line) ? 0.8 : 0.18), lineWidth: 1))
                    }.buttonStyle(.plain).disabled(!eligible(line))
                        .accessibilityLabel("\(line.name), add to inventory")
                        .accessibilityValue(eligible(line) && line.addToInventory ? "Selected" : "Not selected")
                        .accessibilityHint("Changes inventory selection only. Review and save to record the receipt.")
                        .accessibilityIdentifier("receipt.card.\(line.name)")
                }
            }
            if lines.count > 6 {
                Button(showAll ? "Show fewer items" : "Show all \(lines.count) items") {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { showAll.toggle() }
                }.frame(minHeight: 44).buttonStyle(.borderless)
            }
        }.padding(.vertical, 10)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 10)
            .onAppear { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) { appeared = true } }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: selected)
    }
    @ViewBuilder private var selectionButtons: some View {
        Button("Add all", systemImage: "checkmark.circle.fill") { selectAll(true) }
            .buttonStyle(.borderedProminent).tint(ShoppingTheme.ink).foregroundStyle(ShoppingTheme.canvas)
            .controlSize(.large).accessibilityIdentifier("receipt.inventoryAll")
            .accessibilityLabel("Add all eligible items to inventory")
            .disabled(!lines.contains(where: eligible))
        Button("Clear selection") { selectAll(false) }
            .buttonStyle(.bordered).controlSize(.large).accessibilityIdentifier("receipt.inventoryNone").disabled(selected == 0)
    }
    private func selectAll(_ enabled: Bool) {
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
            ReceiptInventorySelection.setAll(enabled, lines: &lines, unavailableIDs: unavailableIDs)
        }
    }
}
