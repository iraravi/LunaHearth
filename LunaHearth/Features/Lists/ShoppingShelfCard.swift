import SwiftUI

struct ShoppingShelfCard: View {
    let item: GroceryItem
    let category: PantryCategory
    let buyer: String
    let store: String
    let atHome: Bool
    let usedAI: Bool
    let open: () -> Void
    let addToInventory: (() -> Void)?
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: open) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(PantryVisualRules.icon(item.name, category: category)).font(.system(size: 32)).accessibilityHidden(true)
                        Spacer(minLength: 0)
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle").font(.title3).foregroundStyle(ShoppingTheme.accent)
                    }.padding(12).background(ShoppingTheme.accent.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
                    Text(item.name).font(.headline).foregroundStyle(ShoppingTheme.ink).strikethrough(item.isCompleted).fixedSize(horizontal: false, vertical: true)
                    if let quantity = item.quantityText, !quantity.isEmpty { Text(quantity).font(.subheadline).foregroundStyle(ShoppingTheme.muted) }
                    Label(item.neededLater == true ? "Later" : "Now", systemImage: item.neededLater == true ? "clock" : "basket")
                        .font(.caption.weight(.semibold)).foregroundStyle(ShoppingTheme.accent)
                    if item.neededLater == true, let day = item.plannedDay, let date = ShoppingEntryRules.date(for: day) {
                        Text(date, format: .dateTime.month(.abbreviated).day().year()).font(.caption).foregroundStyle(ShoppingTheme.muted)
                    }
                    Label(buyer, systemImage: "person.crop.circle").font(.caption).foregroundStyle(ShoppingTheme.muted)
                    if item.isCompleted {
                        Label(item.purchaseDisposition == "inventory" ? "Added to pantry" : "Bought", systemImage: "checkmark.circle").font(.caption).foregroundStyle(ShoppingTheme.accent)
                    } else if atHome { Label("Also at home", systemImage: "cabinet").font(.caption).foregroundStyle(ShoppingTheme.muted) }
                    if usedAI { Label("AI category", systemImage: "sparkles").font(.caption2).foregroundStyle(ShoppingTheme.muted) }
                }.frame(maxWidth: .infinity, alignment: .topLeading).contentShape(Rectangle())
            }.buttonStyle(.plain)
                .accessibilityLabel("\(item.name), \(item.quantityText ?? ""), \(store.isEmpty ? "Any store" : store), \(buyer), \(item.neededLater == true ? "needed later" : "needed now"), \(item.isCompleted ? "checked" : "not checked")")
                .accessibilityHint(item.isCompleted ? "Reopen shopping. Existing inventory stays unchanged." : "Choose bought and add to inventory, or bought without adding.")
                .accessibilityIdentifier("shopping.item.\(item.name)")
                // The grid is one List row; card swipe actions would accumulate on that row.
                .entryActions(.editing(item), includesSwipeActions: false)
            if let addToInventory { Button("Add to pantry", systemImage: "shippingbox", action: addToInventory).font(.caption).frame(minHeight: 44).buttonStyle(.borderless) }
        }.padding(12).frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
            .background(ShoppingTheme.surface, in: RoundedRectangle(cornerRadius: 18))
            .hearthCardOutline(ShoppingTheme.accent)
    }
}
